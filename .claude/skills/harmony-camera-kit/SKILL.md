---
name: harmony-camera-kit
description: Camera Kit usage for HarmonyOS — taking photos, video, dual-camera preview, picture-in-picture, camera session management, permissions. Trigger phrases: "camera", "take photo", "capture", "preview", "dual camera", "PIP", "borescope camera", "camera permission", "PhotoSession", "CameraManager".
---

# When to Use This Skill

Example trigger prompts:
- "Implement the camera capture page"
- "How do I show dual camera preview?"
- "Add front camera picture-in-picture"
- "Handle camera permission request"
- "Switch between back camera and borescope"

**For USB cameras (borescopes) connected via USB-C**: also read the
`harmony-usb-ddk` skill — Camera Kit may not see USB cameras natively.

---

# Core Classes & Import

```typescript
import { camera } from "@kit.CameraKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { common } from "@kit.AbilityKit";
```

---

# Standard Camera Pipeline

```
getCameraDevices()
  → createCameraInput(device)
    → createPreviewOutput(surface)    // XComponent surface
    → createPhotoOutput(surface)      // ImageReceiver surface
      → createSession(SceneMode.NORMAL_PHOTO)
        → addInput(cameraInput)
        → addOutput(previewOutput)
        → addOutput(photoOutput)
          → session.start()
```

## 1. Get Available Devices

```typescript
const cameraManager = camera.getCameraManager(context);
const devices: camera.CameraDevice[] = cameraManager.getSupportedCameras();

// Filter by position
const backCameras = devices.filter(
  d => d.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK
);
const frontCameras = devices.filter(
  d => d.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT
);
```

## 2. Create Inputs and Outputs

```typescript
// CameraInput
const cameraInput: camera.CameraInput =
  await cameraManager.createCameraInput(backCameras[0]);
await cameraInput.open();

// PreviewOutput — requires XComponent surface ID from UI
const previewProfile = getSupportedPreviewProfile(cameraManager, backCameras[0]);
const previewOutput: camera.PreviewOutput =
  await cameraManager.createPreviewOutput(previewProfile, surfaceId);

// PhotoOutput — requires ImageReceiver
import { image } from "@kit.ImageKit";
const imageReceiver = image.createImageReceiver(
  { width: 4096, height: 3072 },
  image.ImageFormat.JPEG,
  3  // capacity
);
const photoSurfaceId = await imageReceiver.getReceivingSurfaceId();
const photoProfile = getSupportedPhotoProfile(cameraManager, backCameras[0]);
const photoOutput: camera.PhotoOutput =
  await cameraManager.createPhotoOutput(photoProfile, photoSurfaceId);
```

## 3. Create and Start Session

```typescript
const session: camera.PhotoSession =
  await cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO);

await session.beginConfig();
await session.addInput(cameraInput);
await session.addOutput(previewOutput);
await session.addOutput(photoOutput);
await session.commitConfig();
await session.start();
```

## 4. Capture Photo

```typescript
const captureSettings: camera.PhotoCaptureSetting = {
  quality: camera.QualityLevel.QUALITY_LEVEL_HIGH,
  rotation: camera.ImageRotation.ROTATION_0,
};
await photoOutput.capture(captureSettings);

// Listen for captured image
imageReceiver.on("imageArrival", async () => {
  const img = await imageReceiver.readNextImage();
  const component = await img.getComponent(image.ComponentType.JPEG);
  const arrayBuffer = component.byteBuffer;  // JPEG bytes
  await img.release();
  // → pass arrayBuffer to image composition
});
```

---

# Dual Camera (MultiCameraSession)

## Check Support First

```typescript
const sceneModes = cameraManager.getSupportedSceneModes(backCameras[0]);
const supportsMulti = sceneModes.includes(camera.SceneMode.MULTI_CAMERA);
```

## MultiCameraSession Pipeline

```typescript
// Only available when supportsMulti === true
const multiSession: camera.MultiCameraSession =
  await cameraManager.createSession(camera.SceneMode.MULTI_CAMERA);

await multiSession.beginConfig();

// Add BOTH inputs
const backInput = await cameraManager.createCameraInput(backCameras[0]);
const frontInput = await cameraManager.createCameraInput(frontCameras[0]);
await backInput.open();
await frontInput.open();
await multiSession.addInput(backInput);
await multiSession.addInput(frontInput);

// Add outputs for both
await multiSession.addOutput(backPreviewOutput);
await multiSession.addOutput(frontPreviewOutput);  // PIP surface
await multiSession.addOutput(photoOutput);         // from back camera

await multiSession.commitConfig();
await multiSession.start();
```

## XComponent for PIP Preview

```typescript
// In ArkUI build()
XComponent({
  id: "pip-preview",
  type: XComponentType.SURFACE,
  controller: this.pipController
})
  .width(240)
  .height(160)
  .borderRadius(12)
  .onLoad(() => {
    const surfaceId = this.pipController.getXComponentSurfaceId();
    this.connectFrontPreview(surfaceId);
  })
```

---

# Permission Handling

Required permission (declare in `module.json5`):

```json5
"requestPermissions": [
  { "name": "ohos.permission.CAMERA" }
]
```

Runtime request (required on first launch):

```typescript
import { abilityAccessCtrl, Permissions } from "@kit.AbilityKit";

async requestCameraPermission(context: common.UIAbilityContext): Promise<boolean> {
  const atManager = abilityAccessCtrl.createAtManager();
  const perms: Permissions[] = ["ohos.permission.CAMERA"];
  const result = await atManager.requestPermissionsFromUser(context, perms);
  return result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
}
```

---

# Session Lifecycle — Critical

**Always release on page disappear to avoid camera-in-use errors:**

```typescript
aboutToDisappear(): void {
  this.releaseCamera();
}

async releaseCamera(): Promise<void> {
  try {
    await this.session?.stop();
    await this.session?.release();
    await this.cameraInput?.close();
    await this.previewOutput?.release();
    await this.photoOutput?.release();
  } catch (err) {
    console.error("Camera release error:", JSON.stringify(err));
  }
}
```

---

# Common Pitfalls

| Pitfall | Consequence | Fix |
|---|---|---|
| Not releasing session on `aboutToDisappear` | "Camera in use" error next open | Always release in lifecycle hook |
| Not calling `beginConfig`/`commitConfig` around changes | Session config errors | Always bracket config changes |
| Assuming `getSupportedCameras()` is sorted | Wrong camera selected | Filter by `cameraPosition` |
| Missing CAMERA permission in module.json5 | Crash on first API call | Add to `requestPermissions` AND request at runtime |
| Creating session before `cameraInput.open()` | Session start failure | Open input BEFORE creating session |
| Using `MULTI_CAMERA` on unsupported device | API exception | Always check `getSupportedSceneModes` first |

---

# USB Camera / Borescope Note

Camera Kit enumerates **native** cameras only. USB cameras (including
industrial borescopes connected via USB-C) are typically **NOT** visible
to Camera Kit. For USB cameras, read the `harmony-usb-ddk` skill.

If the hardware vendor provides a HarmonyOS SDK, use that SDK instead of
raw USB DDK.
