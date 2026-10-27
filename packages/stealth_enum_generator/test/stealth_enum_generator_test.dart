import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:stealth_enum_generator/src/builder.dart';
import 'package:stealth_enum_generator/src/stealth_enum_generator.dart';
import 'package:test/test.dart';

const _stealthEnumPkgSource = '''
library stealth_enum;

class StealthEnum {
  final int? seed;
  final bool generateWhen;
  final String? name;
  final bool generateLabel;

  const StealthEnum({
    this.seed,
    this.generateWhen = true,
    this.name,
    this.generateLabel = false,
  });
}

class StealthValue {
  final int value;
  const StealthValue(this.value);
}
''';

Map<String, String> _withSources(Map<String, String> packageSources) {
  return {
    'stealth_enum|lib/stealth_enum.dart': _stealthEnumPkgSource,
    ...packageSources,
  };
}

void main() {
  group('StealthEnumGenerator metadata & setup', () {
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

  group('StealthEnumGenerator code generation', () {
    test('generates standard extension type with zero string footprint',
        () async {
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/role.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'role.g.dart';

@StealthEnum()
enum _UserRole { guest, member, admin }
''',
        }),
        outputs: {
          'a|lib/role.stealth_enum.g.part': decodedMatches(
            allOf([
              contains('extension type const UserRole._(int rawValue) {'),
              contains('static const UserRole guest = UserRole._('),
              contains('static const UserRole member = UserRole._('),
              contains('static const UserRole admin = UserRole._('),
              contains('static UserRole? tryFromRawValue(int rawValue) {'),
              contains('bool get isValid => UserRole.values.contains(this);'),
              // toJson / fromJson always emitted
              contains('int toJson() => rawValue;'),
              contains(
                  'static UserRole? fromJson(int rawValue) => tryFromRawValue(rawValue);'),
              // Exhaustive pattern matching with fail-closed StateError
              contains('T when<T>({'),
              contains('T maybeWhen<T>({'),
              contains("_ => throw StateError(''),"),
              // Must NOT contain string labels when generateLabel is false
              isNot(contains('String get label')),
              isNot(contains('byLabel(')),
            ]),
          ),
        },
      );
    });

    test('generateLabel: true emits .label and byLabel helpers', () async {
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/theme.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'theme.g.dart';

@StealthEnum(generateLabel: true)
enum _AppTheme { light, dark, system }
''',
        }),
        outputs: {
          'a|lib/theme.stealth_enum.g.part': decodedMatches(
            allOf([
              contains('extension type const AppTheme._(int rawValue) {'),
              contains('String get label => switch (rawValue) {'),
              contains("=> 'light',"),
              contains("=> 'dark',"),
              contains("=> 'system',"),
              contains('static AppTheme? byLabel(String label) {'),
              contains("'light' => light,"),
              contains("'dark' => dark,"),
              contains("'system' => system,"),
              // toJson and fromJson are also present
              contains('int toJson() => rawValue;'),
              contains(
                  'static AppTheme? fromJson(int rawValue) => tryFromRawValue(rawValue);'),
            ]),
          ),
        },
      );
    });

    test('@StealthValue assigns explicit immutable integer values', () async {
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/tier.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'tier.g.dart';

@StealthEnum()
enum _SubscriptionTier {
  @StealthValue(0x10000001)
  free,
  @StealthValue(0x7F000002)
  premium,
}
''',
        }),
        outputs: {
          'a|lib/tier.stealth_enum.g.part': decodedMatches(
            allOf([
              contains(
                  'static const SubscriptionTier free = SubscriptionTier._(0x10000001);'),
              contains(
                  'static const SubscriptionTier premium = SubscriptionTier._(0x7F000002);'),
              contains('0x10000001 => free,'),
              contains('0x7F000002 => premium,'),
            ]),
          ),
        },
      );
    });

    test('generateWhen: false omits .when() and .maybeWhen() helpers',
        () async {
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/flag.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'flag.g.dart';

@StealthEnum(generateWhen: false)
enum _FeatureFlag { enabled, disabled }
''',
        }),
        outputs: {
          'a|lib/flag.stealth_enum.g.part': decodedMatches(
            allOf([
              contains('extension type const FeatureFlag._(int rawValue) {'),
              contains('int toJson() => rawValue;'),
              isNot(contains('T when<T>({')),
              isNot(contains('T maybeWhen<T>({')),
            ]),
          ),
        },
      );
    });

    test('name parameter overrides public extension type name', () async {
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/role.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'role.g.dart';

@StealthEnum(name: 'PublicUserRole')
enum _Role { guest, admin }
''',
        }),
        outputs: {
          'a|lib/role.stealth_enum.g.part': decodedMatches(
            allOf([
              contains('extension type const PublicUserRole._(int rawValue) {'),
              contains('static const PublicUserRole guest = PublicUserRole._('),
              contains('static const PublicUserRole admin = PublicUserRole._('),
            ]),
          ),
        },
      );
    });

    test(
        'per-constant FNV-1a stability: inserting a constant does NOT shift other values',
        () async {
      String? originalGuestHex;
      String? originalAdminHex;

      // 1. Initial enum: guest, admin
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/role.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'role.g.dart';

@StealthEnum()
enum _UserRole { guest, admin }
''',
        }),
        outputs: {
          'a|lib/role.stealth_enum.g.part':
              decodedMatches(predicate<String>((content) {
            final guestMatch =
                RegExp(r'guest = UserRole\._\((0x[0-9A-Fa-f]+)\)')
                    .firstMatch(content);
            final adminMatch =
                RegExp(r'admin = UserRole\._\((0x[0-9A-Fa-f]+)\)')
                    .firstMatch(content);
            originalGuestHex = guestMatch?.group(1);
            originalAdminHex = adminMatch?.group(1);
            expect(originalGuestHex, isNotNull);
            expect(originalAdminHex, isNotNull);
            return true;
          })),
        },
      );

      // 2. Modified enum: inserted 'moderator' in between guest and admin
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/role.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'role.g.dart';

@StealthEnum()
enum _UserRole { guest, moderator, admin }
''',
        }),
        outputs: {
          'a|lib/role.stealth_enum.g.part':
              decodedMatches(predicate<String>((content) {
            final guestMatch =
                RegExp(r'guest = UserRole\._\((0x[0-9A-Fa-f]+)\)')
                    .firstMatch(content);
            final adminMatch =
                RegExp(r'admin = UserRole\._\((0x[0-9A-Fa-f]+)\)')
                    .firstMatch(content);
            // Must match original values exactly!
            expect(guestMatch?.group(1), equals(originalGuestHex),
                reason:
                    'guest rawValue must not shift when inserting moderator');
            expect(adminMatch?.group(1), equals(originalAdminHex),
                reason:
                    'admin rawValue must not shift when inserting moderator');
            return true;
          })),
        },
      );
    });
  });

  group('StealthEnumGenerator validation errors', () {
    test('logs error when applied to a non-enum declaration', () async {
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/invalid.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'invalid.g.dart';

@StealthEnum()
class _InvalidClass {}
''',
        }),
        outputs: {},
      );
    });

    test('logs error when duplicate @StealthValue is used in same enum',
        () async {
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/dup.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'dup.g.dart';

@StealthEnum()
enum _DuplicateVal {
  @StealthValue(0x10000001)
  a,
  @StealthValue(0x10000001)
  b,
}
''',
        }),
        outputs: {},
      );
    });
  });
}
