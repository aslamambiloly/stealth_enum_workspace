import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:stealth_enum_generator/src/builder.dart';
import 'package:stealth_enum_generator/src/stealth_enum_generator.dart';
import 'package:test/test.dart';

const _stealthEnumPkgSource = '''
library stealth_enum;

class StealthEnum {
  final int? seed;
  final String? key;
  final bool generateWhen;
  final String? name;
  final bool generateLabel;

  const StealthEnum({
    this.seed,
    this.key,
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
              contains(
                  'bool get isValid => tryFromRawValue(rawValue) != null;'),
              // toJson / fromJson always emitted
              contains('int toJson() => rawValue;'),
              contains(
                  'static UserRole? fromJson(int rawValue) => tryFromRawValue(rawValue);'),
              // Exhaustive pattern matching with fail-closed StateError
              contains('R when<R>({'),
              contains('R maybeWhen<R>({'),
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
              contains('String get label => switch (this) {'),
              contains("light => 'light',"),
              contains("dark => 'dark',"),
              contains("system => 'system',"),
              contains(
                  'static AppTheme? byLabel(String label) => switch (label) {'),
              contains("'light' => light,"),
              contains("'dark' => dark,"),
              contains("'system' => system,"),
              // toJson/fromJson still operate on ints
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
          'a|lib/payment.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'payment.g.dart';

@StealthEnum()
enum _PaymentGateway {
  @StealthValue(0x10000001)
  stripe,
  @StealthValue(0x7F000002)
  applePay,
  googlePay,
}
''',
        }),
        outputs: {
          'a|lib/payment.stealth_enum.g.part': decodedMatches(
            allOf([
              contains(
                  'static const PaymentGateway stripe = PaymentGateway._(0x10000001);'),
              contains(
                  'static const PaymentGateway applePay = PaymentGateway._(0x7F000002);'),
              // googlePay derives its value automatically
              contains('static const PaymentGateway googlePay = PaymentGateway._('),
            ]),
          ),
        },
      );
    });

    test('custom key parameter derives valid deterministic constants',
        () async {
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/keyed.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'keyed.g.dart';

@StealthEnum(key: 'my_project_secret_salt_1234')
enum _KeyedStatus { pending, approved, rejected }
''',
        }),
        outputs: {
          'a|lib/keyed.stealth_enum.g.part': decodedMatches(
            allOf([
              contains('extension type const KeyedStatus._(int rawValue) {'),
              contains('static const KeyedStatus pending = KeyedStatus._('),
              contains('static const KeyedStatus approved = KeyedStatus._('),
              contains('static const KeyedStatus rejected = KeyedStatus._('),
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
          'a|lib/simple.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'simple.g.dart';

@StealthEnum(generateWhen: false)
enum _SimpleMode { on, off }
''',
        }),
        outputs: {
          'a|lib/simple.stealth_enum.g.part': decodedMatches(
            allOf([
              contains('extension type const SimpleMode._(int rawValue) {'),
              isNot(contains('when<')),
              isNot(contains('maybeWhen<')),
            ]),
          ),
        },
      );
    });

    test('name parameter overrides public extension type name', () async {
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/custom_name.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'custom_name.g.dart';

@StealthEnum(name: 'RenamedClearance')
enum _InternalClearance { low, high }
''',
        }),
        outputs: {
          'a|lib/custom_name.stealth_enum.g.part': decodedMatches(
            allOf([
              contains('extension type const RenamedClearance._(int rawValue) {'),
              contains('static const RenamedClearance low = RenamedClearance._('),
              contains('static const RenamedClearance high = RenamedClearance._('),
            ]),
          ),
        },
      );
    });

    test(
        'per-constant HMAC-SHA256 stability: inserting a constant does NOT shift other values',
        () async {
      String? originalGuestHex;
      String? originalAdminHex;

      // First run: 2 constants
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/stable.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'stable.g.dart';

@StealthEnum()
enum _UserRole { guest, admin }
''',
        }),
        outputs: {
          'a|lib/stable.stealth_enum.g.part': decodedMatches(
              predicate<String>((content) {
            final guestMatch =
                RegExp(r'static const UserRole guest = UserRole\._\((0x[0-9A-Fa-f]+)\);')
                    .firstMatch(content);
            final adminMatch =
                RegExp(r'static const UserRole admin = UserRole\._\((0x[0-9A-Fa-f]+)\);')
                    .firstMatch(content);
            expect(guestMatch, isNotNull);
            expect(adminMatch, isNotNull);
            originalGuestHex = guestMatch!.group(1);
            originalAdminHex = adminMatch!.group(1);
            return true;
          })),
        },
      );

      // Second run: insert 'moderator' between guest and admin
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/stable.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'stable.g.dart';

@StealthEnum()
enum _UserRole { guest, moderator, admin }
''',
        }),
        outputs: {
          'a|lib/stable.stealth_enum.g.part': decodedMatches(
              predicate<String>((content) {
            final guestMatch =
                RegExp(r'static const UserRole guest = UserRole\._\((0x[0-9A-Fa-f]+)\);')
                    .firstMatch(content);
            final adminMatch =
                RegExp(r'static const UserRole admin = UserRole\._\((0x[0-9A-Fa-f]+)\);')
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
    test('logs error with exact message when applied to a non-enum declaration',
        () async {
      final logs = <String>[];
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
        onLog: (LogRecord record) => logs.add(record.message),
      );
      expect(
        logs,
        anyElement(contains('can only be applied to an enum declaration')),
      );
    });

    test('logs error when enum is not declared private with leading underscore',
        () async {
      final logs = <String>[];
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/public_enum.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'public_enum.g.dart';

@StealthEnum()
enum PublicEnum { a, b }
''',
        }),
        outputs: {},
        onLog: (LogRecord record) => logs.add(record.message),
      );
      expect(
        logs,
        anyElement(contains(
            'can only be applied to private enum declarations starting with a leading underscore')),
      );
    });

    test('logs error when duplicate @StealthValue is used in same enum',
        () async {
      final logs = <String>[];
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
        onLog: (LogRecord record) => logs.add(record.message),
      );
      expect(
        logs,
        anyElement(contains('Duplicate @StealthValue(0x10000001)')),
      );
    });

    test('logs error when @StealthValue has negative value', () async {
      final logs = <String>[];
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/neg.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'neg.g.dart';

@StealthEnum()
enum _NegativeVal {
  @StealthValue(-5)
  a,
}
''',
        }),
        outputs: {},
        onLog: (LogRecord record) => logs.add(record.message),
      );
      expect(
        logs,
        anyElement(contains('Values must be positive 32-bit unsigned integers')),
      );
    });

    test('logs error when @StealthValue has trivial sequential value (< 0x1000)',
        () async {
      final logs = <String>[];
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/small.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'small.g.dart';

@StealthEnum()
enum _SmallVal {
  @StealthValue(1)
  a,
}
''',
        }),
        outputs: {},
        onLog: (LogRecord record) => logs.add(record.message),
      );
      expect(
        logs,
        anyElement(contains(
            'defeat reverse-engineering resistance by creating low sequential jump tables')),
      );
    });

    test('logs error when constant collides with reserved member name (including fromRawValue)',
        () async {
      final logs = <String>[];
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/reserved.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'reserved.g.dart';

@StealthEnum()
enum _ReservedVal {
  fromRawValue,
  admin,
}
''',
        }),
        outputs: {},
        onLog: (LogRecord record) => logs.add(record.message),
      );
      expect(
        logs,
        anyElement(contains(
            'collides with a generated extension type member or parameter')),
      );
    });

    test('stealthEnumBuilder applies config key from build.yaml', () async {
      await testBuilder(
        stealthEnumBuilder(
          const BuilderOptions({'key': 'project_wide_ci_secret_key'}),
        ),
        _withSources({
          'a|lib/secret_status.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'secret_status.g.dart';

@StealthEnum()
enum _SecretStatus { active, inactive }
''',
        }),
        outputs: {
          'a|lib/secret_status.stealth_enum.g.part': decodedMatches(
            allOf([
              contains('extension type const SecretStatus._(int rawValue) {'),
              contains('static const SecretStatus active = SecretStatus._('),
              contains('static const SecretStatus inactive = SecretStatus._('),
            ]),
          ),
        },
      );
    });
  });
}
