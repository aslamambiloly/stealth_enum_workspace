import 'package:stealth_enum/stealth_enum.dart';
import 'package:test/test.dart';

void main() {
  group('StealthEnum annotation', () {
    test('default constructor sets default values', () {
      const annotation = StealthEnum();
      expect(annotation.seed, isNull);
      expect(annotation.generateWhen, isTrue);
      expect(annotation.name, isNull);
    });

    test('custom values are stored correctly', () {
      const annotation = StealthEnum(
        seed: 12345,
        generateWhen: false,
        name: 'CustomStatus',
      );
      expect(annotation.seed, equals(12345));
      expect(annotation.generateWhen, isFalse);
      expect(annotation.name, equals('CustomStatus'));
    });
  });
}
