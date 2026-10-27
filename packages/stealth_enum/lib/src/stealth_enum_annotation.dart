import 'package:meta/meta_meta.dart';

/// Annotates a **private** Dart `enum` (e.g. `enum _MyEnum { ... }`) to trigger
/// code generation of a public, zero-cost Dart 3 `extension type` backed by
/// cryptographically randomized 32-bit integers.
///
/// ### Why private?
/// A private enum (leading `_`) is never referenced at runtime by your
/// application code. The Dart AOT tree-shaker therefore **completely removes**
/// the original `_MyEnum` and its plain-text string table from `libapp.so`.
/// The generated `extension type` compiles directly to raw `int` comparisons —
/// no class, no strings, no metadata in the binary.
///
/// ### Example
/// ```dart
/// import 'package:stealth_enum/stealth_enum.dart';
///
/// part 'user_flow.g.dart';
///
/// @StealthEnum()
/// enum _UserFlow { onboarding, freeTier, proMember, banned }
/// ```
///
/// After running `dart run build_runner build`, the file `user_flow.g.dart`
/// will contain a `UserFlow` extension type with randomized hex constants and
/// inlined `.when()` / `.maybeWhen()` exhaustive helpers.
@Target({TargetKind.enumType})
final class StealthEnum {
  /// Optional fixed integer seed for reproducible builds.
  ///
  /// **Security Note**: A 32-bit integer seed has a limited key space that can be
  /// brute-forced against common dictionary words. For security-sensitive enums
  /// (licensing, paywalls, admin gates), use [key] with a high-entropy secret string
  /// instead of [seed].
  final int? seed;

  /// Secret key string for HMAC-SHA256 derivation.
  ///
  /// Recommended for all security-sensitive enums. When provided, constants
  /// are derived using HMAC-SHA256 keyed with this secret string over
  /// `'$publicName::$fieldName'`.
  ///
  /// Because HMAC-SHA256 satisfies the strict avalanche criterion, knowledge
  /// of raw constants does NOT leak enum or constant names, and differential
  /// attacks (such as XORing pairs of constants) cannot cancel out the key.
  ///
  /// Can also be configured globally in `build.yaml` or via the `STEALTH_ENUM_KEY`
  /// environment variable to avoid committing secrets into source control.
  final String? key;

  /// Whether to generate `.when()` and `.maybeWhen()` exhaustive helper
  /// methods. Defaults to `true`.
  ///
  /// Set to `false` if you want the raw extension type without helpers
  /// (e.g. when using Dart 3 switch expressions directly).
  final bool generateWhen;

  /// Optional override for the generated public type name.
  ///
  /// By default the generator strips the leading `_` from the source enum
  /// name. Use this parameter to specify an explicit name instead.
  final String? name;

  /// Whether to generate label-based ergonomic helpers: `.label` and `byLabel()`.
  /// Defaults to `false`.
  ///
  /// **Security trade-off**: Enabling this emits human-readable label strings
  /// (e.g. `'admin'`, `'superAdmin'`) into the generated `.g.dart` file, which
  /// **will appear in the compiled binary**. The private source enum's strings
  /// are still fully erased, but the generated labels re-introduce readable
  /// identifiers. Only enable this when you genuinely need display names or
  /// logging and you understand the trade-off.
  ///
  /// Note: [toJson] and [fromJson] are always generated on all extension types
  /// because they operate exclusively on raw integers with zero string overhead.
  ///
  /// When enabled, the generated type gains:
  /// - `.label` → `String` name of the current variant (e.g. `'admin'`).
  /// - `byLabel(String)` → `T?` Looks up a variant by its label string.
  final bool generateLabel;

  /// Creates a [StealthEnum] annotation.
  ///
  /// Specify [seed] or [key] for keyed cryptographic integer generation, [generateWhen]
  /// to enable or disable `.when()` / `.maybeWhen()` helper generation, [name]
  /// to override the generated public extension type name, or [generateLabel]
  /// to enable display name and label lookup helpers.
  const StealthEnum({
    this.seed,
    this.key,
    this.generateWhen = true,
    this.name,
    this.generateLabel = false,
  });
}

/// Optional annotation on an enum constant to explicitly specify its [rawValue].
///
/// Use this when you require an immutable, exact integer value across renames,
/// or to match existing database records / backend protocol values.
///
/// If this annotation is omitted, the generator automatically derives a
/// collision-free 32-bit hex value using keyed HMAC-SHA256 of the enum and
/// field names.
///
/// The [value] must be a positive 32-bit unsigned integer (`0x0` to `0xFFFFFFFF`).
/// To maintain reverse-engineering resistance, use high-entropy constants
/// (`>= 0x10000`) rather than small sequential numbers (e.g. `1, 2, 3`) to
/// prevent decompilers from identifying sequential jump tables.
///
/// ### Example
/// ```dart
/// @StealthEnum()
/// enum _UserRole {
///   @StealthValue(0x10000001)
///   guest,
///   @StealthValue(0x7F000002)
///   admin,
/// }
/// ```
@Target({TargetKind.enumValue})
final class StealthValue {
  /// The explicit raw integer value to assign to this enum constant.
  /// Must be an unsigned 32-bit integer in the range [0x0 .. 0xFFFFFFFF].
  final int value;

  /// Creates a [StealthValue] annotation with an explicit [value].
  const StealthValue(this.value);
}
