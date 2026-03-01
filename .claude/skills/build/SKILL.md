---
name: build
description: Build the AIIDPhoto Xcode project for iOS Simulator
disable-model-invocation: true
argument-hint: "[clean]"
allowed-tools: Bash(xcodebuild *), Bash(xcodegen *)
---

# Build AIIDPhoto

Build the iOS project for simulator. Pass `clean` as argument to do a clean build.

## Steps

1. Regenerate the Xcode project if `project.yml` has been modified:

```bash
xcodegen generate --spec project.yml
```

2. Build the project:

```bash
# If $ARGUMENTS contains "clean", add clean before build
xcodebuild \
  -project AIIDPhoto.xcodeproj \
  -scheme AIIDPhoto \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -quiet \
  build 2>&1
```

3. If the build fails:
   - Read the error output carefully
   - Identify the file and line number of each error
   - Read the failing source files
   - Fix the compilation errors
   - Rebuild to verify the fix

4. Report build results:
   - If succeeded: "Build succeeded" with any warnings
   - If failed: list each error with file:line and suggest fixes
