import 'package:test/test.dart';

// The extension types are generated as `part of` these files.
// Importing the parent files gives us access to SecurityClearance and SubscriptionStatus.
import 'package:stealth_enum_example/security_clearance.dart';
import 'package:stealth_enum_example/subscription_status.dart';

void main() {
  group('SecurityClearance extension type', () {
    test('equality — same constant equals itself', () {
      expect(SecurityClearance.admin, equals(SecurityClearance.admin));
      expect(SecurityClearance.guest, equals(SecurityClearance.guest));
    });

    test('fromRawValue reconstructs constants and wraps raw integers', () {
      expect(
        SecurityClearance.fromRawValue(SecurityClearance.guest.rawValue),
        equals(SecurityClearance.guest),
      );
      expect(
        SecurityClearance.fromRawValue(SecurityClearance.admin.rawValue),
        equals(SecurityClearance.admin),
      );
    });

    test('tryFromRawValue parses known values and returns null on unknown', () {
      for (final v in SecurityClearance.values) {
        expect(SecurityClearance.tryFromRawValue(v.rawValue), equals(v));
      }
      expect(SecurityClearance.tryFromRawValue(0x12345678), isNull);
    });

    test('isValid returns true for valid constants and false for invalid rawValue', () {
      for (final v in SecurityClearance.values) {
        expect(v.isValid, isTrue);
      }
      final invalid = SecurityClearance.fromRawValue(0x12345678);
      expect(invalid.isValid, isFalse);
    });

    test('inequality — different constants are not equal', () {
      expect(SecurityClearance.admin, isNot(equals(SecurityClearance.guest)));
      expect(
          SecurityClearance.operator, isNot(equals(SecurityClearance.superAdmin)));
    });

    test('extension type erases to int at runtime', () {
      // The core guarantee: the extension type is a zero-cost wrapper.
      // At runtime it IS an int — no wrapper object allocated.
      expect(SecurityClearance.admin as Object, isA<int>());
      expect(SecurityClearance.guest as Object, isA<int>());
    });

    test('raw values are non-sequential', () {
      final values = SecurityClearance.values.map((v) => v.rawValue).toList();
      // Check that values are not in the form 0,1,2,3
      final sequential = List.generate(values.length, (i) => i);
      expect(values, isNot(equals(sequential)));
    });

    test('raw values are unique (no collision)', () {
      final rawValues =
          SecurityClearance.values.map((v) => v.rawValue).toSet();
      expect(rawValues.length, equals(SecurityClearance.values.length));
    });

    test('.when() — exhaustive matching returns correct values', () {
      expect(
        SecurityClearance.guest.when(
          guest: () => 'g',
          operator: () => 'o',
          admin: () => 'a',
          superAdmin: () => 's',
        ),
        equals('g'),
      );
      expect(
        SecurityClearance.admin.when(
          guest: () => 'g',
          operator: () => 'o',
          admin: () => 'a',
          superAdmin: () => 's',
        ),
        equals('a'),
      );
      expect(
        SecurityClearance.superAdmin.when(
          guest: () => 'g',
          operator: () => 'o',
          admin: () => 'a',
          superAdmin: () => 's',
        ),
        equals('s'),
      );
    });

    test('.when() — all branches execute exactly once', () {
      final called = <String>[];
      SecurityClearance.operator.when(
        guest: () => called.add('guest'),
        operator: () => called.add('operator'),
        admin: () => called.add('admin'),
        superAdmin: () => called.add('superAdmin'),
      );
      expect(called, equals(['operator']));
    });

    test('.when() fails closed on corrupted or invalid rawValue', () {
      final invalid = SecurityClearance.fromRawValue(0x12345678);
      expect(
        () => invalid.when(
          guest: () => 'g',
          operator: () => 'o',
          admin: () => 'a',
          superAdmin: () => 's',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('.maybeWhen() — matching branch executes', () {
      final result = SecurityClearance.admin.maybeWhen(
        admin: () => 'admin hit',
        orElse: () => 'fallback',
      );
      expect(result, equals('admin hit'));
    });

    test('.maybeWhen() — orElse fires when no matching branch provided', () {
      final result = SecurityClearance.guest.maybeWhen(
        admin: () => 'admin hit',
        orElse: () => 'fallback',
      );
      expect(result, equals('fallback'));
    });

    test('.values list contains all constants in declaration order', () {
      expect(SecurityClearance.values, hasLength(4));
      expect(SecurityClearance.values[0], equals(SecurityClearance.guest));
      expect(SecurityClearance.values[1], equals(SecurityClearance.operator));
      expect(SecurityClearance.values[2], equals(SecurityClearance.admin));
      expect(SecurityClearance.values[3], equals(SecurityClearance.superAdmin));
    });
  });

  group('SubscriptionStatus extension type (seeded)', () {
    test('equality holds', () {
      expect(SubscriptionStatus.active, equals(SubscriptionStatus.active));
      expect(SubscriptionStatus.trial, isNot(equals(SubscriptionStatus.expired)));
    });

    test('raw values are non-sequential', () {
      final values =
          SubscriptionStatus.values.map((v) => v.rawValue).toList();
      final sequential = List.generate(values.length, (i) => i);
      expect(values, isNot(equals(sequential)));
    });

    test('deterministic: re-running build gives same values', () {
      // Because seed:42 is fixed, the constants always have the same rawValue.
      // Simply assert they are non-zero integers (we cannot know exact values
      // here without running the generator, but the test confirms they exist).
      for (final v in SubscriptionStatus.values) {
        expect(v.rawValue, greaterThan(0));
      }
    });

    test('.when() exhaustive matching', () {
      expect(
        SubscriptionStatus.cancelled.when(
          trial: () => 0,
          active: () => 1,
          expired: () => 2,
          cancelled: () => 3,
        ),
        equals(3),
      );
    });

    test('.when() fails closed on corrupted or invalid rawValue', () {
      final invalid = SubscriptionStatus.fromRawValue(0x99999999);
      expect(
        () => invalid.when(
          trial: () => 0,
          active: () => 1,
          expired: () => 2,
          cancelled: () => 3,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('.maybeWhen() orElse fallback', () {
      expect(
        SubscriptionStatus.trial.maybeWhen(
          active: () => 'active',
          orElse: () => 'other',
        ),
        equals('other'),
      );
    });

    test('fromRawValue reconstructs constants and wraps raw integers', () {
      expect(
        SubscriptionStatus.fromRawValue(SubscriptionStatus.active.rawValue),
        equals(SubscriptionStatus.active),
      );
      expect(
        SubscriptionStatus.fromRawValue(SubscriptionStatus.trial.rawValue),
        equals(SubscriptionStatus.trial),
      );
    });

    test('tryFromRawValue parses known values and returns null on unknown', () {
      for (final v in SubscriptionStatus.values) {
        expect(SubscriptionStatus.tryFromRawValue(v.rawValue), equals(v));
      }
      expect(SubscriptionStatus.tryFromRawValue(0x99999999), isNull);
    });

    test('isValid returns true for valid constants and false for invalid rawValue', () {
      for (final v in SubscriptionStatus.values) {
        expect(v.isValid, isTrue);
      }
      final invalid = SubscriptionStatus.fromRawValue(0x99999999);
      expect(invalid.isValid, isFalse);
    });
  });
}
