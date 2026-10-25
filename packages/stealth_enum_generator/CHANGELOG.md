## 0.1.1

* Added package example in `example/example.dart`.
* Added dartdoc comment for `StealthEnumGenerator` constructor.
* Fixed unresolved doc reference `build.yaml` in `builder.dart`.
* Refined package description to adhere to pub.dev length guidelines.
* Broadened analyzer compatibility for `EnumElement` constants across versions.

## 0.1.0

* Initial release.
* `StealthEnumGenerator` using `source_gen 4.x` and `analyzer 14.x`.
* Deterministic collision-free 32-bit value generation (seeded from `enumName ^ fieldName ^ 0xDEADBEEF`).
* `SharedPartBuilder` integration for `.g.dart` sharing.
* Security-first code emission: wildcard final branch, `@pragma('vm:prefer-inline')`.
