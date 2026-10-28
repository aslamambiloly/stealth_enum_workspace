## 2.2.5

### Security & Hardening
* **Placeholder Key Rejection**: The generator now rejects documented public placeholder keys (e.g., `'your-project-secret-salt-here-or-env'` and `'YOUR_HIGH_ENTROPY_BUILD_SECRET'`) with an `InvalidGenerationSourceError` at compile time, preventing accidental public key usage.
* **`require_key` Minimum Length Enforcement**: When `require_key: true` or `STEALTH_ENUM_REQUIRE_KEY="1"` is active, keys shorter than 24 characters throw an `InvalidGenerationSourceError` instead of only issuing a warning.
* **AOT Verification Ambiguity Detection**: Updated `scripts/verify_aot_strings.sh` to cross-reference strings in both Control and Stealth binaries; common words appearing in both builds (such as runtime or stdlib identifiers) are marked as `[AMBIGUOUS]` alongside recommendations to use canary names.
* **Real `build.yaml` Builder Parsing Test**: Added a unit test validating builder options parsing directly from real `build.yaml` syntax.
* **Zero Constant Churn**: 100% constant value backwards compatible with 2.2.0, 2.2.1, 2.2.2, 2.2.3, and 2.2.4. Note: If your CI audits generated code comments via recorded fingerprint baselines, update your recorded baseline with `grep -rh "Key fingerprint" lib | sort -u`.

## 2.2.4

### Security & Hardening
* **Short Key Warning**: Added compile-time warning when a secret key is under 24 characters, recommending `python3 -c "import secrets;print(secrets.token_urlsafe(24))"` to prevent weak keys vulnerable to offline dictionary confirmation.
* **Domain-Separated Key Fingerprinting**: Key fingerprints are now derived with domain separation (`HMAC-SHA256(key, 'stealth_enum:fingerprint:v1')`) to prevent cross-protocol table reuse.
* **Strict Control APK Enforcement**: Updated empirical verification script (`scripts/verify_aot_strings.sh`) in `--flutter` mode to require `CONTROL_APK` with confirmed baseline string leaks, exiting with `UNVERIFIED` otherwise.
* **Smart Warning Handling for `@StealthValue`**: Enums where every constant has explicit `@StealthValue` now skip default-salt warnings, key fingerprints, and `require_key` checks (as no key is needed).
* **Seed Warning**: Added compile-time warning for seed-only enums advising that 32-bit seeds have low entropy (~1.7h search space) compared to secret keys.
* **Zero hash churn**: 100% byte-for-byte backwards compatible with 2.2.0, 2.2.1, 2.2.2, and 2.2.3.

## 2.2.3

### Maintenance & Compatibility
* Requires `stealth_enum: ">=2.2.3 <3.0.0"` with tightened lower bounds on `meta` (`>=1.14.0`).
* Added tests for empty enum validation and seed parameter generation, boosting test suite to 23 comprehensive tests.
* Formatted source code to standard Dart formatting conventions.
* Fixed dartdoc symbol references for `StealthEnum.key` and `StealthEnum.seed`.
* Zero hash churn: 100% byte-for-byte backwards compatible with 2.2.0, 2.2.1, and 2.2.2.

## 2.2.2

### Hardening & Key Management
* Added `require_key` support in `build.yaml` (`options.config['require_key']: true`) and `STEALTH_ENUM_REQUIRE_KEY="1"` CI environment variable to fail the build if any enum lacks a secret key or if the key is empty, preventing accidental silent fallback to the public default salt.
* Safe type coercion for YAML builder config (`options.config['key']?.toString()`), supporting numeric/integer keys without type cast exceptions.
* Added compile-time warning when an enum falls back to the public default salt.
* Emits a non-reversible 8-character SHA-256 key fingerprint comment (`// Key fingerprint: <hash>`) in generated files when a secret key is configured.
* Rigorous unit tests asserting exact HMAC-SHA256 mathematical derivation, key fingerprinting, numeric keys, precedence rules, and `require_key` enforcement.
* Requires `stealth_enum: ">=2.2.2 <3.0.0"`.
* Zero hash churn: 100% byte-for-byte backwards compatible with 2.2.0 and 2.2.1.

## 2.2.1

### Improvements & Hardening
* Added support for project-wide secret keys via `build.yaml` (`options.config['key']`) and `STEALTH_ENUM_KEY` CI environment variable.
* Added `'fromRawValue'` to `_reservedNames` validation set to prevent constructor collisions when defining enum constants.
* Hardened empirical AOT verification script (`scripts/verify_aot_strings.sh`) with `-S <symbols>` to strip debug symbols on Dart AOT compiles and added real Flutter arm64 APK inspection support.
* Comprehensive unit tests covering `defaultKey` options and `fromRawValue` collision validation.
* Requires `stealth_enum: ">=2.2.1 <3.0.0"`.
* **Zero hash churn**: preserves exact 2.2.0 HMAC-SHA256 derivation for existing constants.

## 2.2.0

### Security & Hardening
* Hashing upgraded from linear FNV-1a to **keyed HMAC-SHA256**: eliminates XOR differential attacks (`valA ^ valB` no longer cancels the key or enum name).
* Added support for `key: String?` parameter in `@StealthEnum(key: '...')`.
* Enforced private enum declarations: generates a descriptive `InvalidGenerationSourceError` if `@StealthEnum` is placed on a public enum without a leading underscore (`_`).
* Added keyword reservation check: throws a compile-time error if an enum constant collides with a generated extension type member (`when`, `orElse`, `isValid`, etc.).
* Added strict range validation to `@StealthValue`: throws a compile-time error on negative integers or values below `0x1000`.
* 15 comprehensive unit tests verifying code emission and non-vacuous validation error logging.

## 2.1.0

### New Features & Improvements
* Deterministic 32-bit FNV-1a hashing: Replaced Dart runtime `hashCode` with 32-bit FNV-1a hashing over `(seed ?? 0xDEADBEEF) ^ fnv1a(publicName) ^ fnv1a(fieldName)`. Provides independent per-constant hash values: inserting, reordering, or removing constants leaves other values untouched.
* Added `@StealthValue(int)` support: Enum constants annotated with `@StealthValue(value)` use the exact specified 32-bit hex/int value, allowing frozen values for database and external API stability.
* Decoupled `toJson()` and `fromJson(int)`: Integer-based serialization helpers are now generated by default on all extension types with zero string overhead.
* `generateLabel: true` now exclusively generates `.label` and `byLabel()` string helpers.
* 10 comprehensive unit tests using `build_test` testing actual generated code across all options, FNV-1a stability, `@StealthValue`, and error handling.

## 2.0.1

* Updated `README.md`, example code, and package-level `llms.txt` to accurately reference `stealth_enum: ^2.0.0` and `stealth_enum_generator: ^2.0.0`.
* Synchronized documentation and examples across the package.

## 2.0.0

* Added `generateLabel` code path in `StealthEnumGenerator`. When `@StealthEnum(generateLabel: true)`, the generator emits `.label` getter, `byLabel(String)`, `toJson()`, and `fromJson(int)` helpers alongside the existing int-backed extension type.
* Added inline security comment block in generated label section explaining the string-in-binary trade-off.
* Requires `stealth_enum: ^2.0.0`.

## 1.0.5


* Added `tryFromRawValue()` generation for safe, null-returning integer parsing.
* Added `isValid` boolean getter generation for variant validation.
* 100% test coverage maintained.

## 1.0.4

* Security hardening: `.when()` now generates explicit hex conditions for every enum constant.
* Wildcard branch `_ => throw StateError('')` fails closed on unknown or corrupted integers without leaking strings.
* 100% test coverage maintained.

## 1.0.3

* Added `fromRawValue` factory constructor to generated extension types for zero-cost runtime deserialization.
* Added unit test suite for generator and builder.
* Achieved 100% test coverage.
* Updated CI/CD workflow actions.

## 1.0.1

* Improved README formatting and documentation.
* Updated badges.

## 1.0.0

* Production ready 1.0.0 release.
* Updated dependency to support `stealth_enum` ^1.0.0.

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
