---
name: swift-review
description: Review Swift/iOS code for bugs, security issues, and best practices violations
disable-model-invocation: true
argument-hint: "[file-or-directory]"
context: fork
agent: general-purpose
---

# Swift Code Review

Review the Swift/iOS code at `$ARGUMENTS` (or the entire `ios/AIIDPhoto/` directory if no argument given) for the following categories:

## 1. Logic Bugs
- Unreachable code (e.g., code after infinite `for await` loops)
- Race conditions in async/concurrent code
- Missing `@MainActor` on UI-mutating code
- Incorrect `Task` lifecycle (detached tasks not cancelled)
- Force unwraps that could crash

## 2. Security Issues
- API keys or secrets in client-side code
- Sensitive data stored in UserDefaults instead of Keychain
- Missing input validation on network responses
- HTTP instead of HTTPS endpoints

## 3. StoreKit 2 Issues
- Not finishing transactions
- Not checking revocation/expiration dates
- Missing `Transaction.currentEntitlements` check on launch
- Incorrect subscription status persistence

## 4. SwiftUI Anti-patterns
- Business logic in View body
- Heavy computation in View init
- Missing `@MainActor` on ObservableObject
- Deprecated API usage (e.g., old `onChange` signature)
- Memory leaks from strong reference cycles in closures

## 5. iOS Best Practices
- Not handling app lifecycle events (background/foreground)
- Missing error feedback to users (silent failures)
- Blocking main thread with synchronous operations
- Not using `Codable` for JSON parsing

## Output Format

For each issue found, report:
```
[SEVERITY] file.swift:LINE - Description
  Suggestion: How to fix it
```

Severity levels: CRITICAL (crash/security), WARNING (bug/anti-pattern), INFO (improvement)

Summarize findings at the end with counts per severity.
