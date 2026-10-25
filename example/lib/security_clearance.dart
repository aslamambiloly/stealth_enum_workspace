import 'package:stealth_enum/stealth_enum.dart';

part 'security_clearance.g.dart';

/// Source private enum — annotated, private, and never referenced at runtime.
/// The Dart AOT tree-shaker will 100% delete `_SecurityClearance` and its
/// plain-text string table from `libapp.so`. Only the generated
/// [SecurityClearance] extension type (raw integers) survives in the binary.
@StealthEnum()
enum _SecurityClearance {
  guest,
  operator,
  admin,
  superAdmin,
}
