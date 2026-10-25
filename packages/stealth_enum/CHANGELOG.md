## 0.1.0

* Initial release.
* `@StealthEnum` annotation with `seed`, `generateWhen`, and `name` parameters.
* Dart 3.3+ `extension type` output backed by deterministic, collision-free 32-bit hex integers.
* Inlined exhaustive `.when()` and `.maybeWhen()` helpers with `@pragma('vm:prefer-inline')`.
* No `StateError` strings in the binary — final `when` branch uses wildcard `_ =>`.
* Compatible with `SharedPartBuilder` alongside `json_serializable`, `freezed`, and `riverpod_generator`.
