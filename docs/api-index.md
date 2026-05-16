# API Documentation Index — 工业巡检拍照 App

Links into `harmonyos-api/` within this directory.

Before writing any API call, read the linked file first.

---

## Camera Kit — 相机

| What you need to implement | Document |
|---|---|
| Understand the camera pipeline | [camera-overview.md](harmonyos-api/media/camera/camera-overview.md) |
| Enumerate cameras, listen for status | [camera-device-management.md](harmonyos-api/media/camera/camera-device-management.md) |
| Open a camera input stream | [camera-device-input.md](harmonyos-api/media/camera/camera-device-input.md) |
| Configure session (add input/output, start) | [camera-session-management.md](harmonyos-api/media/camera/camera-session-management.md) |
| Preview stream on XComponent | [camera-preview.md](harmonyos-api/media/camera/camera-preview.md) |
| Capture a photo | [camera-shooting.md](harmonyos-api/media/camera/camera-shooting.md) |
| Full photo capture walkthrough | [camera-shooting-case.md](harmonyos-api/media/camera/camera-shooting-case.md) |
| **Dual-channel preview (front + back simultaneously)** | [camera-dual-channel-preview.md](harmonyos-api/media/camera/camera-dual-channel-preview.md) |
| Use system camera picker (no permission needed) | [camera-picker.md](harmonyos-api/media/camera/camera-picker.md) |
| Preparation & permissions | [camera-preparation.md](harmonyos-api/media/camera/camera-preparation.md) |

---

## Media Library — 相册 / 媒体库

| What you need to implement | Document |
|---|---|
| Overview of PhotoAccessHelper | [photoAccessHelper-overview.md](harmonyos-api/media/medialibrary/photoAccessHelper-overview.md) |
| Request permissions, set up helper | [photoAccessHelper-preparation.md](harmonyos-api/media/medialibrary/photoAccessHelper-preparation.md) |
| **Save photo to gallery (createAsset)** | [photoAccessHelper-resource-guidelines.md](harmonyos-api/media/medialibrary/photoAccessHelper-resource-guidelines.md) |
| **Create and manage user albums** | [photoAccessHelper-userAlbum-guidelines.md](harmonyos-api/media/medialibrary/photoAccessHelper-userAlbum-guidelines.md) |
| Query system albums (Camera Roll etc.) | [photoAccessHelper-systemAlbum-guidelines.md](harmonyos-api/media/medialibrary/photoAccessHelper-systemAlbum-guidelines.md) |
| Use SaveButton (restricted permissions) | [photoAccessHelper-savebutton.md](harmonyos-api/media/medialibrary/photoAccessHelper-savebutton.md) |

---

## Image Kit — 图像处理

| What you need to implement | Document |
|---|---|
| Decode JPEG bytes → PixelMap | [image-decoding.md](harmonyos-api/media/image/image-decoding.md) |
| Encode PixelMap → JPEG bytes | [image-encoding.md](harmonyos-api/media/image/image-encoding.md) |
| **PixelMap operations (crop, scale, flip)** | [image-pixelmap-operation.md](harmonyos-api/media/image/image-pixelmap-operation.md) |
| Receive image buffer from camera output | [image-receiver.md](harmonyos-api/media/image/image-receiver.md) |

---

## Database — 本地存储

| What you need to implement | Document |
|---|---|
| **SQLite via RelationalStore (RDB)** | [data-persistence-by-rdb-store.md](harmonyos-api/database/data-persistence-by-rdb-store.md) |
| Key-value settings via Preferences | [data-persistence-by-preferences.md](harmonyos-api/database/data-persistence-by-preferences.md) |
| Overview of local persistence options | [app-data-persistence-overview.md](harmonyos-api/database/app-data-persistence-overview.md) |

---

## File Management — 文件管理

| What you need to implement | Document |
|---|---|
| App sandbox directory paths | [app-sandbox-directory.md](harmonyos-api/file-management/app-sandbox-directory.md) |
| Read/write files in sandbox | [app-file-access.md](harmonyos-api/file-management/app-file-access.md) |
| Overview of app file capabilities | [app-file-overview.md](harmonyos-api/file-management/app-file-overview.md) |

---

## USB DDK — 孔探 / 外设

| What you need to implement | Document |
|---|---|
| **USB DDK for external devices** | [usb-ddk-guidelines.md](harmonyos-api/device/driver/usb-ddk-guidelines.md) |
| External device detection & permissions | [externaldevice-guidelines.md](harmonyos-api/device/driver/externaldevice-guidelines.md) |
| USB Serial DDK (alternative for some scopes) | [usb-serial-ddk-guidelines.md](harmonyos-api/device/driver/usb-serial-ddk-guidelines.md) |

---

## UI — 界面

| What you need to implement | Document |
|---|---|
| **Canvas / custom drawing (watermark)** | [arkts-drawing-customization-on-canvas.md](harmonyos-api/ui/arkts-drawing-customization-on-canvas.md) |
| State management overview | [state-management/](harmonyos-api/ui/state-management/) |
| Navigation between pages | [arkts-navigation-navigation.md](harmonyos-api/ui/arkts-navigation-navigation.md) |
| Custom dialog (confirmation modals) | [arkts-common-components-custom-dialog.md](harmonyos-api/ui/arkts-common-components-custom-dialog.md) |
| Toast notifications | [arkts-create-toast.md](harmonyos-api/ui/arkts-create-toast.md) |

---

## Security & Permissions — 权限

| What you need to implement | Document |
|---|---|
| Permission declaration & runtime request | [security/](harmonyos-api/security/) |

---

## Permissions Required by This App

Declared in `entry/src/main/module.json5`:

| Permission | Purpose |
|---|---|
| `ohos.permission.CAMERA` | Camera capture |
| `ohos.permission.READ_IMAGEVIDEO` | Query saved photos |
| `ohos.permission.WRITE_IMAGEVIDEO` | Save to gallery |
| `ohos.permission.ACCESS_DDK_USB` | USB borescope detection |
