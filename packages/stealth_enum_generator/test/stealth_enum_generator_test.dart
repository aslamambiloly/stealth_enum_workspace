import 'package:build/build.dart';
import 'package:stealth_enum_generator/src/builder.dart';
import 'package:stealth_enum_generator/src/stealth_enum_generator.dart';
import 'package:test/test.dart';

void main() {
  group('StealthEnumGenerator', () {
    test('instantiates with const constructor', () {
      const generator = StealthEnumGenerator();
      expect(generator, isNotNull);
    });

    test('stealthEnumBuilder returns a valid Builder', () {
      final builder = stealthEnumBuilder(BuilderOptions.empty);
      expect(builder, isNotNull);
      expect(builder, isA<Builder>());
    });
  });
}
