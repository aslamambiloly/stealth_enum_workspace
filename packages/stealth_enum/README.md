
<p align="center">
  <a href="https://pub.dev/packages/stealth_enum"><img src="https://img.shields.io/pub/v/stealth_enum.svg" alt="pub version"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.3%2B-blue?logo=dart" alt="Dart"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.19%2B-blue?logo=flutter" alt="Flutter"></a>
  <br>
  <a href="https://codecov.io/gh/aslamambiloly/stealth_enum_workspace"><img src="https://codecov.io/gh/aslamambiloly/stealth_enum_workspace/graph/badge.svg" alt="codecov"></a>
</p>

<p align="center">
  <a href="https://ko-fi.com/N7K021PF59"><img src="https://raw.githubusercontent.com/aslamambiloly/curved_navigation_bar_pro/main/doc/coffee.png" alt="Support me on Ko-fi" width="400"></a>
</p>

A Zero Overhead Dart & Flutter code generator that hides enum metadata, randomizes enum values, and makes AOT binaries harder to reverse engineer (REA, Blutter, Ghidra etc.).

## The `Issue` : (
You maybe already doing:

✅ `--obfuscate --split-debug-info=.`<br>
✅ SSL Certificate Pinning.<br>
✅ App Attest & App Integrity.<br>
✅ [freeRasp](https://pub.dev/packages/freerasp).<br>
✅ [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage).<br>
✅ [envied](https://pub.dev/packages/envied).<br>

Do you feel like you are protected? Yes, but there's a small catch when it comes to reverse engineering. 

❌ **Dart enums still expose their names intentionally in compiled AOT binaries**.

## The `Solution` : )
When you compile a Flutter app with `--obfuscate --split-debug-info`, Dart strips class and function symbols. But **enum identifier strings are intentionally preserved** in the Dart Object Pool (`pp.txt` in Blutter) just to support `.name` and `.toString()`.

AI assisted reverse engineering pipelines like **REA (Reverse Engineer Anything)**, **Blutter**, and **Ghidra** use these plain text strings as anchors. They locate the string in decompiled assembly, trace cross-references back to your obfuscated business logic, and reconstruct your licensing, authentication, and security checks.

Standard enums also compile to sequential indices (`0, 1, 2, 3`), creating predictable jump tables that decompilers immediately identify.


```text
// What Blutter sees in pp.txt (Standard Enum):
"SubscriptionStatus"  "trial"  "active"  "expired"  "cancelled"

// What Ghidra sees in ARM64 (With stealth_enum):
CMP W0, #0x4B91E20A   // Is it a math constant? Hash? Memory offset?
CMP W0, #0x7C104F8B
CMP W0, #0x1D55A9C3
```

## What to change in the `code`?
Not much! Just make your enums private and add `@StealthEnum()` annotation to it just like the image below:



<p>
  <img src="https://raw.githubusercontent.com/aslamambiloly/stealth_enum_workspace/main/doc/difference-rounded.png" width="550" alt="Code difference"/>
</p>

**Sabaaaash! That's it!** You just protected yourself from simple AI assisted reverse engineering attacks.

 Now run:



```bash
dart run build_runner build --delete-conflicting-outputs
# or for Flutter:
flutter pub run build_runner build --delete-conflicting-outputs
```


And enjoy using the **same enum class** with **same enum name** as if nothing has changed just like below image!

<p>
  <img src="https://raw.githubusercontent.com/aslamambiloly/stealth_enum_workspace/main/doc/before-after.png" width="550" alt="Before and After"/>
</p>

## Table of Contents

- [Compatibility](#compatibility)
- [Features](#features)
- [Getting started](#getting-started)
- [Usage](#usage)
  - [1. Annotate a private enum](#1-annotate-a-private-enum)
  - [2. Run the code generator](#2-run-the-code-generator)
  - [3. Use the generated extension type](#3-use-the-generated-extension-type)
  - [Custom seed for deterministic builds](#custom-seed-for-deterministic-builds)
  - [Custom type name](#custom-type-name)
  - [Safe Parsing & Zero-Crash Architecture](#safe-parsing--zero-crash-architecture)
  - [Serialization & Logging (generateLabel)](#serialization--logging-generatelabel)
- [Migration Guide](#migration-guide)
  - [Step-by-step migration from standard enum](#step-by-step-migration-from-standard-enum)
  - [Pattern matching](#pattern-matching)
  - [Serialization / JSON](#serialization--json)
  - [Logging & debugging](#logging--debugging)
  - [Persistence & version safety](#persistence--version-safety)
  - [Common patterns side-by-side](#common-patterns-side-by-side)
- [Generated Output](#generated-output)
- [AOT Verification](#aot-verification)
- [API Reference](#api-reference)
  - [`@StealthEnum`](#stealthenum)
  - [Generated Extension Type](#generated-extension-type)
- [Under the Hood](#under-the-hood)
- [Running the example](#running-the-example)
- [Contributing](#contributing)
- [License](#license)

## Compatibility

> `stealth_enum` is implemented entirely in **pure Dart**. So don't worry about:
> - **iOS Swift Package Manager (SPM)**: 100% compatible. Requires no CocoaPods or native SPM configuration.
> - **Android Gradle Plugin (AGP 9.0+)**: 100% immune to Kotlin Gradle Plugin (KGP) deprecations and breaking changes.


## Features


- **Zero Binary String Footprint**: Completely removes enum and constant names from compiled AOT binaries.
- **Non-Sequential Entropy**: Replaces predictable sequential indices with high-entropy 32-bit hex values.
- **Zero Runtime Overhead**: Built on Dart 3.3+ `extension type const` over primitive `int` with zero heap allocation and zero boxing.
- **Inlined Pattern Matching**: `@pragma('vm:prefer-inline')` on `.when()` and `.maybeWhen()` inlines branches directly into call sites.
- **No `StateError` String Leaks**: The fallback branch in `.when()` uses a wildcard `_ =>` rather than throwing an exception with class names.
- **Guaranteed Tree-Shaking**: The private annotated enum (`_MyEnum`) is discarded by the compiler; only the lightweight extension type remains.
- **Deterministic CI Builds**: Optional compile-time `seed` parameter guarantees reproducible builds across team members and CI pipelines.
- **Standard Enum Ergonomics**: `.values`, equality (`==`), exhaustive `.when()`, safe `tryFromRawValue()`, and optional `.label` / `byLabel()` / `toJson()` / `fromJson()` for serialization scenarios.
- **Pure Dart**: Zero native code, zero CocoaPods or Gradle headaches.
- **AOT Verification Script**: Included shell script proves string removal empirically on your own machine.

<div align="center">

| Feature | Standard Dart `enum` | `@StealthEnum` |
|:---:|:---:|:---:|
| **Strings in Binary** | Plain-text in Object Pool (`pp.txt`) | **Zero** strings in binary (with `generateLabel: false`) |
| **Index Pattern** | Sequential `0, 1, 2, 3` (jump tables) | Non-sequential 32-bit hex (`0x4B91E20A`) |
| **Runtime Cost** | Wrapper object allocation | **Zero** (erases to raw primitive `int`) |
| **Exhaustive Matching** | Native `switch` statement | Inlined `.when()` / `.maybeWhen()` |
| **Safe Parsing** | `.values.byName()` throws on unknown | `tryFromRawValue()` returns null |
| **Decompiler Visibility** | Anchors for REA & Ghidra | Indistinguishable from random constants (with secret key; default salt dictionary-recoverable) |
| **Tree-Shaking** | Kept in binary | **100% tree-shaken** (private source enum) |

</div>


## Getting started

Add `stealth_enum` to your `pubspec.yaml`:

```yaml
dependencies:
  stealth_enum: ^2.2.4

dev_dependencies:
  build_runner: ^2.4.0
  stealth_enum_generator: ^2.2.4
```

Then run:

```bash
dart pub get
# or for Flutter:
flutter pub get
```

## Usage

### 1. Annotate a private enum

Define your enum as a **private** enum (prefixed with `_`) and add the `part` directive:

```dart
// lib/security_clearance.dart
import 'package:stealth_enum/stealth_enum.dart';

part 'security_clearance.g.dart';

@StealthEnum()
enum _SecurityClearance {
  guest,
  operator,
  admin,
  superAdmin,
}
```

### 2. Run the code generator

Generate the obfuscated extension types using `build_runner`:

```bash
dart run build_runner build --delete-conflicting-outputs
# or for Flutter:
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Use the generated extension type

The generated `SecurityClearance` extension type provides compile-time type safety with zero runtime cost:

```dart
import 'security_clearance.dart';

void authorize(SecurityClearance clearance) {
  // Exhaustive pattern matching (fully inlined at compile-time):
  final role = clearance.when(
    guest: () => 'Guest Access',
    operator: () => 'Operator Access',
    admin: () => 'Administrator Access',
    superAdmin: () => 'Super Admin Access',
  );
  print(role);
}

void main() {
  authorize(SecurityClearance.admin); // → "Administrator Access"

  // Partial matching with required fallback:
  final canEdit = SecurityClearance.operator.maybeWhen(
    admin: () => true,
    superAdmin: () => true,
    orElse: () => false,
  );
  print(canEdit); // → false

  // Extension types erase to int at runtime:
  assert(SecurityClearance.admin as Object is int); // true ✓

  // Direct equality check:
  if (clearance == SecurityClearance.superAdmin) {
    unlockAllDoors();
  }

  // Iterate over all values:
  for (final level in SecurityClearance.values) {
    print(level.rawValue); // prints hex int (e.g. 0x7C06254C)
  }
}
```

### Secret key for cryptographic secrecy

For cryptographic resistance against dictionary recovery, supply a secret key (minimum 24 characters recommended):

```dart
@StealthEnum(key: 'your-project-secret-salt-here-or-env')
enum _SubscriptionTier {
  free,
  pro,
  enterprise,
}
```

> [!TIP]
> **Preferred Key Configuration:** In production, configure the secret key project-wide in `build.yaml` or via the `STEALTH_ENUM_KEY` CI environment variable so keys are not hardcoded in source files.
>
> *(Note: A legacy `seed: int` parameter is also supported as a 32-bit namespace separator, but provides low entropy. Use `key:` for cryptographic protection).*

### Custom type name

By default, the public extension type name strips the leading `_` from your private enum (`_SecurityClearance` → `SecurityClearance`). You can customize this with `name`:

```dart
@StealthEnum(name: 'AppRole')
enum _RoleInternal {
  user,
  admin,
}
```

### Safe Parsing & Zero-Crash Architecture

`stealth_enum` provides comprehensive compile-time (AOT) and runtime safety guarantees so your app remains resilient:

#### 1. Compile-Time Exhaustiveness (AOT Safety)
Every branch in `.when()` is marked `required`. If you add a new constant to your private enum, Dart's type checker refuses to compile your app until you handle it. It is impossible to forget a case at compile time.

#### 2. Safe Parsing from Untrusted Inputs (`tryFromRawValue`)
When reading integer values from network APIs, JSON, databases, or local storage, use `tryFromRawValue()` to prevent unexpected runtime errors:

```dart
// Safely parses raw integers, returning null if unknown (zero crashes!):
final role = SecurityClearance.tryFromRawValue(json['clearance']) ?? SecurityClearance.guest;
```

#### 3. Graceful Fallbacks (`maybeWhen`)
For partial matching with a guaranteed safe fallback, use `.maybeWhen()`:

```dart
role.maybeWhen(
  admin: () => unlockAdminPanel(),
  superAdmin: () => unlockFullAccess(),
  orElse: () => showDefaultView(), // Executed for any other or unknown value
);
```

#### 4. Instance Validation (`isValid`)
Easily verify whether an instance holds a recognized enum constant:

```dart
if (role.isValid) {
  // Safe to proceed
}
```

#### 5. Fail-Closed Security
If an invalid raw integer reaches `.when()`, it fails closed by throwing `StateError('')` rather than accidentally granting unauthorized privileges to the last branch.

### Zero-Overhead JSON Serialization (`toJson` / `fromJson`)

Every generated extension type automatically includes `toJson()` and `fromJson(int)` helpers:

```dart
// Serializes directly to raw integer (0 string overhead, completely stealthy):
final json = {'role': clearance.toJson()}; // → {'role': 0x7C06254C}

// Safely deserializes from raw integer, returning null if unknown:
final restored = SecurityClearance.fromJson(json['role'] as int); // → SecurityClearance.admin
```

Because these helpers operate exclusively on integers, they produce **zero string literals** in your compiled binary.

### Explicit Values for Databases & APIs (`@StealthValue`)

If you are persisting enum values in a long-lived database (Hive, SQLite, SharedPreferences) or exchanging them with an external API, use `@StealthValue` to lock exact raw integers:

```dart
@StealthEnum()
enum _PaymentGateway {
  @StealthValue(0x10000001)
  stripe,

  @StealthValue(0x20000002)
  applePay,

  @StealthValue(0x30000003)
  googlePay,
}
```

- **Rename-proof**: You can rename `applePay` to `applePaySheet` without changing its stored `0x20000002` integer.
- **Order-proof**: Adding, deleting, or reordering other variants will never alter annotated values.

### Display Labels & Logging (`generateLabel`)

By default, `stealth_enum` emits **zero string literals** into the binary. For debugging, logging, or UI pickers where you need human-readable names, enable `generateLabel`:

> [!WARNING]
> **Security trade-off**: Enabling `generateLabel: true` emits plain-text label strings (e.g. `'admin'`, `'superAdmin'`) into the generated `.g.dart` file, which **will appear in the compiled binary**. The private source enum is still fully tree-shaken, but the generated labels re-introduce readable identifiers. Only enable this when you genuinely need UI labels or logging and accept this trade-off.

```dart
@StealthEnum(generateLabel: true)
enum _AppTheme {
  light,
  dark,
  system,
}
```

This generates `.label` and `byLabel()` on the extension type:

```dart
// .label — equivalent to .name on a standard enum
print(AppTheme.dark.label); // → 'dark'

// byLabel() — equivalent to AppTheme.values.byName() (returns null if not found)
final theme = AppTheme.byLabel('dark'); // → AppTheme.dark (or null)
```

---

## Migration Guide

> This guide shows you how to migrate from standard Dart enums to `stealth_enum` step by step, with side-by-side comparisons for the most common patterns.

### Step-by-step migration from standard enum

**Before** (standard enum):
```dart
// user_role.dart
enum UserRole {
  viewer,
  editor,
  admin,
}
```

**After** (stealth_enum):
```dart
// user_role.dart
import 'package:stealth_enum/stealth_enum.dart';

part 'user_role.g.dart';   // ← add this

@StealthEnum()             // ← annotate
enum _UserRole {           // ← make private (add _)
  viewer,
  editor,
  admin,
}
```

Then run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

The generator produces `user_role.g.dart` with a `UserRole` extension type. **Your call sites need zero changes** for equality checks and `.values` iteration.

---

### Pattern matching

| Standard enum | stealth_enum |
|---|---|
| `switch (role) { case UserRole.admin: ... }` | `role.when(admin: () => ..., viewer: () => ..., editor: () => ...)` |
| Non-exhaustive `switch` (compile warning) | Non-exhaustive → use `.maybeWhen(orElse: ...)` |
| `role == UserRole.admin` | `role == UserRole.admin` ✓ (unchanged) |

```dart
// Standard enum switch
switch (role) {
  case UserRole.admin:
    showAdminPanel();
  default:
    showDefaultView();
}

// stealth_enum equivalent (exhaustive — compiler forces all cases)
role.when(
  viewer: () => showDefaultView(),
  editor: () => showDefaultView(),
  admin: () => showAdminPanel(),
);

// stealth_enum partial match (use maybeWhen for non-exhaustive)
role.maybeWhen(
  admin: () => showAdminPanel(),
  orElse: () => showDefaultView(),
);
```

---

### Serialization / JSON

Standard enums are often serialized as strings (`.name`) or indices (`.index`). **Do not use `.index` with stealth_enum** — the raw values are not sequential integers. Always use `.rawValue` / `tryFromRawValue()`.

```dart
// ── Serializing ──────────────────────────────────────────────────────────────

// Standard enum — serialized as string (fragile if enum is renamed)
final json = {'role': role.name}; // → {'role': 'admin'}

// stealth_enum — serialize as raw int (opaque, zero strings in binary)
// Tip: Use @StealthValue(int) to keep rawValue completely immutable across renames
final json = {'role': role.rawValue}; // → {'role': 0x5B7DA15D}

// ── Deserializing ────────────────────────────────────────────────────────────

// Standard enum — throws if string doesn't match
final role = UserRole.values.byName(json['role'] as String);

// stealth_enum — returns null on unknown value (safe)
final role = UserRole.tryFromRawValue(json['role'] as int)
    ?? UserRole.viewer; // safe default

// ── With generateLabel: true (optional, see security trade-off) ──────────────
// toJson / fromJson helpers mirror json_serializable conventions:
final json = {'role': role.toJson()};             // int
final role = UserRole.fromJson(json['role'] as int); // T?
```

> **Persistence tip**: Always store the raw integer value alongside a schema version. If you ever change the enum names or re-generate with a different seed, you can migrate stored values using the old hex constants directly.

#### Working with `json_serializable`

`stealth_enum` is compatible with `json_serializable`. Use a custom converter:

```dart
import 'package:json_annotation/json_annotation.dart';
import 'user_role.dart';

class UserRoleConverter implements JsonConverter<UserRole, int> {
  const UserRoleConverter();

  @override
  UserRole fromJson(int json) =>
      UserRole.tryFromRawValue(json) ?? UserRole.viewer;

  @override
  int toJson(UserRole role) => role.rawValue;
}

@JsonSerializable()
class UserProfile {
  @UserRoleConverter()
  final UserRole role;

  const UserProfile({required this.role});
  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}
```

---

### Logging & debugging

Without `generateLabel`, `.toString()` on an extension type returns the raw integer. For logging:

```dart
// Option A: Use .rawValue in logs (most secure — no strings in binary)
log('User role changed to rawValue=${role.rawValue}');

// Option B: Enable generateLabel: true and use .label (strings appear in binary)
@StealthEnum(generateLabel: true)
enum _UserRole { viewer, editor, admin }

log('User role changed to ${role.label}'); // → 'admin'

// Option C: Manual map in your own code (strings only in your file, not enum)
const _roleNames = {
  UserRole.viewer: 'Viewer',
  UserRole.editor: 'Editor',
  UserRole.admin: 'Administrator',
};
log('User role changed to ${_roleNames[role]}');
```

---

### Persistence & Stability Model

`stealth_enum` uses **keyed HMAC-SHA256** over `'$publicName::$fieldName'` to derive constant values.

#### Key Precedence & Security Hierarchy

1. **Enum-level secret key**: `@StealthEnum(key: '...')`
2. **Project-wide secret key**: `build.yaml` option or `STEALTH_ENUM_KEY` environment variable
3. **Enum-level seed**: `@StealthEnum(seed: 0xCAFEBABE)` *(32-bit namespace separator)*
4. **Default salt**: `'stealth_enum:default_salt:0xDEADBEEF'` *(zero-configuration default)*

#### Threat Model: Default Salt vs. `seed` vs. Secret `key`

| Mechanism | Resistance to Dictionary & Rainbow Table Recovery | Best Used For |
|---|---|---|
| **Default Salt** | ⚠️ **Low** — Default salt is public in the open-source generator. If an attacker extracts integers and guesses the enum name, they can test common wordlists. | Prototyping and internal enums with no security sensitivity. |
| **`seed: <int>`** | ⚠️ **Low** — 32-bit space ($2^{32} \approx 4.29 \times 10^9$) can be brute-forced in ~1.7 hours on a single CPU core and minutes on GPU. | Preventing accidental value collisions across different enums. |
| **`key: '<secret>'`** | 🛡️ **Cryptographically Secure** — 128+ bit entropy makes dictionary and brute-force preimage attacks mathematically infeasible. | **Production security-sensitive enums (roles, entitlements, feature flags).** |

> [!TIP]
> **Build-Time Only Secrecy:** The `key` is used **exclusively at build time** by `build_runner` to compute 32-bit integer constants. It is **NEVER** emitted into the generated `*.g.dart` file and **NEVER** compiled into the binary.

##### Generating a High-Entropy Secret Key

Generate a 24-character random URL-safe secret in your terminal:
```bash
python3 -c "import secrets; print(secrets.token_urlsafe(24))"
```

##### Project-Wide Secret Key in `build.yaml` or CI Environment

Instead of placing secret strings inside your Dart source files, you can define a repository-wide secret in `build.yaml`:

```yaml
targets:
  $default:
    builders:
      stealth_enum_generator:stealth_enum:
        options:
          key: "YOUR_HIGH_ENTROPY_BUILD_SECRET"
          require_key: true  # Fails build if any enum lacks a secret key
```

Or pass it dynamically in CI via the `STEALTH_ENUM_KEY` environment variable without committing the secret to source control:

```bash
export STEALTH_ENUM_KEY="YOUR_HIGH_ENTROPY_BUILD_SECRET"
export STEALTH_ENUM_REQUIRE_KEY="1"  # Guarantees CI fails if secret is missing or empty
dart run build_runner build --delete-conflicting-outputs
```

> [!CAUTION]
> **Enforce `require_key: true` in CI:**
> If an unset CI secret evaluates to an empty string (`""`), unkeyed builds will fall back to the public default salt with a compile-time warning. Setting `require_key: true` or `STEALTH_ENUM_REQUIRE_KEY="1"` ensures your CI pipeline immediately fails hard if the secret key is missing.

> [!NOTE]
> **Build Caching Notice:**
> `build_runner` caches generated artifacts and does not automatically detect changes in environment variables across invocations. Whenever you set, change, or rotate your secret keys, run:
> ```bash
> dart run build_runner clean
> ```

##### Key Fingerprint Verification

When a secret key is configured, `stealth_enum_generator` includes an 8-character domain-separated HMAC-SHA256 fingerprint comment in each generated file:

```dart
// Key fingerprint: a4f8e219
extension type const SecretStatus._(int rawValue) {
```

This fingerprint (`HMAC-SHA256(key, 'stealth_enum:fingerprint:v1')`) allows CI checks and reviewers to verify that files were generated with the expected secret key without exposing the key itself. To prevent offline dictionary matching against short passwords, the generator issues a compile-time warning if a key is under 24 characters. (Enums whose constants are all frozen with `@StealthValue` omit the fingerprint).

#### Core Architectural Guarantees

1. **Non-Linear Avalanche Effect (Differential Attack Resistance)**:
   Because HMAC-SHA256 is a cryptographically secure pseudorandom function (PRF), XORing pairs of constants (`valA ^ valB`) does **not** cancel the key or enum name. Decompilers cannot perform differential wordlist recovery.

2. **Per-Constant Independence**:
   Because each constant's value is derived independently, **adding, removing, or reordering other constants does NOT shift existing constants**.
   If you have `_UserRole { viewer, editor, admin }` and later insert `moderator` between `editor` and `admin`, the raw values for `viewer`, `editor`, and `admin` remain completely identical.

3. **Cross-Enum Isolation**:
   Even if two enums use the same seed, they will never share values because each enum's `publicName` is folded into every constant's HMAC input.

4. **Renaming Behavior**:
   If you rename an un-annotated constant (e.g. `editor` → `contentEditor`), its derived hash changes.

5. **Guaranteed Immutability with `@StealthValue`**:
   For database persistence, API protocols, or to make values rename-proof forever, use the `@StealthValue` annotation:

   ```dart
   @StealthEnum()
   enum _UserRole {
     @StealthValue(0x10000001)
     viewer,

     @StealthValue(0x10000002)
     editor,

     @StealthValue(0x10000003)
     admin,
   }
   ```

> [!IMPORTANT]
> **Upgrading from 2.0.x / 2.1.0:**
> Version 2.2.0 upgraded the hashing algorithm from linear FNV-1a to keyed HMAC-SHA256 to eliminate differential XOR recovery attacks. If your application persisted raw integer values from 2.0.x / 2.1.0 into databases or storage, annotate those constants with their existing hex values using `@StealthValue(0x...)` before regenerating. In 2.2.1, the HMAC derivation remains 100% backwards compatible with 2.2.0 with zero hash churn.

---

### Common patterns side-by-side

```dart
// ┌─────────────────────────────┬──────────────────────────────────────────────┐
// │  Standard Dart enum         │  stealth_enum                                │
// ├─────────────────────────────┼──────────────────────────────────────────────┤
// │  role == UserRole.admin     │  role == UserRole.admin          (same ✓)   │
// │  UserRole.values            │  UserRole.values                 (same ✓)   │
// │  role.index                 │  role.rawValue                   (int)       │
// │  role.name                  │  role.label  (needs generateLabel: true)     │
// │  UserRole.values.byName(s)  │  UserRole.byLabel(s)            (returns T?)│
// │  UserRole.values[i]         │  UserRole.tryFromRawValue(i)    (returns T?)│
// │  switch (role) { ... }      │  role.when(...)   or  role.maybeWhen(...)    │
// │  role.toJson()              │  role.toJson()   (always emitted, returns int)│
// │  UserRole.fromJson(i)       │  UserRole.fromJson(i)           (returns T?)│
// └─────────────────────────────┴──────────────────────────────────────────────┘
```

---

## Generated Output

Here is what `stealth_enum_generator` produces in `security_clearance.g.dart`:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_clearance.dart';

// **************************************************************************
// StealthEnumGenerator
// **************************************************************************

extension type const SecurityClearance._(int rawValue) {
  static const SecurityClearance guest = SecurityClearance._(0x5B7DA15D);
  static const SecurityClearance operator = SecurityClearance._(0x44EE678C);
  static const SecurityClearance admin = SecurityClearance._(0x18C38206);
  static const SecurityClearance superAdmin = SecurityClearance._(0x59EA165F);

  /// Creates a [SecurityClearance] instance from [rawValue] at runtime.
  const factory SecurityClearance.fromRawValue(int rawValue) =
      SecurityClearance._;

  /// Safely parses [rawValue] into a [SecurityClearance], returning `null` if unknown.
  static SecurityClearance? tryFromRawValue(int rawValue) {
    return switch (rawValue) {
      0x5B7DA15D => guest,
      0x44EE678C => operator,
      0x18C38206 => admin,
      0x59EA165F => superAdmin,
      _ => null,
    };
  }

  /// Returns `true` if this instance represents a valid, recognized constant.
  bool get isValid => tryFromRawValue(rawValue) != null;

  /// Serializes this [SecurityClearance] to its integer [rawValue].
  int toJson() => rawValue;

  /// Deserializes an integer [rawValue] into a [SecurityClearance], returning `null` on unknown value.
  static SecurityClearance? fromJson(int rawValue) => tryFromRawValue(rawValue);

  /// All recognized constants of [SecurityClearance].
  static const List<SecurityClearance> values = [
    guest,
    operator,
    admin,
    superAdmin,
  ];

  /// Exhaustive pattern matching across all variants.
  @pragma('vm:prefer-inline')
  R when<R>({
    required R Function() guest,
    required R Function() operator,
    required R Function() admin,
    required R Function() superAdmin,
  }) {
    return switch (rawValue) {
      0x5B7DA15D => guest(),
      0x44EE678C => operator(),
      0x18C38206 => admin(),
      0x59EA165F => superAdmin(),
      _ => throw StateError(''), // Fails closed without leaking strings
    };
  }

  /// Partial pattern matching with a required [orElse] fallback.
  @pragma('vm:prefer-inline')
  R maybeWhen<R>({
    R Function()? guest,
    R Function()? operator,
    R Function()? admin,
    R Function()? superAdmin,
    required R Function() orElse,
  }) {
    return switch (rawValue) {
      0x5B7DA15D when guest != null => guest(),
      0x44EE678C when operator != null => operator(),
      0x18C38206 when admin != null => admin(),
      0x59EA165F when superAdmin != null => superAdmin(),
      _ => orElse(),
    };
  }
}
```

With `generateLabel: true`, string label ergonomics are emitted into the extension type:

```dart
  // String labels appear in the compiled binary when generateLabel: true.
  String get label => switch (this) {
    guest => 'guest',
    operator => 'operator',
    admin => 'admin',
    superAdmin => 'superAdmin',
    _ => 'unknown',
  };

  static SecurityClearance? byLabel(String label) => switch (label) {
    'guest' => guest,
    'operator' => operator,
    'admin' => admin,
    'superAdmin' => superAdmin,
    _ => null,
  };
```
```

## Empirical AOT Verification Benchmark

The workspace includes an empirical verification script comparing standard Dart enums against `@StealthEnum`:

```bash
# 1. Desktop AOT verification (verifies Dart VM Object Pool string erasure with stripped symbols):
bash scripts/verify_aot_strings.sh

# 2. Real Flutter arm64 release APK verification with custom enum strings:
bash scripts/verify_aot_strings.sh --flutter /path/to/flutter_project "myRole,myTier,myFlag"

# 3. Comparing pre-migration control APK vs stealth APK:
CONTROL_APK="old_release.apk" bash scripts/verify_aot_strings.sh --flutter /path/to/flutter_project "myRole,myTier"
```

**How it proves string erasure:**
1. **Control Phase**: Compiles a standard Dart enum to AOT binary and scans it. Asserts that identifiers (`superAdmin`, `StandardClearance`) **ARE LEAKED** into the compiled binary.
2. **Stealth Phase**: Compiles the `@StealthEnum` extension type with observable runtime side-effects. Scans the binary and asserts that all enum identifiers are **100% ABSENT**.

Actual benchmark terminal output:
```
╔══════════════════════════════════════════════════════════════╗
║    stealth_enum — Empirical AOT String Removal Benchmark     ║
║       Side-by-Side Control (Standard Enum) vs @StealthEnum   ║
╚══════════════════════════════════════════════════════════════╝

[INFO]  Dart SDK     : 3.13.3
[INFO]  Workspace    : /path/to/stealth_enum_workspace
[INFO]  Build cache  : /path/to/stealth_enum_workspace/.aot_verify_build

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[PHASE 1/2] CONTROL TARGET: Compiling Standard Dart Enum to AOT...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[OK] Control binary compiled: 5.2M (symbols stripped to separate file)

Scanning control binary for standard enum strings...
  [CONFIRMED LEAK] Standard enum identifier 'superAdmin' FOUND in AOT binary
  [CONFIRMED LEAK] Standard enum identifier 'StandardClearance' FOUND in AOT binary
✓ Control verified: Standard Dart enums leak plain-text identifiers into compiled AOT binaries.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[PHASE 2/2] STEALTH TARGET: Compiling @StealthEnum to AOT...    
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Resolving dependencies & compiling stealth binary (with -S symbols stripped)...
[OK] Stealth binary compiled: 5.2M (symbols stripped to separate file)

Scanning stealth binary for private enum identifiers...
  [PASS] Sensitive string ABSENT from binary: 'superAdmin'
  [PASS] Sensitive string ABSENT from binary: 'trial'
  [PASS] Sensitive string ABSENT from binary: 'cancelled'
  [PASS] Sensitive string ABSENT from binary: '_SecurityClearance'
  [PASS] Sensitive string ABSENT from binary: '_SubscriptionStatus'

══════════════════════════════════════════════════════════════
BENCHMARK RESULTS SUMMARY:
  • Control Target (Standard Enum) : LEAKED identifier strings into AOT binary
  • Stealth Target (@StealthEnum)  : 0 LEAKS — all 5 identifiers erased
══════════════════════════════════════════════════════════════

✓ ALL EMPIRICAL AOT TESTS PASSED.
  @StealthEnum completely eliminates enum identifier metadata from AOT binaries.
```

This benchmark also runs automatically in **GitHub Actions CI on every commit and pull request**.

## API Reference

### `@StealthEnum`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `name` | `String?` | `null` | Custom name for the generated extension type. Defaults to stripping the leading `_` from the enum name. |
| `key` | `String?` | `null` | High-entropy secret key string for cryptographic HMAC-SHA256 derivation. Prevents dictionary/rainbow-table reversal of constant names from decompiled binaries. Can also be configured repository-wide in `build.yaml` or via `STEALTH_ENUM_KEY`. |
| `seed` | `int?` | `null` | Custom 32-bit integer seed for deterministic salt customization. Note: 32-bit seeds can be brute-forced; use `key` for cryptographic secrecy. |
| `generateWhen` | `bool` | `true` | When `true`, generates `.when()` and `.maybeWhen()` inlined pattern matching helpers. |
| `generateLabel` | `bool` | `false` | When `true`, generates `.label` and `byLabel()` helpers. **Emits string literals into the binary — read the security trade-off above.** |

### `@StealthValue`

| Parameter | Type | Description |
|---|---|---|
| `value` | `int` | Explicit raw integer value assigned to an individual enum constant. Immune to renames and constant reordering. |

### Generated Extension Type

| Member | Type | Description |
|---|---|---|
| `rawValue` | `int` | The underlying 32-bit obfuscated integer value. |
| `values` | `List<T>` | List of all enum variants in declaration order. |
| `fromRawValue(int)` | `const factory` | Creates an extension type instance from a raw integer value. |
| `tryFromRawValue(int)` | `static T?` | Safely parses a raw integer, returning `null` if unknown (zero crashes). |
| `isValid` | `bool` | Returns `true` if this instance holds a recognized enum variant. |
| `toJson()` | `int` | Serializes to raw integer for JSON/storage (0 string overhead). |
| `fromJson(int)` | `static T?` | Deserializes from a raw JSON integer (0 string overhead). |
| `when<T>(...)` | `T Function(...)` | Inlined exhaustive pattern matching covering all variants. Fails closed on unknown values. |
| `maybeWhen<T>(...)` | `T Function(...)` | Inlined non-exhaustive pattern matching with a required `orElse` fallback. |
| `label` | `String` | *(generateLabel: true)* Human-readable name of the variant. Equivalent to `.name` on a standard enum. |
| `byLabel(String)` | `static T?` | *(generateLabel: true)* Looks up a variant by its label string. Returns `null` if not found. |

## Under the Hood

- **Pure Extension Type:** Dart 3.3 introduced `extension type`, which compiles down directly to the underlying representation type (`int`). At runtime, it lives in a CPU register with zero heap allocation and zero pointer indirection.
- **Tree-Shaking:** Because the source enum `_SecurityClearance` is private to the file and never instantiated, the Dart AOT compiler completely removes the original enum declaration, its string names, and metadata from the compiled binary.
- **Decompiler Neutralization:** Conventional decompilers (Blutter, Ghidra) look for string tables and incremental switch jump tables (`0, 1, 2, ...`). With `stealth_enum`, they see isolated integer comparisons (`CMP W0, #0x7C06254C`) scattered across inlined call sites.
- **Fail-Closed Security (No String Leaks):** All cases in `.when()` match explicit hex values, and the wildcard branch `_ => throw StateError('')` fails closed on unknown or corrupted values without leaking any string literals into the binary.
- **Cryptographic Keyed HMAC-SHA256 Hashing:** Values are derived using HMAC-SHA256 over `'$publicName::$fieldName'` with an optional secret key, seed, or default salt. Because HMAC-SHA256 is a cryptographically secure pseudorandom function (PRF) with full avalanche effect, XOR differential attacks cannot recover names or cancel the key. Each constant is calculated independently, guaranteeing that adding, removing, or reordering variants never shifts untouched constants' values. Exact numbers can also be frozen with `@StealthValue`.

## Running the example

```bash
cd example
dart pub get
dart run build_runner build
dart run lib/stealth_enum_example.dart
```

## Contributing

PRs and issues are welcome! Please open an issue first for significant changes.


## License

Made with 💛 by [aslamambiloly](https://github.com/aslamambiloly) © 2026
