# /new-page — Add a New ArkUI Page to the Current Project

Generates an ArkUI page skeleton and wires it into routing.

## Steps

1. Ask: "页面名称（PascalCase，例如 WorkLogPage）："
2. Ask: "这个页面从哪个页面跳转过来（例如 HomePage）："
3. Ask: "这个页面会跳转到哪些页面（逗号分隔，可留空）："
4. Ask: "这个页面的主要功能（一句话）："

Then:

1. Read the `harmony-arkts-rules` skill — apply all rules to the generated code
2. Create `entry/src/main/ets/pages/<PageName>.ets` with:
   - `@Entry @Component struct <PageName>`
   - `aboutToAppear()` and `aboutToDisappear()` lifecycle stubs
   - `build()` with a root `Column` or `Stack` matching the page purpose
   - Router import and navigation stubs to destination pages
   - A `// TODO: implement` comment on the main content area
   - All UI text in Chinese (use placeholders like `Text("页面标题")`)
3. Add route to `entry/src/main/resources/base/profile/main_pages.json`:
   ```json
   "pages/PageName"
   ```
4. If the source page is specified, show the router.pushUrl snippet to paste in:
   ```typescript
   router.pushUrl({ url: "pages/<PageName>" })
   ```
5. Remind: read `design/prototype.md` for this page's design before
   implementing any UI beyond the skeleton

## Page Skeleton Template

```typescript
import { router } from "@kit.ArkUI";

@Entry
@Component
struct <PageName> {
  // @State properties here

  aboutToAppear(): void {
    // Load data
  }

  aboutToDisappear(): void {
    // Release resources
  }

  build() {
    Column() {
      // TODO: implement <PageName> UI
      // Reference: design/prototype.html → Screen N
      Text("<PageName>")
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
    }
    .width("100%")
    .height("100%")
    .backgroundColor("#F5F7FA")
  }
}
```
