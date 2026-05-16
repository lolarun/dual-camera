# Project Documentation — 工业巡检拍照 App

## Files in This Directory

| File | Status | Purpose |
|---|---|---|
| `api-index.md` | Ready | Quick-lookup table for Huawei API reference docs |
| `harmonyos-api/` | Populated via fetch-docs | Huawei official API reference |
| `requirements.md` | TODO — place here | Original requirement document from client |

## API Documentation

Huawei API reference is at `harmonyos-api/` in this directory.

Relevant subdirectories:
- `harmonyos-api/media/camera/` — Camera Kit API reference
- `harmonyos-api/media/medialibrary/` — PhotoAccessHelper reference
- `harmonyos-api/database/` — RelationalStore & Preferences
- `harmonyos-api/media/image/` — PixelMap, ImagePacker, OffscreenCanvas
- `harmonyos-api/device/driver/` — USB Device Development Kit

Populate by running: `bash tools/fetch-harmony-docs.sh` from project root.
