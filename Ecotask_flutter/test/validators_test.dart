import 'package:ecotask/core/app_date.dart';
import 'package:ecotask/core/chart_scale.dart';
import 'package:ecotask/core/number_format.dart';
import 'package:ecotask/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('nope'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email('jane@example.com'), isNull);
      expect(Validators.email(' jane+tag@mail.example.org '), isNull);
    });

    test('name length 2-50', () {
      expect(Validators.name(''), isNotNull);
      expect(Validators.name('A'), isNotNull);
      expect(Validators.name('Al'), isNull);
      expect(Validators.name('x' * 50), isNull);
      expect(Validators.name('x' * 51), isNotNull);
    });

    test('password rules', () {
      expect(Validators.newPassword('12345'),
          'Password must be at least 6 characters');
      expect(Validators.newPassword('123456'), isNull);
      expect(Validators.loginPassword(''), isNotNull);
      expect(Validators.loginPassword('x'), isNull);
    });

    test('task title 1-200', () {
      expect(Validators.taskTitle('  '), isNotNull);
      expect(Validators.taskTitle('Bike ride'), isNull);
      expect(Validators.taskTitle('x' * 201), isNotNull);
    });

    test('quantity must be a number >= 0.01', () {
      expect(Validators.quantity(''), isNotNull);
      expect(Validators.quantity('abc'), isNotNull);
      expect(Validators.quantity('0'), isNotNull);
      expect(Validators.quantity('0.009'), isNotNull);
      expect(Validators.quantity('0.01'), isNull);
      expect(Validators.quantity('12.5'), isNull);
      expect(Validators.quantity('NaN'), isNotNull);
    });

    test('category and date', () {
      expect(Validators.category('food'), isNull);
      expect(Validators.category('bogus'), isNotNull);
      expect(Validators.date('2026-02-30'), isNotNull);
      expect(Validators.date('22/10/2026'), isNotNull);
      expect(Validators.date('2026-10-22'), isNull);
    });
  });

  group('AppDate', () {
    test('formats and parses', () {
      expect(AppDate.dayOf(DateTime(2026, 3, 5)), '2026-03-05');
      expect(AppDate.tryParse('2026-03-05'), DateTime(2026, 3, 5));
      expect(AppDate.tryParse('2026-13-01'), isNull);
      expect(AppDate.tryParse(null), isNull);
    });

    test('daysAgo crosses month/year/leap boundaries', () {
      expect(AppDate.daysAgo(1, from: DateTime(2026, 3, 1)), '2026-02-28');
      expect(AppDate.daysAgo(1, from: DateTime(2024, 3, 1)), '2024-02-29');
      expect(AppDate.daysAgo(30, from: DateTime(2026, 1, 15)), '2025-12-16');
    });
  });

  group('JsNumber', () {
    test('round matches parseFloat(toFixed())', () {
      expect(JsNumber.round(3.14159, 2), 3.14);
      expect(JsNumber.round(0.125, 2), 0.13);
      expect(JsNumber.round(-0.125, 2), -0.13);
    });

    test('toJsString prints integers without .0', () {
      expect(JsNumber.toJsString(27), '27');
      expect(JsNumber.toJsString(27.5), '27.5');
      expect(JsNumber.toJsString(-21.77), '-21.77');
    });
  });

  group('niceScale', () {
    test('includes zero and picks round steps', () {
      final s = niceScale(0, 15.6);
      expect(s.min, 0);
      expect(s.max, 20);
      expect(s.interval, 5);
    });

    test('handles negatives and all-zero data', () {
      final neg = niceScale(-1.18, 15.6);
      expect(neg.min <= -1.18, isTrue);
      expect(neg.max >= 15.6, isTrue);
      final zero = niceScale(0, 0);
      expect(zero.max > zero.min, isTrue);
    });
  });
}
