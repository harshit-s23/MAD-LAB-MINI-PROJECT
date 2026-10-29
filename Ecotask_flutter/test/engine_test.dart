import 'dart:convert';
import 'dart:io';

import 'package:ecotask/core/app_date.dart';
import 'package:ecotask/models/badge.dart';
import 'package:ecotask/services/carbon_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixture values were produced by running the ORIGINAL backend
/// `carbonEngine.js` (see test/fixtures/engine_parity.json).
void main() {
  final fixture =
      jsonDecode(File('test/fixtures/engine_parity.json').readAsStringSync())
          as Map<String, dynamic>;

  group('calculateCarbonValue', () {
    test('known values from the original factors', () {
      expect(CarbonEngine.calculateCarbonValue('transport', 'car_petrol', 18),
          3.78);
      expect(CarbonEngine.calculateCarbonValue('food', 'beef', 0.4), 10.8);
      expect(CarbonEngine.calculateCarbonValue('other', 'tree_planted', 1),
          -21.77);
      expect(
          CarbonEngine.calculateCarbonValue('transport', 'cycling', 8), -0.16);
      expect(
          CarbonEngine.calculateCarbonValue('energy', 'natural_gas', 2), 4.08);
    });

    test('unknown category or subcategory yields 0', () {
      expect(CarbonEngine.calculateCarbonValue('nope', 'car_petrol', 5), 0);
      expect(CarbonEngine.calculateCarbonValue('transport', 'rocket', 5), 0);
      expect(CarbonEngine.calculateCarbonValue('transport', '', 5), 0);
      expect(CarbonEngine.calculateCarbonValue(null, null, 5), 0);
    });

    test('quantity defaults to 1', () {
      expect(CarbonEngine.calculateCarbonValue('food', 'dairy'), 3.2);
    });

    test(
        'matches the original JS for ${(fixture['carbon'] as List).length} random inputs',
        () {
      for (final c in fixture['carbon'] as List) {
        final got = CarbonEngine.calculateCarbonValue(c['category'] as String,
            c['subcategory'] as String, (c['quantity'] as num).toDouble());
        expect(got, (c['expected'] as num).toDouble(), reason: '$c');
      }
    });
  });

  group('calculateEcoScore', () {
    test('no emissions -> 100',
        () => expect(CarbonEngine.calculateEcoScore(0), 100));

    test('global average (13 kg/day) -> 50', () {
      expect(CarbonEngine.calculateEcoScore(13 * 30), 50);
    });

    test('twice the average (or more) clamps to 0', () {
      expect(CarbonEngine.calculateEcoScore(26 * 30), 0);
      expect(CarbonEngine.calculateEcoScore(5000), 0);
    });

    test('net savings clamp to 100',
        () => expect(CarbonEngine.calculateEcoScore(-200), 100));

    test('rounded to one decimal',
        () => expect(CarbonEngine.calculateEcoScore(2.1), 99.7));

    test('matches the original JS for random inputs', () {
      for (final c in fixture['score'] as List) {
        final got = CarbonEngine.calculateEcoScore(
            (c['total'] as num).toDouble(), c['days'] as int);
        expect(got, (c['expected'] as num).toDouble(), reason: '$c');
      }
    });
  });

  group('getEcoLevel', () {
    test('thresholds are inclusive and first match wins', () {
      expect(CarbonEngine.getEcoLevel(0).name, 'Seedling');
      expect(CarbonEngine.getEcoLevel(30).name, 'Seedling');
      expect(CarbonEngine.getEcoLevel(30.1).name, 'Sprout');
      expect(CarbonEngine.getEcoLevel(65).name, 'Leaf');
      expect(CarbonEngine.getEcoLevel(90).name, 'Forest');
      expect(CarbonEngine.getEcoLevel(90.1).name, 'Earth Guardian');
      expect(CarbonEngine.getEcoLevel(100).emoji, '🌍');
    });

    test('out of range falls back to the first level', () {
      expect(CarbonEngine.getEcoLevel(-5).name, 'Seedling');
      expect(CarbonEngine.getEcoLevel(150).name, 'Seedling');
    });

    test('matches the original JS', () {
      for (final c in fixture['level'] as List) {
        expect(CarbonEngine.getEcoLevel((c['score'] as num).toDouble()).name,
            c['expected'],
            reason: '$c');
      }
    });
  });

  group('generateSuggestions', () {
    test('no data -> waste + general tips', () {
      final s = CarbonEngine.generateSuggestions({});
      expect(s.map((e) => e.category).toList(), ['waste', 'general']);
    });

    test('high transport and food emissions', () {
      final s = CarbonEngine.generateSuggestions({
        'transport': CategoryAggregate(totalCarbon: 6, count: 2),
        'food': CategoryAggregate(totalCarbon: 9, count: 2),
        'energy': CategoryAggregate(totalCarbon: 4, count: 1),
      });
      expect(
          s.map((e) => e.category).toList(), ['transport', 'food', 'energy']);
    });

    test('never more than three', () {
      final s = CarbonEngine.generateSuggestions({
        'transport': CategoryAggregate(totalCarbon: 60, count: 2),
        'food': CategoryAggregate(totalCarbon: 90, count: 2),
        'energy': CategoryAggregate(totalCarbon: 40, count: 1),
        'waste': CategoryAggregate(totalCarbon: 1, count: 1),
      });
      expect(s.length, 3);
    });

    test('matches the original JS text and ordering', () {
      for (final c in fixture['suggestions'] as List) {
        final input = <String, CategoryAggregate>{};
        (c['input'] as Map<String, dynamic>).forEach((k, v) {
          input[k] = CategoryAggregate(
              totalCarbon: (v['totalCarbon'] as num).toDouble(),
              count: v['count'] as int);
        });
        final got = CarbonEngine.generateSuggestions(input)
            .map((s) => [s.category, s.tip, s.impact, s.icon])
            .toList();
        expect(jsonEncode(got), jsonEncode(c['expected']), reason: '$c');
      }
    });
  });

  group('checkBadges', () {
    List<String> ids(List<EarnedBadge> b) => b.map((e) => e.id).toList();

    test('first task awards first_task once', () {
      final a = CarbonEngine.checkBadges(
          currentBadges: const [], streak: 0, totalTasks: 1, ecoScore: 50);
      expect(ids(a), ['first_task']);
      final b = CarbonEngine.checkBadges(
          currentBadges: a, streak: 0, totalTasks: 2, ecoScore: 50);
      expect(ids(b), ['first_task']);
    });

    test('week_streak needs a streak of 7 and earth_guardian a score of 90',
        () {
      expect(
          ids(CarbonEngine.checkBadges(
              currentBadges: const [],
              streak: 6,
              totalTasks: 0,
              ecoScore: 89.9)),
          isEmpty);
      expect(
          ids(CarbonEngine.checkBadges(
              currentBadges: const [], streak: 7, totalTasks: 0, ecoScore: 90)),
          ['week_streak', 'earth_guardian']);
    });

    test(
        'only three of the eight badges can ever be awarded (original behaviour)',
        () {
      final a = CarbonEngine.checkBadges(
          currentBadges: const [], streak: 99, totalTasks: 99, ecoScore: 100);
      expect(ids(a).toSet(), {'first_task', 'week_streak', 'earth_guardian'});
      expect(CarbonEngine.badges.length, 8);
    });

    test('awarded badge keeps the full definition', () {
      final a = CarbonEngine.checkBadges(
              currentBadges: const [], streak: 0, totalTasks: 1, ecoScore: 0)
          .single;
      expect(a.name, 'First Step');
      expect(a.emoji, '🎯');
      expect(a.condition, 'tasks >= 1');
    });

    test('matches the original JS', () {
      for (final c in fixture['badges'] as List) {
        final current = (c['current'] as List)
            .map((id) => EarnedBadge(id: id as String, name: id, emoji: 'x'))
            .toList();
        final got = CarbonEngine.checkBadges(
          currentBadges: current,
          streak: c['streak'] as int,
          totalTasks: c['totalTasks'] as int,
          ecoScore: (c['ecoScore'] as num).toDouble(),
        );
        expect(ids(got), (c['expected'] as List).cast<String>(), reason: '$c');
      }
    });
  });

  group('updateStreak', () {
    final now = DateTime(2026, 10, 22, 9);

    test('no previous activity keeps the streak', () {
      expect(
          CarbonEngine.updateStreak(streak: 3, lastActiveDate: null, now: now),
          3);
      expect(CarbonEngine.updateStreak(streak: 3, lastActiveDate: '', now: now),
          3);
    });

    test('already active today keeps the streak', () {
      expect(
          CarbonEngine.updateStreak(
              streak: 4, lastActiveDate: '2026-10-22', now: now),
          4);
    });

    test('active yesterday increments', () {
      expect(
          CarbonEngine.updateStreak(
              streak: 4, lastActiveDate: '2026-10-21', now: now),
          5);
    });

    test('a gap resets to 1', () {
      expect(
          CarbonEngine.updateStreak(
              streak: 9, lastActiveDate: '2026-10-20', now: now),
          1);
      expect(
          CarbonEngine.updateStreak(
              streak: 9, lastActiveDate: '2025-01-01', now: now),
          1);
    });

    test('month and year boundaries', () {
      expect(
          CarbonEngine.updateStreak(
              streak: 1,
              lastActiveDate: '2026-02-28',
              now: DateTime(2026, 3, 1)),
          2);
      expect(
          CarbonEngine.updateStreak(
              streak: 1,
              lastActiveDate: '2025-12-31',
              now: DateTime(2026, 1, 1)),
          2);
      expect(
          CarbonEngine.updateStreak(
              streak: 1,
              lastActiveDate: '2024-02-29',
              now: DateTime(2024, 3, 1)),
          2);
    });

    test('uses the injectable clock by default', () {
      AppDate.now = () => now;
      addTearDown(() => AppDate.now = DateTime.now);
      expect(CarbonEngine.updateStreak(streak: 2, lastActiveDate: '2026-10-21'),
          3);
    });
  });
}
