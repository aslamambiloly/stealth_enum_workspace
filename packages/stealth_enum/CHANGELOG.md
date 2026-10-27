## 2.0.1

* Updated package-level `llms.txt` with complete 2.0.x feature documentation, migration guide, JSON serialization patterns, and safe parsing guarantees.
* Synchronized documentation and examples across the package.

## 2.0.0

### New Features
* Added `generateLabel` annotation parameter (default `false`). When enabled, the generator emits `.label` getter, `byLabel(String)`, `toJson()`, and `fromJson(int)` helpers — equivalent to `.name`, `byName()`, and JSON converters on standard enums.
* Added comprehensive **Migration Guide** in README covering pattern matching, JSON serialization (including `json_serializable` custom converter pattern), logging, persistence, and side-by-side standard enum → stealth_enum cheatsheet.
* Added **AOT Verification Script** (`scripts/verify_aot_strings.sh`) that compiles the example to a native AOT binary and asserts all enum identifier strings are absent using the `strings` CLI tool.
* Updated feature table to include Safe Parsing row comparing `tryFromRawValue` vs `byName` (which throws on unknown values).

### Breaking Changes
* Generator version constraint updated: `stealth_enum_generator: ^2.0.0` requires `stealth_enum: ^2.0.0`. Update both packages together.

## 1.0.5


* Added `tryFromRawValue()` for safe, null-returning parsing of untrusted inputs (APIs, JSON, databases) to prevent runtime crashes.
* Added `isValid` boolean getter to verify if an instance holds a recognized enum variant.
* Documented compile-time and runtime safety guarantees in README and llms.txt.

## 1.0.4

* Hardened generated pattern matching: all cases are now explicit and wildcard branches fail closed.
* Updated documentation and examples.

## 1.0.3

* Added unit test suite for `StealthEnum` annotation.
* Enhanced example and documentation.
* Updated CI/CD workflow actions.

## 1.0.1

* Improved README formatting and line breaks in documentation.
* Updated badges and preview graphics.

## 1.0.0

* Production ready 1.0.0 release.
* Zero runtime overhead and complete enum metadata erasure in Flutter AOT binaries.
* Full compatibility with Dart 3.3+ and Flutter 3.19+.

## 0.1.1

* Added package example in `example/example.dart`.
* Added dartdoc comments for `StealthEnum` constructor.
* Refined package description to adhere to pub.dev length guidelines.

## 0.1.0

* Initial release.
* `@StealthEnum` annotation with `seed`, `generateWhen`, and `name` parameters.
* Dart 3.3+ `extension type` output backed by deterministic, collision-free 32-bit hex integers.
* Inlined exhaustive `.when()` and `.maybeWhen()` helpers with `@pragma('vm:prefer-inline')`.
* No `StateError` strings in the binary — final `when` branch uses wildcard `_ =>`.
* Compatible with `SharedPartBuilder` alongside `json_serializable`, `freezed`, and `riverpod_generator`.
