import 'package:stealth_enum/stealth_enum.dart';
import 'package:test/test.dart';

void main() {
  group('StealthEnum annotation', () {
    test('default constructor sets default values', () {
      const annotation = StealthEnum();
      expect(annotation.seed, isNull);
      expect(annotation.generateWhen, isTrue);
      expect(annotation.name, isNull);
      expect(annotation.generateLabel, isFalse);
    });

    test('custom values are stored correctly', () {
      const annotation = StealthEnum(
        seed: 12345,
        key: 'project_secret_salt',
        generateWhen: false,
        name: 'CustomStatus',
      );
      expect(annotation.seed, equals(12345));
      expect(annotation.key, equals('project_secret_salt'));
      expect(annotation.generateWhen, isFalse);
      expect(annotation.name, equals('CustomStatus'));
      expect(annotation.generateLabel, isFalse);
    });

    test('generateLabel: true is stored correctly', () {
      const annotation = StealthEnum(generateLabel: true);
      expect(annotation.generateLabel, isTrue);
      // generateWhen still defaults to true
      expect(annotation.generateWhen, isTrue);
    });
  });

  group('StealthValue annotation', () {
    test('stores explicit integer value', () {
      const value = StealthValue(0x12345678);
      expect(value.value, equals(0x12345678));
    });
  });
}
