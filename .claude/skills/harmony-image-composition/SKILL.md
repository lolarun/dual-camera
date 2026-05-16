---
name: harmony-image-composition
description: Image manipulation, watermarking, picture-in-picture composition, canvas rendering for HarmonyOS. Trigger phrases: "watermark", "add watermark", "compose image", "PIP overlay", "combine photos", "OffscreenCanvas", "PixelMap", "image composition", "draw on image", "metadata watermark".
---

# When to Use This Skill

Example trigger prompts:
- "Add a watermark with task metadata to the captured photo"
- "Composite the PIP front camera image onto the back camera photo"
- "Draw the metadata strip at the bottom of the image"
- "Create the final composed JPEG for saving"

---

# Import

```typescript
import { image } from "@kit.ImageKit";
import { drawing } from "@kit.ArkGraphics2D";
import { taskpool } from "@kit.ArkTS";
import { fs } from "@kit.CoreFileKit";
```

---

# High-Level Composition Pipeline

```
Back camera JPEG bytes (ArrayBuffer)
Front camera JPEG bytes (ArrayBuffer) [optional, for PIP]
  ↓
① Decode both to PixelMap
② Create OffscreenCanvas matching back camera dimensions
③ Draw back camera full-frame
④ Draw front camera at PIP position (top-left, scaled down)
⑤ Draw translucent black strip at bottom
⑥ Draw metadata text lines in white over the strip
⑦ Get composed PixelMap from canvas
⑧ Pack to JPEG (ImagePacker) → ArrayBuffer
⑨ Write ArrayBuffer to sandbox file + gallery
⑩ Release all PixelMaps
```

---

# Step-by-Step Implementation

## 1. Decode JPEG Bytes to PixelMap

```typescript
async function decodeJpeg(buffer: ArrayBuffer): Promise<image.PixelMap> {
  const imageSource = image.createImageSource(buffer);
  const pixelMap = await imageSource.createPixelMap({
    editable: false,
    desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
  });
  imageSource.release();
  return pixelMap;
}
```

## 2. Get Image Dimensions

```typescript
const backInfo = await backPixelMap.getImageInfo();
const W = backInfo.size.width;   // e.g. 4096
const H = backInfo.size.height;  // e.g. 3072
```

## 3. Compose on OffscreenCanvas

```typescript
// Run on TaskPool to avoid blocking UI thread
@Concurrent
async function composeImage(
  backBuffer: ArrayBuffer,
  frontBuffer: ArrayBuffer | null,
  metadata: WatermarkMetadata
): Promise<ArrayBuffer> {
  const backPixelMap = await decodeJpeg(backBuffer);
  const backInfo = await backPixelMap.getImageInfo();
  const W = backInfo.size.width;
  const H = backInfo.size.height;

  // OffscreenCanvas at full resolution
  const offscreenCanvas = new OffscreenCanvas(W, H);
  const ctx = offscreenCanvas.getContext("2d") as OffscreenCanvasRenderingContext2D;

  // Draw back camera (full frame)
  const backBitmap = await createImageBitmap(backPixelMap);
  ctx.drawImage(backBitmap, 0, 0, W, H);
  backPixelMap.release();

  // Draw PIP (front camera, top-left, 240×160 logical → scale to full res)
  if (frontBuffer !== null) {
    const frontPixelMap = await decodeJpeg(frontBuffer);
    const pipW = Math.round(W * 0.18);  // 18% of width
    const pipH = Math.round(pipW * 0.67);
    const pipX = Math.round(W * 0.02);
    const pipY = Math.round(H * 0.03);

    const frontBitmap = await createImageBitmap(frontPixelMap);
    // Rounded clip
    ctx.save();
    ctx.beginPath();
    ctx.roundRect(pipX, pipY, pipW, pipH, [Math.round(pipW * 0.05)]);
    ctx.clip();
    ctx.drawImage(frontBitmap, pipX, pipY, pipW, pipH);
    ctx.restore();

    // PIP border
    ctx.strokeStyle = "white";
    ctx.lineWidth = Math.round(W * 0.002);
    ctx.beginPath();
    ctx.roundRect(pipX, pipY, pipW, pipH, [Math.round(pipW * 0.05)]);
    ctx.stroke();

    frontPixelMap.release();
  }

  // Watermark strip at bottom (18% of height)
  const stripH = Math.round(H * 0.18);
  const stripY = H - stripH;
  ctx.fillStyle = "rgba(0, 0, 0, 0.72)";
  ctx.fillRect(0, stripY, W, stripH);

  // Watermark text
  const baseFontSize = Math.round(H * 0.028);  // scales with resolution
  ctx.fillStyle = "white";
  ctx.textBaseline = "top";

  const lines = buildWatermarkLines(metadata);
  lines.forEach((line, i) => {
    ctx.font = `${baseFontSize}px "PingFang SC", "Noto Sans SC", sans-serif`;
    ctx.fillText(
      line,
      Math.round(W * 0.02),
      stripY + Math.round(H * 0.025) + i * Math.round(baseFontSize * 1.5)
    );
  });

  // Get composed bitmap → PixelMap → pack to JPEG
  const composedBitmap = offscreenCanvas.transferToImageBitmap();
  const packer = image.createImagePacker();
  const packedBuffer = await packer.packing(composedBitmap, {
    format: "image/jpeg",
    quality: 95,
  });
  packer.release();

  return packedBuffer;
}
```

## 4. Watermark Text Layout

```typescript
class WatermarkMetadata {
  taskNumber: string = "";
  deviceModel: string = "";
  unit: string = "";
  part: string = "";
  partArea: string = "";
  project: string = "";
  operator: string = "";
  inspector: string = "";
  photographer: string = "";
  photoDate: string = "";
}

function buildWatermarkLines(meta: WatermarkMetadata): string[] {
  return [
    `任务号：${meta.taskNumber}　机型：${meta.deviceModel}　单位：${meta.unit}`,
    `部位：${meta.part}　部位区域：${meta.partArea}`,
    `照相对应项目：${meta.project}`,
    `操作者：${meta.operator}　检验员：${meta.inspector}　照相人：${meta.photographer}　日期：${meta.photoDate}`,
  ];
}
```

## 5. Run Composition Off UI Thread

```typescript
// In the component
async handleSave(): Promise<void> {
  this.isSaving = true;
  this.saveProgress = 0;

  try {
    // Pass ArrayBuffers (transferable) to TaskPool
    const task = new taskpool.Task(
      composeImage,
      this.backCameraBuffer,
      this.frontCameraBuffer,
      this.metadata
    );
    const composedBuffer = await taskpool.execute(task) as ArrayBuffer;

    this.saveProgress = 50;

    // Write to sandbox
    const sandboxPath = getPhotoSandboxPath(
      this.context, this.metadata.taskNumber, this.metadata.part, this.filename
    );
    await fs.mkdir(getDirPath(sandboxPath), true);
    const file = await fs.open(sandboxPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
    await fs.write(file.fd, composedBuffer);
    await fs.close(file.fd);

    this.saveProgress = 80;

    // Write to gallery
    const galleryUri = await savePhotoToGallery(this.context, composedBuffer, this.filename);
    this.saveProgress = 100;

    // Record in DB
    await DBService.getInstance().insertTask({ ...this.metadata, photoPath: sandboxPath, galleryUri });

    this.showSuccessToast();
  } catch (err) {
    this.showSaveError();
  } finally {
    this.isSaving = false;
  }
}
```

---

# Filename Convention

```typescript
function buildFilename(meta: WatermarkMetadata): string {
  const safeDate = meta.photoDate.replace(/-/g, "");
  return `${meta.taskNumber}-${meta.part}-${meta.photographer}-${safeDate}.jpg`;
}
// Example: A12345-右侧发动机-张三-20260426.jpg
```

---

# Memory Management — Critical

```typescript
// ALWAYS release PixelMaps when done
// Unreleased PixelMaps cause native memory leaks visible in DevEco Profiler

try {
  const pixelMap = await decodeJpeg(buffer);
  // ... use it ...
} finally {
  pixelMap.release();  // even on error
}
```

---

# Performance Notes

- Full-resolution composition (4096×3072) takes ~800ms–2s on MatePad Pro
- Always run on `taskpool` — never on the UI thread
- Show a progress bar with cancellation option for any operation >500ms
- Pack at quality 92–95 for good JPEG size/quality tradeoff
- Use `transferToImageBitmap()` (zero-copy) instead of `getImageData()`
