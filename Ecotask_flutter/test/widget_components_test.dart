import 'package:ecotask/core/app_date.dart';
import 'package:ecotask/models/badge.dart';
import 'package:ecotask/models/dashboard_data.dart';
import 'package:ecotask/models/suggestion.dart';
import 'package:ecotask/models/task_input.dart';
import 'package:ecotask/providers/op_result.dart';
import 'package:ecotask/services/carbon_engine.dart';
import 'package:ecotask/theme/app_theme.dart';
import 'package:ecotask/widgets/badge_grid.dart';
import 'package:ecotask/widgets/carbon_pill.dart';
import 'package:ecotask/widgets/category_pie_chart.dart';
import 'package:ecotask/widgets/eco_score_ring.dart';
import 'package:ecotask/widgets/stat_card.dart';
import 'package:ecotask/widgets/suggestions_panel.dart';
import 'package:ecotask/widgets/task_card.dart';
import 'package:ecotask/widgets/task_form_sheet.dart';
import 'package:ecotask/widgets/weekly_trend_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

Widget host(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
          body: SingleChildScrollView(
              child: Padding(padding: const EdgeInsets.all(16), child: child))),
    );

void useBigScreen(WidgetTester tester, {double w = 500, double h = 2000}) {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('EcoScoreRing', () {
    testWidgets('shows the rounded score and level name', (tester) async {
      await tester.pumpWidget(host(
          EcoScoreRing(score: 67.5, level: CarbonEngine.getEcoLevel(67.5))));
      await tester.pump(const Duration(milliseconds: 1300));
      expect(find.text('68'), findsOneWidget);
      expect(find.text('Tree'), findsOneWidget);
      expect(find.text('ECO SCORE'), findsOneWidget);
    });

    testWidgets('perfect score', (tester) async {
      await tester.pumpWidget(
          host(EcoScoreRing(score: 100, level: CarbonEngine.getEcoLevel(100))));
      await tester.pump(const Duration(milliseconds: 1300));
      expect(find.text('100'), findsOneWidget);
      expect(find.text('Earth Guardian'), findsOneWidget);
    });
  });

  group('StatCard', () {
    testWidgets('renders label, value, unit and sub text', (tester) async {
      await tester.pumpWidget(host(const StatCard(
          icon: '📅',
          label: "Today's Emissions",
          value: '15.60',
          unit: 'kg CO₂',
          sub: 'Last 30 days')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text("TODAY'S EMISSIONS"), findsOneWidget);
      expect(find.text('15.60'), findsOneWidget);
      expect(find.text('kg CO₂'), findsOneWidget);
      expect(find.text('Last 30 days'), findsOneWidget);
    });
  });

  group('BadgeGrid', () {
    testWidgets('shows all eight badges, earned ones highlighted',
        (tester) async {
      await tester.pumpWidget(host(const BadgeGrid(earnedBadges: [
        EarnedBadge(id: 'first_task', name: 'First Step', emoji: '🎯')
      ])));
      await tester.pump(const Duration(seconds: 1));
      for (final b in CarbonEngine.badges) {
        expect(find.text(b.name), findsOneWidget);
      }
      expect(
          tester
              .widget<Opacity>(find.byKey(const Key('badge-first_task')))
              .opacity,
          1);
      expect(
          tester
              .widget<Opacity>(find.byKey(const Key('badge-recycler')))
              .opacity,
          0.4);
    });
  });

  group('SuggestionsPanel', () {
    testWidgets('renders tips and impact', (tester) async {
      await tester.pumpWidget(host(const SuggestionsPanel(suggestions: [
        Suggestion(
            category: 'waste',
            tip: 'Start composting.',
            impact: 'Save ~0.5 kg CO2',
            icon: '♻️')
      ])));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Smart Suggestions 💡'), findsOneWidget);
      expect(find.text('Start composting.'), findsOneWidget);
      expect(find.text('Save ~0.5 kg CO2'), findsOneWidget);
    });

    testWidgets('renders nothing when empty', (tester) async {
      await tester.pumpWidget(host(const SuggestionsPanel(suggestions: [])));
      expect(find.text('Smart Suggestions 💡'), findsNothing);
    });
  });

  group('CarbonPill', () {
    testWidgets('emission vs saving formatting', (tester) async {
      await tester.pumpWidget(host(const Column(children: [
        CarbonPill(value: 3.784, large: true),
        CarbonPill(value: -0.16)
      ])));
      expect(find.textContaining('+3.78'), findsOneWidget);
      expect(find.text('−0.16 kg'), findsOneWidget);
    });
  });

  group('charts', () {
    testWidgets('weekly trend renders a line chart', (tester) async {
      final points = [
        for (var i = 0; i < 7; i++)
          TrendPoint(
              date: '2026-10-${16 + i}',
              day: ['Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu'][i],
              carbon: i == 6 ? 15.6 : (i == 5 ? -1.18 : 0))
      ];
      await tester.pumpWidget(host(WeeklyTrendChart(points: points)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('weekly trend copes with all-zero data', (tester) async {
      final points = [
        for (var i = 0; i < 7; i++)
          TrendPoint(date: 'd$i', day: 'D$i', carbon: 0)
      ];
      await tester.pumpWidget(host(WeeklyTrendChart(points: points)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('category chart shows legend; empty state otherwise',
        (tester) async {
      await tester.pumpWidget(host(const CategoryPieChart(data: [
        CategoryStat(
            category: 'food', totalCarbon: 13.5, count: 1, percentage: 59.6),
        CategoryStat(
            category: 'waste', totalCarbon: -2, count: 1, percentage: -8.8),
      ])));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PieChart), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Waste'), findsOneWidget);

      await tester.pumpWidget(host(const CategoryPieChart(data: [])));
      expect(find.text('Add tasks across categories to see breakdown'),
          findsOneWidget);
    });
  });

  group('TaskCard', () {
    testWidgets('shows details and forwards taps', (tester) async {
      final calls = <String>[];
      final task = fakeTask(description: 'Took the car');
      await tester.pumpWidget(host(TaskCard(
          task: task,
          index: 0,
          onToggle: (_) => calls.add('toggle'),
          onEdit: (_) => calls.add('edit'),
          onDelete: (_) => calls.add('delete'))));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Morning commute'), findsOneWidget);
      expect(find.text('🚗 Transport'), findsOneWidget);
      expect(find.text('2026-10-22'), findsOneWidget);
      expect(find.text('10 km'), findsOneWidget);
      expect(find.text('Took the car'), findsOneWidget);
      expect(find.textContaining('+2.10'), findsOneWidget);

      await tester.tap(find.byKey(const Key('task-toggle')));
      await tester.tap(find.text('✏️ Edit'));
      await tester.tap(find.text('🗑 Delete'));
      expect(calls, ['toggle', 'edit', 'delete']);
    });

    testWidgets('completed task is struck through; savings are labelled',
        (tester) async {
      await tester.pumpWidget(host(TaskCard(
          task:
              fakeTask(completed: true, carbon: -0.16, subcategory: 'cycling'),
          index: 0,
          onToggle: (_) {},
          onEdit: (_) {},
          onDelete: (_) {})));
      await tester.pump(const Duration(seconds: 1));
      expect(
          tester.widget<Text>(find.text('Morning commute')).style?.decoration,
          TextDecoration.lineThrough);
      expect(find.text('saved'), findsOneWidget);
      expect(find.textContaining('−0.16'), findsOneWidget);
    });
  });

  group('TaskFormSheet', () {
    Future<void> openSheet(
        WidgetTester tester, Future<OpResult> Function(TaskInput) onSave,
        {bool edit = false}) async {
      useBigScreen(tester);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showTaskFormSheet(context,
                    editTask: edit
                        ? fakeTask(
                            title: 'Old title',
                            quantity: 18,
                            subcategory: 'car_diesel',
                            unit: 'miles')
                        : null,
                    onSave: onSave),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('new activity: defaults, no preview until a type is chosen',
        (tester) async {
      await openSheet(tester, (_) async => const OpResult.ok());
      expect(find.text('Log Activity'), findsOneWidget);
      expect(find.text('Track your carbon impact'), findsOneWidget);
      expect(find.byKey(const Key('impact-preview')), findsNothing);
    });

    testWidgets(
        'choosing a category selects its first type and previews the impact',
        (tester) async {
      await openSheet(tester, (_) async => const OpResult.ok());
      await tester.tap(find.byKey(const Key('category-food')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('impact-preview')), findsOneWidget);
      expect(find.textContaining('+27 kg CO₂'), findsOneWidget);
      expect(find.textContaining('emitted'), findsOneWidget);

      // Quantity 2 doubles the estimate.
      await tester.enterText(find.byType(TextFormField).at(1), '2');
      await tester.pumpAndSettle();
      expect(find.textContaining('+54 kg CO₂'), findsOneWidget);
    });

    testWidgets('saving types preview a negative impact', (tester) async {
      await openSheet(tester, (_) async => const OpResult.ok());
      await tester.tap(find.byKey(const Key('category-other')));
      await tester.pumpAndSettle();
      expect(find.textContaining('−21.77 kg CO₂'), findsOneWidget);
      expect(find.textContaining('saved'), findsOneWidget);
    });

    testWidgets('empty title blocks saving', (tester) async {
      var saved = false;
      await openSheet(tester, (_) async {
        saved = true;
        return const OpResult.ok();
      });
      await tester.ensureVisible(find.text('🌱 Log Activity'));
      await tester.tap(find.text('🌱 Log Activity'));
      await tester.pumpAndSettle();
      expect(find.text('Activity title is required'), findsOneWidget);
      expect(saved, isFalse);
    });

    testWidgets('invalid quantity blocks saving', (tester) async {
      await openSheet(tester, (_) async => const OpResult.ok());
      await tester.enterText(find.byType(TextFormField).at(0), 'Ride');
      await tester.enterText(find.byType(TextFormField).at(1), '0');
      await tester.ensureVisible(find.text('🌱 Log Activity'));
      await tester.tap(find.text('🌱 Log Activity'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Quantity must be at least'), findsOneWidget);
    });

    testWidgets('valid form saves and closes', (tester) async {
      TaskInput? received;
      await openSheet(tester, (input) async {
        received = input;
        return const OpResult.ok('Activity logged! 🌱');
      });
      await tester.tap(find.byKey(const Key('category-food')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(TextFormField).at(0), '  Steak dinner ');
      await tester.enterText(find.byType(TextFormField).at(1), '0.4');
      await tester.ensureVisible(find.text('🌱 Log Activity'));
      await tester.tap(find.text('🌱 Log Activity'));
      await tester.pumpAndSettle();

      expect(received, isNotNull);
      expect(received!.title, 'Steak dinner');
      expect(received!.category, 'food');
      expect(received!.subcategory, 'beef');
      expect(received!.quantity, 0.4);
      expect(received!.unit, 'kg');
      expect(received!.date, AppDate.today());
      expect(find.text('Track your carbon impact'), findsNothing);
    });

    testWidgets('a failed save keeps the sheet open', (tester) async {
      await openSheet(
          tester, (_) async => const OpResult.fail('Failed to save'));
      await tester.enterText(find.byType(TextFormField).at(0), 'Ride');
      await tester.ensureVisible(find.text('🌱 Log Activity'));
      await tester.tap(find.text('🌱 Log Activity'));
      await tester.pumpAndSettle();
      expect(find.text('Track your carbon impact'), findsOneWidget);
    });

    testWidgets('edit mode is prefilled', (tester) async {
      await openSheet(tester, (_) async => const OpResult.ok(), edit: true);
      expect(find.text('Edit Activity'), findsOneWidget);
      expect(find.text('Old title'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('✏️ Update'), findsOneWidget);
      // Selecting a known type syncs the unit to the type's unit (km).
      expect(find.text('km'), findsWidgets);
    });
  });
}
