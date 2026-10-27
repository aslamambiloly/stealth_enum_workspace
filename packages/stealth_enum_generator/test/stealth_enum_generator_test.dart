import 'dart:convert';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:crypto/crypto.dart';
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
              contains(
                  'static const PaymentGateway googlePay = PaymentGateway._('),
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

    test('seed parameter derives valid deterministic constants', () async {
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/seeded.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'seeded.g.dart';

@StealthEnum(seed: 42)
enum _SeededStatus { a, b }
''',
        }),
        outputs: {
          'a|lib/seeded.stealth_enum.g.part': decodedMatches(
            allOf([
              contains('extension type const SeededStatus._(int rawValue) {'),
              contains('static const SeededStatus a = SeededStatus._('),
              contains('static const SeededStatus b = SeededStatus._('),
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
              contains(
                  'extension type const RenamedClearance._(int rawValue) {'),
              contains(
                  'static const RenamedClearance low = RenamedClearance._('),
              contains(
                  'static const RenamedClearance high = RenamedClearance._('),
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
          'a|lib/stable.stealth_enum.g.part':
              decodedMatches(predicate<String>((content) {
            final guestMatch = RegExp(
                    r'static const UserRole guest = UserRole\._\((0x[0-9A-Fa-f]+)\);')
                .firstMatch(content);
            final adminMatch = RegExp(
                    r'static const UserRole admin = UserRole\._\((0x[0-9A-Fa-f]+)\);')
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
          'a|lib/stable.stealth_enum.g.part':
              decodedMatches(predicate<String>((content) {
            final guestMatch = RegExp(
                    r'static const UserRole guest = UserRole\._\((0x[0-9A-Fa-f]+)\);')
                .firstMatch(content);
            final adminMatch = RegExp(
                    r'static const UserRole admin = UserRole\._\((0x[0-9A-Fa-f]+)\);')
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

    test('logs error when enum has no constants', () async {
      final logs = <String>[];
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/empty.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'empty.g.dart';

@StealthEnum()
enum _EmptyEnum {}
''',
        }),
        outputs: {},
        onLog: (LogRecord record) => logs.add(record.message),
      );
      expect(
        logs,
        anyElement(
            contains('@StealthEnum enum must have at least one constant')),
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
        anyElement(
            contains('Values must be positive 32-bit unsigned integers')),
      );
    });

    test(
        'logs error when @StealthValue has trivial sequential value (< 0x1000)',
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

    test(
        'logs error when constant collides with reserved member name (including fromRawValue)',
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

    test(
        'stealthEnumBuilder derives exact HMAC values, emits key fingerprint, and differs from default salt',
        () async {
      const key = 'project_wide_ci_secret_key';
      final expectedActive = _expectedHex(key, 'SecretStatus', 'active');
      final expectedInactive = _expectedHex(key, 'SecretStatus', 'inactive');
      final defaultActive = _defaultSaltHex('SecretStatus', 'active');
      final defaultInactive = _defaultSaltHex('SecretStatus', 'inactive');
      final expectedFp = Hmac(sha256, utf8.encode(key))
          .convert(utf8.encode('stealth_enum:fingerprint:v1'))
          .toString()
          .substring(0, 8);

      expect(expectedActive, isNot(equals(defaultActive)),
          reason: 'Keyed hash must differ from default salt');
      expect(expectedInactive, isNot(equals(defaultInactive)),
          reason: 'Keyed hash must differ from default salt');

      await testBuilder(
        stealthEnumBuilder(const BuilderOptions({'key': key})),
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
              contains('// Key fingerprint: $expectedFp'),
              contains('extension type const SecretStatus._(int rawValue) {'),
              contains(
                  'static const SecretStatus active = SecretStatus._($expectedActive);'),
              contains(
                  'static const SecretStatus inactive = SecretStatus._($expectedInactive);'),
            ]),
          ),
        },
      );
    });

    test(
        'stealthEnumBuilder handles numeric key in config without cast exception',
        () async {
      const numericKey = 12345;
      final expectedActive = _expectedHex('12345', 'NumStatus', 'active');

      await testBuilder(
        stealthEnumBuilder(const BuilderOptions({'key': numericKey})),
        _withSources({
          'a|lib/num_status.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'num_status.g.dart';

@StealthEnum()
enum _NumStatus { active }
''',
        }),
        outputs: {
          'a|lib/num_status.stealth_enum.g.part': decodedMatches(
            contains(
                'static const NumStatus active = NumStatus._($expectedActive);'),
          ),
        },
      );
    });

    test('key precedence: enum-level key overrides global builder key',
        () async {
      const globalKey = 'global_builder_key';
      const localKey = 'local_enum_key';
      final expectedLocal = _expectedHex(localKey, 'OverrideStatus', 'active');
      final expectedGlobal =
          _expectedHex(globalKey, 'OverrideStatus', 'active');

      expect(expectedLocal, isNot(equals(expectedGlobal)));

      await testBuilder(
        stealthEnumBuilder(const BuilderOptions({'key': globalKey})),
        _withSources({
          'a|lib/override_status.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'override_status.g.dart';

@StealthEnum(key: '$localKey')
enum _OverrideStatus { active }
''',
        }),
        outputs: {
          'a|lib/override_status.stealth_enum.g.part': decodedMatches(
            contains(
                'static const OverrideStatus active = OverrideStatus._($expectedLocal);'),
          ),
        },
      );
    });

    test('key precedence: global builder key overrides enum-level seed',
        () async {
      const globalKey = 'global_builder_key';
      const seed = 42;
      final expectedKeyed = _expectedHex(globalKey, 'SeededStatus', 'active');
      final expectedSeeded =
          _expectedHex('stealth_enum:seed:$seed', 'SeededStatus', 'active');

      expect(expectedKeyed, isNot(equals(expectedSeeded)));

      await testBuilder(
        stealthEnumBuilder(const BuilderOptions({'key': globalKey})),
        _withSources({
          'a|lib/seeded_status.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'seeded_status.g.dart';

@StealthEnum(seed: $seed)
enum _SeededStatus { active }
''',
        }),
        outputs: {
          'a|lib/seeded_status.stealth_enum.g.part': decodedMatches(
            contains(
                'static const SeededStatus active = SeededStatus._($expectedKeyed);'),
          ),
        },
      );
    });

    test('require_key: true fails build when key is absent or empty', () async {
      final logs = <String>[];
      await testBuilder(
        stealthEnumBuilder(const BuilderOptions({'require_key': true})),
        _withSources({
          'a|lib/unkeyed.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'unkeyed.g.dart';

@StealthEnum()
enum _Unkeyed { active }
''',
        }),
        outputs: {},
        onLog: (LogRecord record) => logs.add(record.message),
      );
      expect(
        logs,
        anyElement(
            contains('requires a secret key for cryptographic security')),
      );
    });

    test('require_key: false logs warning when enum uses public default salt',
        () async {
      final logs = <String>[];
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/warn_enum.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'warn_enum.g.dart';

@StealthEnum()
enum _WarnEnum { active }
''',
        }),
        outputs: {
          'a|lib/warn_enum.stealth_enum.g.part': decodedMatches(
            contains('static const WarnEnum active = WarnEnum._('),
          ),
        },
        onLog: (LogRecord record) => logs.add(record.message),
      );
      expect(
        logs,
        anyElement(contains('is using the public default salt')),
      );
    });

    test('logs warning when key is under 24 characters', () async {
      final logs = <String>[];
      await testBuilder(
        stealthEnumBuilder(const BuilderOptions({'key': 'short_key_123'})),
        _withSources({
          'a|lib/short_keyed.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'short_keyed.g.dart';

@StealthEnum()
enum _ShortKeyed { a }
''',
        }),
        outputs: {
          'a|lib/short_keyed.stealth_enum.g.part': decodedMatches(
            contains('static const ShortKeyed a = ShortKeyed._('),
          ),
        },
        onLog: (LogRecord record) => logs.add(record.message),
      );
      expect(
        logs,
        anyElement(contains('is under 24 chars')),
      );
    });

    test(
        'all explicit @StealthValue constants skip default-salt warning, fingerprint, and require_key check',
        () async {
      final logs = <String>[];
      await testBuilder(
        stealthEnumBuilder(const BuilderOptions({'require_key': true})),
        _withSources({
          'a|lib/frozen.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'frozen.g.dart';

@StealthEnum()
enum _Frozen {
  @StealthValue(0x10000001)
  a,
  @StealthValue(0x20000002)
  b,
}
''',
        }),
        outputs: {
          'a|lib/frozen.stealth_enum.g.part': decodedMatches(
            allOf([
              contains('static const Frozen a = Frozen._(0x10000001);'),
              contains('static const Frozen b = Frozen._(0x20000002);'),
              isNot(contains('// Key fingerprint:')),
            ]),
          ),
        },
        onLog: (LogRecord record) => logs.add(record.message),
      );
      expect(
        logs,
        isNot(anyElement(contains('is using the public default salt'))),
      );
      expect(
        logs,
        isNot(anyElement(
            contains('requires a secret key for cryptographic security'))),
      );
    });

    test('seed-only enum logs warning about low entropy', () async {
      final logs = <String>[];
      await testBuilder(
        stealthEnumBuilder(BuilderOptions.empty),
        _withSources({
          'a|lib/seeded_warn.dart': '''
import 'package:stealth_enum/stealth_enum.dart';

part 'seeded_warn.g.dart';

@StealthEnum(seed: 42)
enum _SeededWarn { a }
''',
        }),
        outputs: {
          'a|lib/seeded_warn.stealth_enum.g.part': decodedMatches(
            contains('static const SeededWarn a = SeededWarn._('),
          ),
        },
        onLog: (LogRecord record) => logs.add(record.message),
      );
      expect(
        logs,
        anyElement(
            contains('is using a 32-bit integer seed. Seeds have low entropy')),
      );
    });
  });
}

String _expectedHex(String key, String enumName, String field) {
  final b = Hmac(sha256, utf8.encode(key))
      .convert(utf8.encode('$enumName::$field'))
      .bytes;
  final raw = ((b[0] & 0xFF) << 24) |
      ((b[1] & 0xFF) << 16) |
      ((b[2] & 0xFF) << 8) |
      (b[3] & 0xFF);
  final pos = raw & 0x7FFFFFFF;
  final val = pos < 0x10000000 ? pos + 0x10000000 : pos;
  return '0x${val.toRadixString(16).toUpperCase().padLeft(8, '0')}';
}

String _defaultSaltHex(String enumName, String field) {
  return _expectedHex('stealth_enum:default_salt:0xDEADBEEF', enumName, field);
}
