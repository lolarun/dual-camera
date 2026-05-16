# /compile-check — Verify HarmonyOS Project Compiles

Runs hvigor build and interprets any errors using the harmony-arkts-rules skill.

## Steps

1. Run the build from the project root:
   ```bash
   ./hvigorw assembleHap --no-daemon 2>&1
   ```
   (Use PowerShell on Windows: `.\hvigorw.bat assembleHap --no-daemon`)

2. Parse the output:
   - **Success** (exit 0, contains "BUILD SUCCESSFUL"): report success, list
     the generated .hap path
   - **ArkTS type errors**: read the `harmony-arkts-rules` skill, identify
     which forbidden pattern caused the error, show a before/after fix
   - **Module not found errors**: check `oh-package.json5` dependencies and
     `ohpm install` status
   - **Resource errors**: check `entry/src/main/resources/` structure
   - **Other errors**: show raw error with file:line reference

3. For each error found, offer to fix it inline

## Common Error Patterns

| Error message contains | Likely cause |
|---|---|
| `Type 'any' is not allowed` | Using `any` type — see arkts-rules |
| `Property does not exist` | Dynamic property add — declare in class |
| `Object literal may only specify known properties` | Object literal as model — use class |
| `Cannot find module` | Missing ohpm dependency or wrong import path |
| `is not assignable to type` | Type mismatch — add explicit type |
| `Decorator` related error | Missing/wrong decorator — see arkts-rules cheatsheet |
