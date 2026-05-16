# 工业巡检拍照 App — 完整设计规范
# Inspection Photo App — Full Design Specification

> This is the single source of truth for all screens (1–9), design tokens,
> interaction patterns, and accessibility requirements. Developers should
> implement directly from this document.

---

# 1. Project Context 项目背景

Industrial inspection photo management app for a manufacturing facility.
Used by inspectors who walk around the factory taking standardized photos
of equipment parts, often with a USB borescope attached to the tablet.
Each photo is tagged with structured metadata (task number, equipment
model, inspection location, personnel) and saved with a watermark showing
that metadata at the bottom of the image.

## Target Device & Canvas

| Property | Value |
|---|---|
| Device | Huawei MatePad Pro 11-inch (industrial deployment) |
| Physical | 2560 × 1600 OLED, 16:10 aspect ratio |
| Design viewport | 1280 × 800 dp (landscape, ALWAYS landscape) |
| Density | 2x (design at 1x, assets prepared at 2x) |
| Minimum touch target | 56×56dp (users may wear light gloves) |
| OS | HarmonyOS Next |

## UI Language 界面语言

All visible UI text MUST be in Simplified Chinese (简体中文).
Code, comments, and component names in English.

| English | Chinese |
|---|---|
| Task Number | 任务号 |
| Device Model | 机型 |
| Unit | 单位 |
| Part / Location | 部位 |
| Part Area | 部位区域 |
| Photo Point | 照相点 |
| Inspection Project | 照相对应项目 |
| Operator | 操作者 |
| Inspector | 检验员 |
| Photographer | 照相人 |
| Photo Date | 照相日期 |
| Take Photo | 拍照 |
| Back Camera | 后置摄像头 |
| Front Camera (PIP) | 前置摄像头（画中画） |
| Borescope | 孔探设备 |
| Save | 保存 |
| Cancel | 取消 |
| Confirm | 确认 |

---

# 2. Design System 设计系统

## 2.1 Colors 颜色

| Token | Value | ArkTS | Usage |
|---|---|---|---|
| Primary | `#0066CC` | `Color.parse("#0066CC")` | CTA buttons, active tabs, links |
| Primary-Dark | `#004C99` | `Color.parse("#004C99")` | Pressed/hover state of primary |
| Success | `#00A870` | `Color.parse("#00A870")` | 保存成功, checkmark toasts |
| Warning | `#FF9500` | `Color.parse("#FF9500")` | Required field empty, device warning |
| Danger | `#D93025` | `Color.parse("#D93025")` | Inline errors, destructive actions |
| Background | `#F5F7FA` | `Color.parse("#F5F7FA")` | Page background |
| Surface | `#FFFFFF` | `Color.White` | Cards, form containers |
| Border | `#DCE0E6` | `Color.parse("#DCE0E6")` | All dividers and input borders |
| Text-Primary | `#1A1A1A` | `Color.parse("#1A1A1A")` | Body text, form values |
| Text-Secondary | `#666666` | `Color.parse("#666666")` | Labels, helper text, subtitles |
| Text-Disabled | `#999999` | `Color.parse("#999999")` | Disabled inputs, placeholder |
| Overlay-Dark | `rgba(0,0,0,0.72)` | — | Camera UI overlays, watermark strip |
| Overlay-Light | `rgba(255,255,255,0.15)` | — | Camera button backgrounds |

### Contrast Ratios (WCAG)

- Text-Primary (#1A1A1A) on Background (#F5F7FA): **17.5:1** ✓ AAA
- Text-Secondary (#666666) on Surface (#FFFFFF): **5.7:1** ✓ AA
- Primary (#0066CC) on Surface (#FFFFFF): **5.9:1** ✓ AA (large text: AAA)
- Minimum: body text 7:1 against background (WCAG AAA)

## 2.2 Typography 字体

**Font stack**: `"PingFang SC", "HarmonyOS Sans SC", "Noto Sans SC", sans-serif`

| Role | ArkTS | Size | Weight | Line Height |
|---|---|---|---|---|
| Page Title | `.fontSize(28).fontWeight(FontWeight.Bold)` | 28px | 700 | 1.3 |
| Section Header | `.fontSize(22).fontWeight(FontWeight.Medium)` | 22px | 600 | 1.4 |
| Body | `.fontSize(18).fontWeight(FontWeight.Normal)` | 18px | 400 | 1.5 |
| Form Label | `.fontSize(18).fontWeight(FontWeight.Medium)` | 18px | 500 | 1.4 |
| Button Text | `.fontSize(20).fontWeight(FontWeight.Medium)` | 20px | 600 | 1 |
| Helper / Error | `.fontSize(16).fontWeight(FontWeight.Normal)` | 16px | 400 | 1.4 |
| Watermark Text | — | 12px (scales with resolution) | 400 | 1.6 |

**Rule: Never use font size below 16px in the UI.** Factory lighting varies;
inspectors may be in low-contrast environments. Numeric fields use tabular-nums
for alignment.

## 2.3 Spacing 间距

All values in dp (device-independent pixels), follow 8dp grid.

| Token | Value | Usage |
|---|---|---|
| space-xs | 8dp | Icon padding, chip gap |
| space-sm | 16dp | Inline element gap |
| space-md | 24dp | Card padding |
| space-lg | 32dp | Section separator |
| space-xl | 48dp | Major page sections |

## 2.4 Component Specs 组件规格

### Buttons

| Variant | Height | Border Radius | Font |
|---|---|---|---|
| Primary (filled) | 56dp | 8dp | 20px/600 white |
| Primary Large (CTA) | 72dp | 8dp | 22px/600 white |
| Secondary (outlined) | 56dp | 8dp | 20px/600 primary blue |
| Destructive | 56dp | 8dp | 20px/600 white on Danger |
| Disabled | 56dp | 8dp | 20px/400 Text-Disabled on #E0E0E0 |

Touch ripple: white 30% opacity overlay on tap.
Haptic: 50ms light feedback on every tap.

### Input Fields

| Aspect | Value |
|---|---|
| Height | 56dp |
| Border | 1px solid Border (#DCE0E6) |
| Border (focused) | 2px solid Primary (#0066CC) |
| Border (error) | 2px solid Danger (#D93025) |
| Border radius | 8dp |
| Background | Surface (#FFFFFF) |
| Label position | Above field, 8dp gap |
| Error text position | Below field, 4dp gap, Danger color |

### Dropdowns (Bottom Sheet Style)

- Trigger: full-width tap target (56dp height)
- Picker: system bottom sheet (not small popup menu)
- Show selected value in field; placeholder in Text-Disabled when empty
- Disabled state: background #F0F0F0, text Text-Disabled, no ripple

### Camera Capture Button

| Property | Value |
|---|---|
| Diameter | 96dp |
| Outer ring | 3dp white stroke |
| Inner fill | solid white |
| Pressed inner fill | #E0E0E0 |
| Pressed scale | 0.94 with 100ms ease |

## 2.5 Layout Grid 布局网格

**Design viewport**: 1280×800dp landscape

| Zone | Width | Usage |
|---|---|---|
| Form page — left | 60% (768dp) | Metadata form |
| Form page — right | 40% (512dp) | Reference image + photo point preview |
| History — left sidebar | 25% (320dp) | Filters |
| History — right main | 75% (960dp) | Photo grid (4 columns) |
| Camera — full | 100% | Camera preview |
| Work log — left | 60% (768dp) | Calendar grid |
| Work log — right | 40% (512dp) | Day detail panel |

Safe zones:
- Status bar: 24dp top
- Navigation bottom: 0 (no system navigation bar in kiosk-style deployment)
- Touch-safe zone (right thumb, landscape): right 400dp, bottom 200dp → primary CTA here

## 2.6 Icons 图标

Use HarmonyOS system icons where available. Custom icons as SVG assets at
24×24dp (48×48dp @2x).

| Icon | System ID | Note |
|---|---|---|
| Camera | `ic_camera` | system |
| Settings | `ic_settings` | system |
| Back | `ic_back` | system, left chevron |
| Check | `ic_check_circle` | system |
| Warning | `ic_warning` | system |
| USB connected | `ic_usb_connected` | custom, green dot + USB symbol |
| USB disconnected | `ic_usb_disconnected` | custom, gray dot + USB symbol |
| Flash | `ic_flash_auto` / `ic_flash_off` | system |
| Grid | `ic_grid` | system |

All icons paired with text labels — never icon-only for primary actions.

---

# 3. Screens 页面设计

## Screen 1: 首页 / Home (Entry Point)

- Large app title "工业巡检拍照"
- Large primary button: "开始新任务" (full width, 72dp height)
- Secondary button: "历史记录" (view past photos, filterable by task/date)
- Secondary button: "工作记录" (outlined style, below "开始新任务", links to Screen 8)
- Top-right: settings icon, USB borescope connection status indicator
  (green dot = connected, gray = disconnected)
- Bottom: app version, current inspector name

---

## Screen 2: 相片标示信息输入 (Metadata Input)

2-column landscape layout. Left 60% = form, right 40% = preview area showing
"当前照相点" visual (a placeholder image with editable red ellipse marker —
show a small help hint: "点击图片圈画照相点位置").

### Form fields (in this exact order):

1. **机型信息** (dropdown, required) — triggers dependent fields
2. **任务号** (text input, required, validates against format `[A-Z][0-9]{4,6}`)
3. **单位** (dropdown, required)
4. **部位** (dropdown, required, DISABLED until 机型 selected, helper: "请先选择机型")
5. **部位区域** (dropdown, depends on 部位)
6. **照相对应项目** (dropdown, DISABLED until 部位区域 selected)
7. **操作者** (text input, required)
8. **检验员** (text input, required, pre-filled from Preferences)
9. **照相人** (text input, required, pre-filled with last-used value)
10. **照相日期** (date picker, auto-filled with today, editable)

### Cascade rules:

- Field 4 enabled only when field 1 is non-empty
- Field 6 enabled only when field 5 is non-empty
- Selecting field 1 resets fields 4, 5, 6 to empty
- Selecting field 4 resets fields 5, 6 to empty

### States to show:

- Error state: 任务号 with "任务号格式不正确" inline red error
- Sticky bottom bar: "重置" (outlined, left) + "下一步：拍照" (primary, right,
  disabled until all required filled)
- Auto-save indicator: "已自动保存草稿 · 刚刚" in top bar

---

## Screen 3: 照相点圈画 (Draw Red Ellipse on Reference Image)

Full-screen image with toolbar at top:
- Left: "返回" with confirmation if unsaved
- Center: instruction text "拖动绘制红色椭圆圈出照相点"
- Right: "撤销" / "重做" icons, "完成" primary button

Bottom: thin helper bar "提示：可多次调整椭圆位置和大小" with close icon.

---

## Screen 4: 拍照界面 (Camera Capture — Core Screen)

Full-screen camera preview with overlay UI. Two states:

### State 4a: Dual-camera supported (preview with PIP)

- Full-screen: rear camera preview
- Top-left PIP window (240×160dp, rounded 12dp, 2dp white border):
  front camera preview, with label "画中画"
- Top bar (translucent dark):
  - Left: "返回"
  - Center: task number + part ("任务号：A12345 · 右侧发动机")
  - Right: camera source toggle "原生后摄 | 孔探" (segmented control,
    "孔探" disabled with tooltip "请连接孔探设备" if not connected)
- Bottom bar (translucent dark):
  - Left: thumbnail of last photo (tap to preview)
  - Center: LARGE capture button (96dp diameter, white ring, center fill)
  - Right: flash toggle + grid toggle
- Bottom helper text (small): "拍摄后将自动添加水印"

### State 4b: Dual-camera not supported (draggable PIP placeholder)

- Same layout, but PIP window is a dashed-border rectangle with text
  "请拖动确定画中画位置" before capture begins.

---

## Screen 5: 拍摄确认页 (Post-Capture Review)

- Full-screen composed preview: back camera photo + front PIP inset +
  watermark at bottom with metadata text (semi-transparent black strip,
  all metadata in small text)
- Filename shown prominently: "A12345-右侧发动机-张三.jpg"
- Two big buttons:
  - "重拍" (outlined, left, 40% width)
  - "保存到相册" (primary green, right, 60% width)
- On save: success toast with checkmark animation "已保存 · 任务 A12345-001"

---

## Screen 6: 历史记录 (History List)

- Left sidebar (25%): filter panel
  - Date range picker
  - Task number search
  - Part filter (chips)
  - Camera source filter
- Right main (75%): grid of photo cards (4 columns), each card shows:
  - Thumbnail with PIP and watermark visible
  - Task number (bold)
  - Part + date (smaller)
  - Long-press = multi-select for batch export
- Top-right: "导出选中 (N)" button appears on selection
- Empty state: centered illustration + "暂无拍摄记录 · 点击首页开始新任务"

---

## Screen 7: 错误与异常状态 (Error & Edge Cases)

### 7a. Borescope disconnected during capture

Modal: warning icon, "孔探设备已断开，已切换至原生后摄。重新连接后可切回。"
Single button: "知道了"

### 7b. Storage low

Banner at top of home screen (amber background):
"存储空间不足（剩余 < 500MB），请尽快导出或清理历史记录"
With "去清理" action button.

### 7c. Network / sync not needed (single-device mode)

Small status chip in top bar: "单机模式" (gray, informational)

### 7d. Permission denied (first launch)

Full-screen permission request:
- Large icon
- Title: "需要以下权限才能工作"
- List: 相机 / 相册读写 / USB 外设访问
- Primary button: "授予权限"
- Link: "为什么需要这些权限？"

### 7e. Form validation error (inline)

Show 任务号 field with red border, error icon, text below:
"任务号应为字母和数字组合（示例：A12345）"

### 7f. Save failed

Toast: "保存失败，请重试" with red background, "重试" action.

---

## Screen 8: 工作记录 (Work Log — Calendar View)

Accessed from Screen 1 home via "工作记录" secondary button.

### Layout (landscape 1280×800)

**Top navigation bar** (height 64dp, white surface, 1dp bottom border):
- Left: 返回 icon + text
- Center: page title "工作记录"
- Right: view mode segmented control "日历 | 列表" (calendar active by default)

Main content area split into two columns:

### Left column: 日历区 (Calendar) — 60% width (~768dp)

**Year-month header bar** (height 72dp, centered):
- Left arrow button (56dp, outlined, chevron left)
- Center: big clickable title "2026 年 4 月" (32px / 600 weight)
  - Subtle down-caret icon indicating tappable for quick jump
- Right arrow button (56dp, outlined, chevron right)
- Far right: small outlined button "今天" (returns to current month)

**Weekday header row** (height 48dp):
- 一 / 二 / 三 / 四 / 五 / 六 / 日
- 18px / 500 weight / text-secondary #666666
- Weekends (六 / 日) lighter color (#999999)

**Calendar grid** (6 rows × 7 columns):
- Each cell: ~100dp wide × 90dp tall, 8dp gap between cells
- Cell states:

  1. **空工作日 (empty weekday)**: White surface, border #ECEEF2,
     date number top-left (22px / 400, #1A1A1A)

  2. **有任务日 (has tasks)**: White surface, border #DCE0E6,
     date number top-left (22px / 600, #1A1A1A),
     task count badge bottom-right:
     - Pill shape, background #E6F0FB, text #0066CC,
       padding 4dp 10dp, radius 12dp
     - Format: "3 任务" (16px / 600)
     - If count ≥ 10: #0066CC background with white text

  3. **周末 (weekend)**: Subtle diagonal stripe background
     (repeating-linear-gradient #F5F7FA / #FAFBFC, 45deg),
     date number #999999

  4. **今天 (today)**: White surface, 2dp solid border #0066CC,
     date number bold blue (#0066CC, 22px / 700)

  5. **选中日 (selected)**: Filled background #0066CC,
     date number white (22px / 700),
     task badge: white text on semi-transparent white background

  6. **其他月份日期 (adjacent months)**: Faded to #C0C4CC,
     no task badges, smaller font weight

- Realistic mock distribution:
  - ~60% of weekdays have tasks
  - Counts vary: 1-2 light, 3-5 normal, 8+ busy
  - One day shows "12 任务" for high-count emphasis style
  - Weekends mostly empty with 1-2 exceptions

**Bottom stats bar** (height 64dp, separator line above):
- Three inline stats: "本月任务 · 47" / "照片总数 · 328" / "工作天数 · 18"
- 18px / 500 / text-secondary
- Right side: small outlined button "导出本月记录"

### Right column: 当日详情 (Day Detail) — 40% width (~512dp)

**Day header** (height 80dp):
- Big date: "4 月 24 日" (28px / 600)
- Subtitle: "星期五 · 今天" or "星期三 · 2 天前" (18px / 400, text-secondary)
- Right: small icon button (more options, three dots)

**Summary row** (height 56dp, background #F5F7FA, padding 16dp):
- "共 3 个任务 · 27 张照片" (18px / 500)

**Task list** (scrollable, each task is a card):

Each task card (margin-bottom 12dp, padding 16dp, white surface,
border 1dp #DCE0E6, radius 8dp):
- Row 1: task number (bold, 20px / 600) + right-aligned timestamp
  "10:23 - 11:05" (16px / 400, text-secondary)
- Row 2: part location "右侧发动机 · 前端接口处" (18px / 500)
- Row 3: small inline tags — photographer, photo count
  - Tag style: small rounded pill, #F0F2F5 background, 14px text
  - e.g. "张三"  "9 张照片"  "原生后摄"
- Right edge: right-pointing chevron, card is tappable
- On tap: opens Screen 9

Sample task cards:
1. Task "A12345" · 右侧发动机 · 前端接口处 · 9 张照片 · 10:23-11:05
2. Task "A12346" · 左侧壳体 · 检修口 · 12 张照片 · 13:45-14:30
3. Task "A12348" · 尾部整流罩 · 外观 · 6 张照片 · 15:20-15:55

**Empty state** (when no tasks on selected day):
- Centered in right column
- Outlined icon (calendar with minus sign)
- Text: "这天没有拍摄记录" (20px / 500, text-secondary)
- Sub-text: "切换到其他日期查看" (16px / 400, text-disabled)

### Variant 8a: Quick year/month picker

Triggered by tapping the "2026 年 4 月" title.
Modal overlay centered on screen, ~480dp wide:
- Title: "选择年月"
- Two wheel pickers side by side: 年份 | 月份
- Years range: current year ± 2
- Bottom: "取消" (outlined) + "确定" (primary)

### Variant 8b: List view mode

When segmented control toggled to "列表":
Replace left column with a flat scrollable list grouped by month:
- Section header: "2026 年 4 月 · 47 任务"
- Each day row: "4 月 24 日 星期五 · 3 任务 · 27 张照片"
- Right column behavior unchanged

---

## Screen 9: 任务照片详情 (Task Photo Detail)

Accessed by tapping a task card from Screen 8. Slides in from right (300ms
ease-out). Route: `#/work-log/task/:id`

### Top navigation bar

- Left: 返回 icon + text (back to Screen 8, calendar remains underneath)
- Center: task number "任务 A12345" (20px / 600)
- Right: more-options icon (export, delete, etc.)

### Task metadata card

Margin 16dp, padding 20dp, white surface, border. Grid of key-value pairs
in 2 columns:

| Label | Value |
|---|---|
| 任务号 | A12345 |
| 机型 | 某某型号 |
| 单位 | 某某车间 |
| 部位 | 右侧发动机 |
| 部位区域 | 前端接口处 |
| 对应项目 | 螺栓紧固检查 |
| 照相人 | 张三 |
| 检验员 | 李四 |
| 操作者 | 王五 |
| 日期 | 2026-04-24 |

Label color: #666666, Value color: #1A1A1A, both 16px.

### Photo grid section

- Header: "拍摄照片 (9)" (20px / 600) + right: view toggle "网格 | 时间线"
- 3-column grid (each thumbnail ~150dp square, 12dp gap):
  - Rounded corners 8dp
  - Bottom overlay strip (semi-transparent black) showing time "10:23"
  - PIP badge: small "画" in top-right corner
  - Borescope badge: small "孔" in top-right corner (Warning #FF9500)
  - Tap: opens full-screen photo viewer with pinch-to-zoom

### Bottom action bar (sticky, height 72dp)

- Left: "选择" (outlined, enters multi-select mode)
- Right: "导出全部" (primary, full task export)

### Multi-select mode variant

- Top bar changes: "已选 3 张" + "全选" / "取消"
- Bottom bar: "导出 (3)" + "删除 (3)"
- Each thumbnail gets a checkbox in top-left corner

---

# 4. Routing 路由

Single-page app with hash-based routing:

| Route | Screen |
|---|---|
| `#/` | Screen 1: 首页 |
| `#/metadata` | Screen 2: 相片标示信息输入 |
| `#/draw-point` | Screen 3: 照相点圈画 |
| `#/camera` | Screen 4: 拍照界面 |
| `#/review` | Screen 5: 拍摄确认页 |
| `#/history` | Screen 6: 历史记录 |
| `#/work-log` | Screen 8: 工作记录 |
| `#/work-log/task/:id` | Screen 9: 任务照片详情 |

Screen 7 states are overlays/modals/toasts displayed contextually.

---

# 5. Interaction Requirements 交互规范

## Global Rules

- Every destructive action (reset form, discard draft, delete) requires confirmation dialog
- Every async operation (save, compose, export) shows progress indicator with cancel option
- Every successful operation shows confirmation (toast, checkmark, or inline success state)
- Form drafts auto-save to Preferences every 30s; show "已自动保存草稿 · 刚刚" in top bar
- Back navigation from mid-form triggers "是否保存草稿？" dialog
- Long operations (image save, watermark compositing) show progress bar, not just spinner
- All numeric inputs use number pad keyboard hint
- All date inputs use native wheel picker (not typed)

## Device Events

- USB borescope hot-plug: show slide-in banner on connection/disconnection,
  auto-dismiss after 3s
- Borescope disconnect during capture: modal warning, auto-switch to native camera

## Screen-Specific Transitions

- Switching calendar months (Screen 8): smooth horizontal slide transition
- Tapping a date (Screen 8): right column updates instantly (no spinner unless > 300ms)
- Tapping a task card (Screen 8 → 9): slides in from right (300ms ease-out)
- All touch targets ≥ 56dp even if visually smaller (add invisible hit area)
- Calendar grid is keyboard-navigable (arrow keys), show focus ring

---

# 6. Accessibility & Industrial Usability 无障碍与工业可用性

- All interactive elements have visible focus ring (for keyboard/stylus)
- Minimum 4.5:1 contrast for all text; 7:1 for primary text
- No reliance on color alone — always pair with icon or text label
- Error messages specific and actionable (not just "error")
- Support Chinese font scaling (user may increase system font size)
- Hit targets are fully opaque and at least 56×56dp
- Primary CTA always bottom-right in landscape (thumb-reachable zone)

---

# 7. Deliverable 交付物

Single self-contained HTML file (`prototype.html`) demonstrating all 9 screens
as interactive frames linked via click/tap. Hash-based client-side routing.
Include a "design system" panel at the top showing colors, typography, and
component tokens. All text in Simplified Chinese. Use Tailwind for styling.
Make it feel like a real HarmonyOS industrial app — clean, high-contrast,
no decorative elements.
