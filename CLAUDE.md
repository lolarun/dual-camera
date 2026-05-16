# 工业巡检拍照 App — Claude Instructions
# Inspection Photo App — Development Instructions

---

## Project Context 项目背景

Industrial inspection photo management app for a manufacturing facility.
Used by inspectors who walk around the factory taking standardized photos
of equipment parts, often with a USB borescope attached to the tablet.

- **Target device**: Huawei MatePad Pro 11-inch (2560×1600, landscape ONLY)
- **Design viewport**: 1280×800 dp (landscape, no portrait support)
- **OS**: HarmonyOS Next
- **Deployment**: Enterprise sideload — single device, factory intranet, no server
- **Network**: Offline / single-device mode. No network calls. No sync.

---

## Conventions 编码规范

| Concern | Convention |
|---|---|
| Language | ArkTS strict mode (`.ets` files); **never** plain TypeScript for UI |
| UI text | All visible strings in Simplified Chinese (简体中文) |
| Comments | English only |
| Directories | kebab-case |
| ArkTS components | PascalCase |
| ArkTS functions / variables | camelCase |
| Build tool | `hvigor` (`./hvigorw assembleHap`); **never** npm/gradle |

---

## Directory Map

```
CLAUDE.md                ← This file (single source of truth for project instructions)

.claude/
  skills/                ← Skills (auto-loaded by Claude Code)
  commands/              ← Custom slash commands (/compile-check, /new-page)

design/
  prototype.md           ← Full design spec — all 9 screens, tokens, interaction rules

docs/
  harmonyos-api/         ← Huawei API reference
  api-index.md           ← Quick-lookup table: what to read before writing each API call
  README.md              ← Documentation index
  *.jpg                  ← Reference images

tools/
  codelinter-all.sh      ← Run codelinter

entry/                   ← (Created by DevEco Studio) Main module
AppScope/                ← (Created by DevEco Studio) App-level config
oh-package.json5         ← (Created by DevEco Studio) Dependencies
build-profile.json5      ← (Created by DevEco Studio) Build config
hvigorw / hvigorw.bat    ← (Created by DevEco Studio) Build script
```

---

## Feature Scope 功能范围

### Pages (Screens) to Implement

| # | Page Name (ArkTS) | Chinese Name | Description |
|---|---|---|---|
| 1 | `HomePage` | 首页 | Entry point, status, navigation |
| 2 | `MetadataFormPage` | 相片标示信息输入 | 10-field cascading form before capture |
| 3 | `EllipseDrawPage` | 照相点圈画 | Draw red ellipse on reference image |
| 4 | `CameraCapturePage` | 拍照界面 | Dual-camera capture with PIP overlay |
| 5 | `PostCaptureReviewPage` | 拍摄确认页 | Review composite + watermark, save |
| 6 | `HistoryListPage` | 历史记录 | Filter + 4-column photo grid |
| 7 | (Error states) | 错误与异常状态 | Modals, toasts, banners |
| 8 | `WorkLogPage` | 工作记录 | Monthly calendar + day detail |
| 9 | `TaskPhotoDetailPage` | 任务照片详情 | Photo grid + metadata + multi-select |

**Entry point**: `HomePage` (annotated `@Entry`)

### Hard Out-of-Scope (This Version)
- No network sync or cloud upload
- No multi-user authentication
- No print functionality
- No video recording

---

## Technical Constraints 技术约束

### ArkTS
- Strict mode — **always read `harmony-arkts-rules` skill before writing any `.ets`**
- All visible UI text in Simplified Chinese (简体中文)
- No `any`, no dynamic properties, no structural typing
- Minimum touch target: 56×56dp (users may wear gloves)

### Camera
- Primary: native back camera via Camera Kit (`harmony-camera-kit` skill)
- Secondary: USB borescope — check for vendor SDK first (`harmony-usb-ddk` skill)
- Dual-camera PIP: front camera in top-left overlay during capture
- Check `getSupportedSceneModes` before attempting `MultiCameraSession`

### Photo Storage
- **Dual-write strategy** (mandatory):
  1. Sandbox: `context.filesDir/tasks/{taskNumber}/{part}/{filename}.jpg`
  2. System gallery: flat album named `"巡检任务-{taskNumber}"`
- Filename format: `{taskNumber}-{part}-{photographer}-{YYYYMMDD}.jpg`
- Watermark: metadata strip at bottom of composed image, white text on semi-transparent black

### Database
- SQLite via RelationalStore (`harmony-storage` skill)
- Schema: `inspection_task` table — see skill for column definitions
- Preferences: store last-used inspector name, photographer name

### Permissions Required (in module.json5)
```json5
"requestPermissions": [
  { "name": "ohos.permission.CAMERA" },
  { "name": "ohos.permission.READ_IMAGEVIDEO" },
  { "name": "ohos.permission.WRITE_IMAGEVIDEO" },
  { "name": "ohos.permission.ACCESS_DDK_USB" }
]
```

---

## Form Field Definitions 表单字段定义

| # | Field | ArkTS name | Type | Constraints |
|---|---|---|---|---|
| 1 | 机型信息 | `deviceModel` | dropdown | Required; triggers field 4 enable |
| 2 | 任务号 | `taskNumber` | text | Required; format `[A-Z][0-9]{4,6}` |
| 3 | 单位 | `unit` | dropdown | Required |
| 4 | 部位 | `part` | dropdown | Required; **disabled until field 1 selected** |
| 5 | 部位区域 | `partArea` | dropdown | Depends on field 4 |
| 6 | 照相对应项目 | `project` | dropdown | **Disabled until field 5 selected** |
| 7 | 操作者 | `operator` | text | Required |
| 8 | 检验员 | `inspector` | text | Required; pre-filled from Preferences |
| 9 | 照相人 | `photographer` | text | Required; pre-filled with last-used value |
| 10 | 照相日期 | `photoDate` | date picker | Auto-filled today; editable |

Dropdown data is **hardcoded constants** (single-device, no server).
Define all dropdown data as `const` arrays in a separate `FormConstants.ets` file.

Cascade rules:
- Field 4 enabled only when field 1 is non-empty
- Field 6 enabled only when field 5 is non-empty
- Selecting field 1 resets fields 4, 5, 6 to empty
- Selecting field 4 resets fields 5, 6 to empty

---

## Design System 设计规范

Full design spec is in `design/prototype.md` — includes all 9 screens,
design tokens (colors, typography, spacing, component specs), interaction
patterns, and accessibility requirements.

### Color Tokens (Quick Reference)

| Token | Value | Usage |
|---|---|---|
| Primary | `#0066CC` | Buttons, links, active states |
| Primary-Dark | `#004C99` | Pressed state |
| Success | `#00A870` | Save confirmed, success toasts |
| Warning | `#FF9500` | Required field empty, device disconnected |
| Danger | `#D93025` | Errors, destructive actions |
| Background | `#F5F7FA` | Page background |
| Surface | `#FFFFFF` | Cards, form areas |
| Border | `#DCE0E6` | All dividers and borders |
| Text-Primary | `#1A1A1A` | Body text |
| Text-Secondary | `#666666` | Labels, helper text |
| Text-Disabled | `#999999` | Disabled state text |

**Never use font sizes below 16px** — factory lighting varies, gloves reduce precision.

---

## Interaction Patterns 交互规范

- Every destructive action (reset form, discard draft) requires a confirmation dialog
- Every async operation (save, compose) shows a progress indicator with cancel option
- Form drafts auto-save to Preferences every 30s; show "已自动保存草稿 · 刚刚" in top bar
- Back navigation from mid-form triggers "是否保存草稿？" dialog
- USB borescope hot-plug: show slide-in banner, auto-dismiss after 3s
- All dropdowns use bottom sheet picker style (not small dropdown menu)
- Success operations show green checkmark toast

---

## Critical Rules 关键规则

1. **ArkTS is NOT a TypeScript superset.** Before writing any `.ets` file,
   invoke the `harmony-arkts-rules` skill. Common LLM mistakes (using `any`,
   dynamic property addition, object literals as models) will fail to compile.

2. **HarmonyOS uses `hvigor`, not npm/gradle.** The build command is:
   `./hvigorw assembleHap`

3. **DevEco Studio initializes the HarmonyOS project skeleton.** Claude Code
   should not create `entry/`, `AppScope/`, or `build-profile.json5` manually.
   The workflow is: DevEco Studio creates skeleton → Claude Code adds logic.

4. **Read `design/prototype.md` before implementing any screen.** It is the
   single source of truth for layout, states, and component specs.

5. **Read `docs/api-index.md` before writing any API call.** It links to the
   relevant Huawei API reference document for each subsystem.

---

## Skill Inventory

| Skill | Trigger scenario |
|---|---|
| `harmony-arkts-rules` | Writing or reviewing any `.ets` / ArkTS code |
| `harmony-camera-kit` | Camera capture, preview, dual-camera, PIP |
| `harmony-media-library` | Save to album, query photos, PhotoAccessHelper |
| `harmony-storage` | SQLite, Preferences, local data persistence |
| `harmony-image-composition` | Watermark, PIP composite, OffscreenCanvas |
| `harmony-usb-ddk` | USB camera, borescope, external peripheral |

---

## Developer Workflow 开发工作流

1. **Before implementing any page**: read `design/prototype.md` and navigate
   to the corresponding screen spec. Understand the layout and component tree.

2. **Before writing any API call**: read `docs/api-index.md` and follow the
   link to the relevant Huawei API reference. Then read the corresponding Skill.

3. **After every component**: run `/compile-check`

4. **After every page**: test on MatePad Pro via hdc:
   ```bash
   hdc install entry/build/default/outputs/default/entry-default-signed.hap
   ```

---

## Reference Files 参考文件

| File | Purpose |
|---|---|
| `design/prototype.md` | Full design spec — 9 screens + tokens + interactions |
| `docs/api-index.md` | API doc quick-lookup table |
| `docs/harmonyos-api/` | Huawei official API reference |
| `.claude/skills/` | 6 Skills covering all major APIs |
