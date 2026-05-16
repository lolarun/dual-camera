---
name: harmony-arkts-rules
description: ArkTS strict typing rules and forbidden patterns. Use this skill whenever writing, reviewing, or debugging ArkTS (.ets) files — including ArkUI components, state management, data models, or any HarmonyOS-specific code. Trigger phrases: "write a component", "create a page", "add state", "define a model", "write ArkTS", "fix compile error", "review .ets".
---

# When to Use This Skill

Use this skill BEFORE writing any `.ets` file. Example prompts that should trigger it:
- "Help me create a CameraPage component"
- "Define a data model for task metadata"
- "Add @State for the form fields"
- "Why does this ArkTS code fail to compile?"
- "Write the logic for the dropdown cascade"

---

# ArkTS Is NOT TypeScript

ArkTS is a **strict static subset** of TypeScript designed for HarmonyOS. It is
compiled ahead-of-time and has NO runtime type checking, NO dynamic dispatch,
and NO JavaScript interoperability unless explicitly bridged. Treat it like a
statically typed language closer to Kotlin than TypeScript.

---

# Forbidden Patterns (Will Fail to Compile)

## 1. `any` and `unknown`

```typescript
// ❌ FORBIDDEN
let data: any = fetchSomething();
function process(input: unknown) { ... }

// ✅ CORRECT — always explicit types
let data: TaskRecord = fetchSomething();
function process(input: string): void { ... }
```

## 2. Dynamic Property Addition

```typescript
// ❌ FORBIDDEN — cannot add properties not declared in class
let obj = {};
obj.name = "test";         // compile error

// ✅ CORRECT — declare all fields upfront
class TaskRecord {
  taskNumber: string = "";
  deviceModel: string = "";
  operator: string = "";
}
```

## 3. Object Literals as Data Models

```typescript
// ❌ FORBIDDEN — object literal types are disallowed for complex models
interface PhotoMeta {
  taskId: string;
  part: string;
}
const meta: PhotoMeta = { taskId: "A001", part: "engine" }; // may error in strict contexts

// ✅ CORRECT — always use classes with explicit default values
class PhotoMeta {
  taskId: string = "";
  part: string = "";
}
const meta = new PhotoMeta();
meta.taskId = "A001";
```

## 4. Structural Typing / Duck Typing

```typescript
// ❌ FORBIDDEN — ArkTS uses nominal typing
function save(record: { id: string }) { ... }
save({ id: "1" }); // may not compile

// ✅ CORRECT — pass declared class instances
class SaveRequest {
  id: string = "";
}
const req = new SaveRequest();
req.id = "1";
save(req);
```

## 5. Function Overloading via Multiple Signatures

```typescript
// ❌ FORBIDDEN
function format(val: string): string;
function format(val: number): string;

// ✅ CORRECT — use union types or separate functions
function formatValue(val: string | number): string {
  if (typeof val === "string") return val;
  return val.toString();
}
```

## 6. Arrow Functions as Class Fields (for event handlers)

```typescript
// ❌ RISKY — can cause context issues with decorators
class MyComponent {
  handleTap = () => { this.count++; }  // may not work with @Watch
}

// ✅ CORRECT — use class methods
class MyComponent {
  handleTap(): void {
    this.count++;
  }
}
```

## 7. `namespace` Keyword

```typescript
// ❌ FORBIDDEN
namespace Utils { export function format() {} }

// ✅ CORRECT — use modules (one file = one module)
export function format(): string { return ""; }
```

## 8. Enum with Non-Literal Initializers

```typescript
// ❌ FORBIDDEN
const BASE = 10;
enum Code { A = BASE + 1 }  // non-literal initializer

// ✅ CORRECT
enum Code { A = 11 }
```

## 9. `instanceof` on Interface Types

```typescript
// ❌ FORBIDDEN — interfaces are erased at runtime
if (obj instanceof MyInterface) { ... }

// ✅ CORRECT — check a discriminator field or use class
class PhotoRecord { readonly type = "photo"; }
if (obj.type === "photo") { ... }
```

## 10. Optional Chaining on Non-Declared Properties

```typescript
// ❌ FORBIDDEN
const name = user?.profile?.name; // if profile not declared on user

// ✅ CORRECT — declare all fields or use explicit null checks
class User {
  profile: UserProfile | null = null;
}
const name = user.profile !== null ? user.profile.name : "";
```

---

# Required Patterns (ArkUI Components)

## Component Skeleton

```typescript
import { router } from "@kit.ArkUI";

@Entry       // only on the root page component
@Component   // required on every UI component
struct CameraPage {
  @State isCapturing: boolean = false;
  @Prop taskNumber: string = "";   // received from parent

  build() {
    Column() {
      // UI tree here
    }
    .width("100%")
    .height("100%")
  }
}
```

## State Management Decorator Cheatsheet

| Decorator | Scope | Direction | Use When |
|---|---|---|---|
| `@State` | Component-local | Internal | Component owns the value |
| `@Prop` | Parent → Child | One-way down | Child displays parent data |
| `@Link` | Parent ↔ Child | Two-way | Child can modify parent state |
| `@Provide` / `@Consume` | Ancestor ↔ Descendant | Two-way | Skip intermediate components |
| `@Watch("field")` | Same component | Reaction | Side effect on state change |
| `@StorageLink` | AppStorage ↔ Component | Two-way | Global app-level state |
| `@LocalStorageLink` | LocalStorage ↔ Component | Two-way | Page-scoped shared state |

```typescript
// @Watch usage — method name must match string
@State @Watch("onCountChange") count: number = 0;

onCountChange(): void {
  console.log(`count changed to ${this.count}`);
}
```

## Builder Functions

```typescript
// Reusable UI block within or across components
@Builder
function PrimaryButton(label: string, onClick: () => void): void {
  Button(label)
    .height(56)
    .backgroundColor("#0066CC")
    .onClick(onClick)
}
```

## @Styles and @Extend

```typescript
// @Styles — reusable attribute set (no parameters)
@Styles
function cardStyle(): void {
  .padding(24)
  .borderRadius(8)
  .backgroundColor(Color.White)
}

// @Extend — extend a specific component type
@Extend(Text)
function labelText(): AttributeModifier<TextAttribute> {
  .fontSize(18)
  .fontWeight(FontWeight.Medium)
  .fontColor("#1A1A1A")
}
```

---

# Data Models — Always Use Classes

```typescript
// All form data as a single class with defaults
class InspectionFormData {
  deviceModel: string = "";
  taskNumber: string = "";
  unit: string = "";
  part: string = "";
  partArea: string = "";
  inspectionProject: string = "";
  operator: string = "";
  inspector: string = "";
  photographer: string = "";
  photoDate: string = "";  // ISO date string "YYYY-MM-DD"
}

// Usage in component
@State formData: InspectionFormData = new InspectionFormData();
```

---

# Lifecycle Methods

```typescript
@Entry @Component
struct MyPage {
  aboutToAppear(): void {
    // Called when component is ready — load data here
  }

  aboutToDisappear(): void {
    // Called before destroy — release resources here (camera, DB connections)
  }

  onPageShow(): void {
    // Called when page becomes visible (routing back to this page)
  }

  onPageHide(): void {
    // Called when navigating away from this page
  }

  build() { ... }
}
```

---

# Async Operations

```typescript
// ArkTS supports async/await — always use for I/O
async loadData(): Promise<void> {
  try {
    const records: TaskRecord[] = await dbService.queryAll();
    this.taskList = records;
  } catch (err) {
    const error = err as BusinessError;
    console.error(`DB error: ${error.code} ${error.message}`);
  }
}

// Trigger from lifecycle
aboutToAppear(): void {
  this.loadData();  // intentionally not awaited at top level
}
```

---

# After Writing Any Non-Trivial Component

Always suggest running:
```bash
cd projects/<project-name> && ./hvigorw assembleHap --no-daemon
```

Compilation errors are the ground truth. ArkTS type errors caught at compile
time are much cheaper to fix than runtime issues.
