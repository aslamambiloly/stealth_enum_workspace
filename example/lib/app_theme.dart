import 'package:stealth_enum/stealth_enum.dart';

part 'app_theme.g.dart';

/// Example of an enum with [generateLabel: true].
///
/// Emits `.label` and `byLabel()` helpers for UI display names while still
/// erasing the source enum declaration. Note that label strings will be present
/// in the compiled binary (explicit opt-in).
@StealthEnum(generateLabel: true)
enum _AppTheme {
  light,
  dark,
  system,
}
