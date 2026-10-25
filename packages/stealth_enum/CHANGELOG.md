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
