
<p align="center">
  <a href="https://pub.dev/packages/stealth_enum_generator"><img src="https://img.shields.io/pub/v/stealth_enum_generator.svg" alt="pub version"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.3%2B-blue?logo=dart" alt="Dart"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.19%2B-blue?logo=flutter" alt="Flutter"></a>
  <br>
  <a href="https://codecov.io/gh/aslamambiloly/stealth_enum_workspace"><img src="https://codecov.io/gh/aslamambiloly/stealth_enum_workspace/graph/badge.svg" alt="codecov"></a>
  <!-- <a href="https://app.codacy.com/gh/aslamambiloly/stealth_enum_workspace/dashboard"><img src="https://app.codacy.com/project/badge/Grade/stealth_enum_workspace" alt="Codacy Badge"></a> -->
</p>

<p align="center">
  <a href="https://ko-fi.com/N7K021PF59"><img src="https://raw.githubusercontent.com/aslamambiloly/curved_navigation_bar_pro/main/doc/coffee.png" alt="Support me on Ko-fi" width="400"></a>
</p>

The companion `build_runner` code generator for [`stealth_enum`](https://pub.dev/packages/stealth_enum).

This package transforms `@StealthEnum()` annotated private Dart enums into zero-cost, obfuscated Dart 3 extension types to neutralize AI-driven reverse engineering pipelines (REA, Blutter, Ghidra).

## Getting started

Add `stealth_enum_generator` to your `dev_dependencies` alongside `build_runner`, and `stealth_enum` to your `dependencies`:

```yaml
dependencies:
  stealth_enum: ^1.0.0

dev_dependencies:
  build_runner: ^2.4.0
  stealth_enum_generator: ^1.0.0
```

Then run:

```bash
dart pub get
# or for Flutter:
flutter pub get
```

## How it works

`StealthEnumGenerator` extends `GeneratorForAnnotation<StealthEnum>` from `source_gen`:

1. **Validation**: Inspects `@StealthEnum()` annotations and ensures they are applied to private `EnumElement` declarations.
2. **Identifier Extraction**: Resolves the public type name (strips the leading `_` or applies the custom `name:` override).
3. **Entropy & Value Generation**: Computes collision-free, deterministic 32-bit hex values for each constant using a seeded random distribution.
4. **Extension Type Synthesis**: Emits an `extension type const <Name>._(int rawValue)` with static constants, `values` list, safe `tryFromRawValue()` parsing, `isValid` validation, and inlined pattern matching.
5. **Fail-Closed Security**: Emits explicit hex cases and fail-closed wildcards (`_ => throw StateError('')`) to guarantee that corrupted or unknown values never execute a privileged branch without leaking strings.
6. **Shared Pipeline Integration**: Built with `SharedPartBuilder` so it seamlessly shares `.g.dart` files with `json_serializable`, `freezed`, and other generators.

For full documentation and examples, see the [stealth_enum README](https://pub.dev/packages/stealth_enum).

## Contributing

PRs and issues are welcome! Please open an issue first for significant changes.


## License

Made with 💛 by [aslamambiloly](https://github.com/aslamambiloly) © 2026
