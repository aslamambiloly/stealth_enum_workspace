
<p align="center">
  <a href="https://pub.dev/packages/stealth_enum"><img src="https://img.shields.io/pub/v/stealth_enum.svg" alt="pub version"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.3%2B-blue?logo=dart" alt="Dart"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.19%2B-blue?logo=flutter" alt="Flutter"></a>
</p>

<p align="center">
  <a href="https://ko-fi.com/N7K021PF59"><img src="https://raw.githubusercontent.com/aslamambiloly/curved_navigation_bar_pro/main/doc/coffee.png" alt="Support me on Ko-fi" width="400"></a>
</p>

A Zero Overhead Dart & Flutter code generator that hides enum metadata, randomizes enum values, and makes AOT binaries harder to reverse engineer (REA, Blutter, Ghidra etc.).

## The `Catch` : |
You maybe already doing:

✅ --obfuscate --split-debug-info=.
✅ SSL Certificate Pinning.
✅ App Attest & App Integrity.
✅ [freeRasp](https://pub.dev/packages/freerasp).
✅ [envied](https://pub.dev/packages/envied).

Do you feel like you are protected? Yes, but there's a small catch when it comes to reverse engineering. 

❌ **Dart enums still expose their names intentionally in compiled AOT binaries**.

## Why `stealth_enum`?
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

<p align="center">
  <img src="https://raw.githubusercontent.com/aslamambiloly/stealth_enum_workspace/main/doc/difference.png" width="550" alt="Code difference"/>
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
- [Generated Output](#generated-output)
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

<div align="center">

| Feature | Standard Dart `enum` | `@StealthEnum` |
|:---:|:---:|:---:|
| **Strings in Binary** | Plain-text in Object Pool (`pp.txt`) | **Zero** strings (completely absent) |
| **Index Pattern** | Sequential `0, 1, 2, 3` (jump tables) | Non-sequential 32-bit hex (`0x4B91E20A`) |
| **Runtime Cost** | Wrapper object allocation | **Zero** (erases to raw primitive `int`) |
| **Exhaustive Matching** | Native `switch` statement | Inlined `.when()` / `.maybeWhen()` |
| **Decompiler Visibility** | Anchors for REA & Ghidra | Indistinguishable from random constants |
| **Tree-Shaking** | Kept in binary | **100% tree-shaken** (private source enum) |

</div>

- **Zero Binary String Footprint**: Completely removes enum and constant names from compiled AOT binaries.
- **Non-Sequential Entropy**: Replaces predictable sequential indices with high-entropy 32-bit hex values.
- **Zero Runtime Overhead**: Built on Dart 3.3+ `extension type const` over primitive `int` with zero heap allocation and zero boxing.
- **Inlined Pattern Matching**: `@pragma('vm:prefer-inline')` on `.when()` and `.maybeWhen()` inlines branches directly into call sites.
- **No `StateError` String Leaks**: The fallback branch in `.when()` uses a wildcard `_ =>` rather than throwing an exception with class names.
- **Guaranteed Tree-Shaking**: The private annotated enum (`_MyEnum`) is discarded by the compiler; only the lightweight extension type remains.
- **Deterministic CI Builds**: Optional compile-time `seed` parameter guarantees reproducible builds across team members and CI pipelines.
- **Pure Dart**: Zero native code, zero CocoaPods or Gradle headaches.

## Getting started

Add `stealth_enum` to your `pubspec.yaml`:

```yaml
dependencies:
  stealth_enum: ^0.1.1

dev_dependencies:
  build_runner: ^2.4.0
  stealth_enum_generator: ^0.1.1
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

### Custom seed for deterministic builds

By default, `stealth_enum` computes deterministic values based on symbol names and internal hashing. If you want a fixed seed across all environments or custom entropy:

```dart
@StealthEnum(seed: 0xCAFEBABE)
enum _SubscriptionTier {
  free,
  pro,
  enterprise,
}
```

### Custom type name

By default, the public extension type name strips the leading `_` from your private enum (`_SecurityClearance` → `SecurityClearance`). You can customize this with `name`:

```dart
@StealthEnum(name: 'AppRole')
enum _RoleInternal {
  user,
  admin,
}
```

## Generated Output

Here is what `stealth_enum_generator` produces in `security_clearance.g.dart`:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_clearance.dart';

// **************************************************************************
// StealthEnumGenerator
// **************************************************************************

extension type const SecurityClearance._(int rawValue) {
  static const SecurityClearance guest = SecurityClearance._(0x373D1B37);
  static const SecurityClearance operator = SecurityClearance._(0x764AE932);
  static const SecurityClearance admin = SecurityClearance._(0x7C06254C);
  static const SecurityClearance superAdmin = SecurityClearance._(0x3154C03F);

  static const List<SecurityClearance> values = <SecurityClearance>[
    guest,
    operator,
    admin,
    superAdmin,
  ];

  @pragma('vm:prefer-inline')
  T when<T>({
    required T Function() guest,
    required T Function() operator,
    required T Function() admin,
    required T Function() superAdmin,
  }) {
    return switch (rawValue) {
      0x373D1B37 => guest(),
      0x764AE932 => operator(),
      0x7C06254C => admin(),
      _ => superAdmin(), // Wildcard branch prevents leaking StateError strings
    };
  }

  @pragma('vm:prefer-inline')
  T maybeWhen<T>({
    T Function()? guest,
    T Function()? operator,
    T Function()? admin,
    T Function()? superAdmin,
    required T Function() orElse,
  }) {
    return switch (rawValue) {
      0x373D1B37 => guest != null ? guest() : orElse(),
      0x764AE932 => operator != null ? operator() : orElse(),
      0x7C06254C => admin != null ? admin() : orElse(),
      0x3154C03F => superAdmin != null ? superAdmin() : orElse(),
      _ => orElse(),
    };
  }
}
```

## API Reference

### `@StealthEnum`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `name` | `String?` | `null` | Custom name for the generated extension type. Defaults to stripping the leading `_` from the enum name. |
| `seed` | `int?` | `null` | Custom 32-bit integer seed for deterministic value generation across builds. |
| `generateWhen` | `bool` | `true` | When `true`, generates `.when()` and `.maybeWhen()` pattern matching helpers. |

### Generated Extension Type

| Member | Type | Description |
|---|---|---|
| `rawValue` | `int` | The underlying 32-bit obfuscated integer value. |
| `values` | `List<T>` | List of all enum variants in declaration order. |
| `when<T>(...)` | `T Function(...)` | Inlined exhaustive pattern matching covering all variants. |
| `maybeWhen<T>(...)` | `T Function(...)` | Inlined non-exhaustive pattern matching with a required `orElse` fallback. |

## Under the Hood

- **Pure Extension Type:** Dart 3.3 introduced `extension type`, which compiles down directly to the underlying representation type (`int`). At runtime, it lives in a CPU register with zero heap allocation and zero pointer indirection.
- **Tree-Shaking:** Because the source enum `_SecurityClearance` is private to the file and never instantiated, the Dart AOT compiler completely removes the original enum declaration, its string names, and metadata from the compiled binary.
- **Decompiler Neutralization:** Conventional decompilers (Blutter, Ghidra) look for string tables and incremental switch jump tables (`0, 1, 2, ...`). With `stealth_enum`, they see isolated integer comparisons (`CMP W0, #0x7C06254C`) scattered across inlined call sites.
- **Wildcard Fallback (No String Leaks):** Standard Dart switch statements may generate exception stubs referencing unhandled cases. `stealth_enum` maps the final case of `.when()` to a wildcard `_ =>`, eliminating any runtime error string.

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
