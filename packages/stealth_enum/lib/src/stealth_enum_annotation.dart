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
  /// Optional fixed seed for **deterministic** code generation.
  ///
  /// When non-null the generator uses `Random(seed)` to produce the same hex
  /// values on every `build_runner` run, preventing unnecessary Git diffs in
  /// CI pipelines. When null, values are seeded from the enum name + field
  /// name hash, which is also stable across runs on the same codebase.
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

  const StealthEnum({
    this.seed,
    this.generateWhen = true,
    this.name,
  });
}
