// Example showing how stealth_enum_generator is invoked via build_runner.
//
// 1. In your pubspec.yaml:
//
// dependencies:
//   stealth_enum: ^1.0.0
//
// dev_dependencies:
//   build_runner: ^2.4.0
//   stealth_enum_generator: ^1.0.0
//
// 2. In your Dart file:
//
// import 'package:stealth_enum/stealth_enum.dart';
//
// part 'example.g.dart';
//
// @StealthEnum()
// enum _UserRole { guest, member, admin }
//
// 3. Run the generator:
// dart run build_runner build
void main() {
  print('stealth_enum_generator generates extension types using build_runner.');
}
