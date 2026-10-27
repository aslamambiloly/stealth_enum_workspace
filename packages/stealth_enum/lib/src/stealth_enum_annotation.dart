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
  /// Optional fixed seed for customizing the deterministic integer generation.
  ///
  /// The generator uses a 32-bit FNV-1a hash combining the enum name, constant name,
  /// and this [seed] (or `0xDEADBEEF` if omitted). Because values are derived
  /// independently per constant, adding, removing, or reordering other constants
  /// does not shift the values of existing constants.
  ///
  /// For exact, frozen raw integer values that must never change even across
  /// renames, use the [@StealthValue] annotation on individual constants.
  final int? seed;

  /// Whether to generate `.when()` and `.maybeWhen()` exhaustive helper
  /// methods. Defaults to `true`.
  ///
  /// Set to `false` if you want the raw extension type without helpers
  /// (e.g. when using Dart 3 switch expressions directly).
  final bool generateWhen;

  /// Optional override for the generated public type name.
  ///
  /// By default the generator strips the leading `_` from the source enum
  /// name. If the source enum is not private (e.g. `enum MyEnum`) the
  /// generator appends `Stealth` to produce `MyEnumStealth`. Use this
  /// parameter to specify an explicit name instead.
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
  /// Specify [seed] for deterministic integer generation, [generateWhen] to
  /// enable or disable `.when()` / `.maybeWhen()` helper generation, [name]
  /// to override the generated public extension type name, or [generateLabel]
  /// to enable display name and label lookup helpers.
  const StealthEnum({
    this.seed,
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
/// collision-free 32-bit hex value using a deterministic FNV-1a hash of the
/// enum and field names.
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
  final int value;

  /// Creates a [StealthValue] annotation with an explicit [value].
  const StealthValue(this.value);
}
