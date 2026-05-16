import { image } from '@kit.ImageKit';
import { taskpool } from '@kit.ArkTS';
import { FormData } from '../common/types/InspectionTypes';

// Empty ArrayBuffer sentinel = no front image (null not allowed in taskpool args)
@Concurrent
async function composeImageTask(
  backBuffer: ArrayBuffer,
  frontBuffer: ArrayBuffer,
  taskNumber: string,
  deviceModel: string,
  unit: string,
  part: string,
  partArea: string,
  project: string,
  operator: string,
  inspector: string,
  photographer: string,
  photoDate: string
): Promise<ArrayBuffer> {
  const backSource   = image.createImageSource(backBuffer);
  const backPixelMap = await backSource.createPixelMap({
    editable: false,
    desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
  });
  backSource.release();

  const backInfo = await backPixelMap.getImageInfo();
  const W = backInfo.size.width;
  const H = backInfo.size.height;

  const offscreen = new OffscreenCanvas(W, H);
  const ctx = offscreen.getContext('2d') as OffscreenCanvasRenderingContext2D;

  // PixelMap is accepted directly by drawImage in HarmonyOS
  ctx.drawImage(backPixelMap, 0, 0, W, H);
  backPixelMap.release();

  // PIP overlay (frontBuffer.byteLength > 0 means PIP data present)
  if (frontBuffer.byteLength > 0) {
    const frontSource   = image.createImageSource(frontBuffer);
    const frontPixelMap = await frontSource.createPixelMap({
      editable: false,
      desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
    });
    frontSource.release();

    const pipW   = Math.round(W * 0.18);
    const pipH   = Math.round(pipW * 0.67);
    const pipX   = Math.round(W * 0.02);
    const pipY   = Math.round(H * 0.03);
    const radius = Math.round(pipW * 0.05);

    ctx.save();
    ctx.beginPath();
    ctx.roundRect(pipX, pipY, pipW, pipH, [radius]);
    ctx.clip();
    ctx.drawImage(frontPixelMap, pipX, pipY, pipW, pipH);
    ctx.restore();

    ctx.strokeStyle = 'white';
    ctx.lineWidth   = Math.round(W * 0.002);
    ctx.beginPath();
    ctx.roundRect(pipX, pipY, pipW, pipH, [radius]);
    ctx.stroke();

    frontPixelMap.release();
  }

  // Watermark strip
  const stripH = Math.round(H * 0.18);
  const stripY = H - stripH;
  ctx.fillStyle = 'rgba(0,0,0,0.72)';
  ctx.fillRect(0, stripY, W, stripH);

  const fontSize    = Math.round(H * 0.028);
  const lineSpacing = Math.round(fontSize * 1.5);
  const textX       = Math.round(W * 0.02);
  const textY       = stripY + Math.round(H * 0.025);

  ctx.font         = `${fontSize}px "PingFang SC", "Noto Sans SC", sans-serif`;
  ctx.fillStyle    = 'white';
  ctx.textBaseline = 'top';

  const lines: string[] = [
    `任务号：${taskNumber}　机型：${deviceModel}　单位：${unit}`,
    `部位：${part}　部位区域：${partArea}`,
    `照相对应项目：${project}`,
    `操作者：${operator}　检验员：${inspector}　照相人：${photographer}　日期：${photoDate}`,
  ];
  for (let i = 0; i < lines.length; i++) {
    ctx.fillText(lines[i], textX, textY + i * lineSpacing);
  }

  // Encode to JPEG via PixelMap
  const composedPixelMap = ctx.getPixelMap(0, 0, W, H);
  const packer  = image.createImagePacker();
  const packed  = await packer.packing(composedPixelMap, { format: 'image/jpeg', quality: 93 });
  packer.release();
  composedPixelMap.release();

  return packed;
}

export class ImageCompositionService {
  static async composeImage(
    backBuffer: ArrayBuffer,
    frontBuffer: ArrayBuffer | null,
    metadata: FormData
  ): Promise<ArrayBuffer> {
    const front = frontBuffer !== null ? frontBuffer : new ArrayBuffer(0);
    const task = new taskpool.Task(
      composeImageTask,
      backBuffer,
      front,
      metadata.taskNumber,
      metadata.deviceModel,
      metadata.unit,
      metadata.part,
      metadata.partArea,
      metadata.project,
      metadata.operator,
      metadata.inspector,
      metadata.photographer,
      metadata.photoDate
    );
    const result = await taskpool.execute(task);
    return result as ArrayBuffer;
  }

  static async composePreview(
    backBuffer: ArrayBuffer,
    frontBuffer: ArrayBuffer | null,
    metadata: FormData
  ): Promise<image.PixelMap> {
    const composed = await ImageCompositionService.composeImage(backBuffer, frontBuffer, metadata);
    const source   = image.createImageSource(composed);
    const pixelMap = await source.createPixelMap({
      editable: false,
      desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
    });
    source.release();
    return pixelMap;
  }
}
