# stealth_enum

**Eliminate Dart enum metadata from Flutter AOT binaries.** Defeat AI-driven
reverse-engineering pipelines (REA · Blutter · Ghidra) that anchor on
plain-text enum tables in `libapp.so`.

[![pub.dev](https://img.shields.io/pub/v/stealth_enum.svg)](https://pub.dev/packages/stealth_enum)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Dart 3](https://img.shields.io/badge/Dart-3.3%2B-blue.svg)](https://dart.dev)

---

## The Problem

When you build a Flutter app with `--obfuscate --split-debug-info`, Dart strips
class and function symbols — but **enum identifier strings are intentionally
preserved** in the Dart Object Pool (`pp.txt` in Blutter) to support `.name`
and `.toString()`.

Tools like [REA (Reverse Engineer Anything)](https://github.com/REA-project/rea)
use these plain-text enum tables as **anchors**: they locate the string in
Ghidra, trace cross-references to the obfuscated ARM64 function, and use an LLM
to reconstruct your exact business logic from the assembly — even with full
obfuscation enabled.

```
// What Blutter sees in pp.txt (before stealth_enum):
"SubscriptionStatus"  "trial"  "active"  "expired"  "cancelled"
```

**Standard enums also compile to sequential indices** `0, 1, 2, 3` — trivially
recognised as enum jump tables by any decompiler.

---

## The Solution

`stealth_enum` + `stealth_enum_generator` transforms annotated private enums
into **zero-cost Dart 3 `extension types`** backed by **randomised 32-bit hex
integers**.

| Property | Standard `enum` | `stealth_enum` |
|---|---|---|
| Strings in binary | ✅ Plain-text in Object Pool | ❌ None |
| Index pattern | ✅ Sequential `0,1,2,3` | ❌ Random hex (`0x4B91E20A`) |
| Runtime cost | Wrapper object | Zero (raw `int`) |
| Exhaustive matching | Native `switch` | Inlined `.when()` |
| Tree-shaken | No | Yes (private source enum) |

```
// What Ghidra sees (after stealth_enum):
CMP W0, #0x4B91E20A   // Could be anything — math constant? address?
CMP W0, #0x7C104F8B
CMP W0, #0x1D55A9C3
```

---

## Installation

```yaml
# pubspec.yaml
dependencies:
  stealth_enum: ^0.1.0

dev_dependencies:
  stealth_enum_generator: ^0.1.0
  build_runner: ^2.4.0
```

---

## Usage

### 1. Annotate a private enum

```dart
// user_flow.dart
import 'package:stealth_enum/stealth_enum.dart';

part 'user_flow.g.dart';

@StealthEnum()
enum _UserFlow {
  onboarding,
  freeTier,
  proMember,
  banned,
}
```

### 2. Run build_runner

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Use the generated extension type

```dart
import 'user_flow.dart'; // pulls in user_flow.g.dart via `part`

void handleFlow(UserFlow flow) {
  final label = flow.when(
    onboarding: () => 'Welcome!',
    freeTier: () => 'Upgrade to Pro',
    proMember: () => 'Enjoy full access',
    banned: () => 'Account restricted',
  );
  print(label);
}

void main() {
  handleFlow(UserFlow.proMember); // → 'Enjoy full access'

  // Extension types erase to int at runtime:
  assert(UserFlow.proMember as Object is int); // true ✓

  // Partial matching:
  final badge = UserFlow.freeTier.maybeWhen(
    proMember: () => '⭐ Pro',
    orElse: () => '🔓 Free',
  );
  print(badge); // → '🔓 Free'
}
```

---

## Generated output

```dart
// user_flow.g.dart — GENERATED CODE - DO NOT MODIFY BY HAND
extension type const UserFlow._(int rawValue) {
  static const UserFlow onboarding = UserFlow._(0x4B91E20A);
  static const UserFlow freeTier   = UserFlow._(0x7C104F8B);
  static const UserFlow proMember  = UserFlow._(0x1D55A9C3);
  static const UserFlow banned     = UserFlow._(0x6E82B119);

  static const List<UserFlow> values = [ onboarding, freeTier, proMember, banned ];

  @pragma('vm:prefer-inline')
  T when<T>({
    required T Function() onboarding,
    required T Function() freeTier,
    required T Function() proMember,
    required T Function() banned,
  }) {
    return switch (rawValue) {
      0x4B91E20A => onboarding(),
      0x7C104F8B => freeTier(),
      0x1D55A9C3 => proMember(),
      _          => banned(), // ← wildcard, no StateError string in binary
    };
  }

  @pragma('vm:prefer-inline')
  T maybeWhen<T>({ ... required T Function() orElse }) { ... }
}
```

---

## Annotation parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `seed` | `int?` | `null` | Fixed seed for deterministic generation (CI-friendly). |
| `generateWhen` | `bool` | `true` | Emit `.when()` / `.maybeWhen()` helpers. |
| `name` | `String?` | `null` | Override the generated type name (default: strip leading `_`). |

### Deterministic CI builds

```dart
@StealthEnum(seed: 42)
enum _SubscriptionStatus { trial, active, expired, cancelled }
```

With a fixed seed, `build_runner` always produces the **same hex constants**,
preventing noisy Git diffs while still appearing completely random in the binary.

---

## Security notes

- **No `StateError` strings:** The final `when` branch uses `_ => lastCase()`
  instead of `throw StateError(...)` — keeping the binary 100% string-free.
- **`@pragma('vm:prefer-inline')`:** Forces Dart AOT to inline `.when()` and
  `.maybeWhen()` at every call site. The helper methods themselves are stripped
  from the binary.
- **Private source enum → guaranteed tree-shaking:** Because `_MyEnum` is
  private and the generator uses it only as a type annotation, the AOT
  tree-shaker deletes the source enum and its entire string table from
  `libapp.so`.

---

## Compatibility

- Dart SDK `>=3.3.0` (required for `extension type`)
- `build_runner >=2.4.0`
- Compatible with `json_serializable`, `freezed`, `riverpod_generator` — all
  share the same `.g.dart` file via `SharedPartBuilder`.

---

## License

MIT © stealth_enum contributors
