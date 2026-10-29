import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_date.dart';
import '../core/constants.dart';
import '../core/number_format.dart';
import '../models/dashboard_data.dart';
import '../models/task.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../widgets/badge_grid.dart';
import '../widgets/carbon_pill.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/eco_button.dart';
import '../widgets/eco_score_ring.dart';
import '../widgets/entrance.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/states.dart';
import '../widgets/suggestions_panel.dart';
import '../widgets/weekly_trend_chart.dart';

/// Dashboard (DashboardPage.jsx). Data is (re)loaded each time the screen is
/// opened and on pull-to-refresh.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final data = provider.data;

    Widget body;
    if (data == null) {
      body = provider.error != null
          ? Padding(
              padding: AppSpacing.page,
              child:
                  ErrorState(message: provider.error!, onRetry: provider.load),
            )
          : const LoadingView(message: 'Loading your eco data...');
    } else {
      body = _DashboardContent(data: data);
    }

    return RefreshIndicator(
      color: AppColors.forest600,
      onRefresh: provider.load,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final user = data.user;
    final level = user.levelData;
    final change = data.weekChange;

    return Padding(
      padding: AppSpacing.page,
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 768;
          final xwide = c.maxWidth >= 1024;

          final statCards = [
            StatCard(
              icon: '📅',
              label: "Today's Emissions",
              value: data.todayCarbon.toStringAsFixed(2),
              unit: 'kg CO₂',
              tone: StatTone.forest,
              delay: const Duration(milliseconds: 100),
            ),
            StatCard(
              icon: '📆',
              label: 'This Week',
              value: data.weeklyCarbon.toStringAsFixed(2),
              unit: 'kg CO₂',
              sub: change != 0
                  ? '${change > 0 ? '+' : ''}${JsNumber.toJsString(change)}% vs last week'
                  : 'No previous data',
              tone: change < 0 ? StatTone.forest : StatTone.earth,
              delay: const Duration(milliseconds: 200),
            ),
            StatCard(
              icon: '🗓️',
              label: 'This Month',
              value: data.monthlyCarbon.toStringAsFixed(2),
              unit: 'kg CO₂',
              sub: 'Last 30 days',
              tone: StatTone.sage,
              delay: const Duration(milliseconds: 300),
            ),
          ];

          final scoreCard = GlassCard(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  EcoScoreRing(score: user.totalEcoScore, level: level),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🔥 ${user.streak}',
                          key: const Key('streak-value'),
                          style: AppText.bodyStyle(14,
                              weight: FontWeight.w600,
                              color: AppColors.orange500)),
                      const SizedBox(width: 8),
                      Text('day streak', style: AppText.small),
                    ],
                  ),
                ],
              ),
            ),
          );

          final trendCard = GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('7-Day Carbon Trend', style: AppText.sectionTitle),
                const SizedBox(height: 16),
                WeeklyTrendChart(points: data.weeklyTrend),
              ],
            ),
          );

          final categoryCard = GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('By Category', style: AppText.sectionTitle),
                const SizedBox(height: 16),
                CategoryPieChart(data: data.categoryData),
              ],
            ),
          );

          final suggestionsCard = GlassCard(
              child: SizedBox(
                  width: double.infinity,
                  child: SuggestionsPanel(suggestions: data.suggestions)));
          final badgesCard =
              GlassCard(child: BadgeGrid(earnedBadges: user.badges));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(name: user.firstName, emoji: level.emoji),
              const SizedBox(height: 24),
              if (change != 0) ...[
                _InsightBanner(change: change),
                const SizedBox(height: 24),
              ],
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: scoreCard),
                    const SizedBox(width: 16),
                    for (var i = 0; i < statCards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 16),
                      Expanded(child: statCards[i]),
                    ],
                  ],
                )
              else ...[
                scoreCard,
                for (final s in statCards) ...[const SizedBox(height: 16), s],
              ],
              const SizedBox(height: 24),
              if (xwide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: trendCard),
                    const SizedBox(width: 16),
                    Expanded(child: categoryCard),
                  ],
                )
              else ...[
                trendCard,
                const SizedBox(height: 16),
                categoryCard,
              ],
              const SizedBox(height: 24),
              if (xwide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: suggestionsCard),
                    const SizedBox(width: 16),
                    Expanded(child: badgesCard),
                  ],
                )
              else ...[
                suggestionsCard,
                const SizedBox(height: 16),
                badgesCard,
              ],
              if (data.recentTasks.isNotEmpty) ...[
                const SizedBox(height: 24),
                _RecentActivities(tasks: data.recentTasks),
              ],
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.emoji});

  final String name;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, $name $emoji', style: AppText.pageTitle),
              const SizedBox(height: 4),
              Text(DateFormat('EEEE, MMMM d', 'en_US').format(AppDate.now()),
                  style: AppText.subtitle),
            ],
          ),
        ),
        const SizedBox(width: 12),
        EcoButton(
          label: '+ Log Activity',
          expand: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onPressed: () => context.go('/tasks'),
        ),
      ],
    );
  }
}

class _InsightBanner extends StatelessWidget {
  const _InsightBanner({required this.change});

  final double change;

  @override
  Widget build(BuildContext context) {
    final down = change < 0;
    final fg = down ? AppColors.forest800 : AppColors.earth800;
    final style =
        AppText.bodyStyle(14, weight: FontWeight.w500, color: fg, height: 1.43);
    return Entrance(
      offset: const Offset(0, -10),
      child: Container(
        key: const Key('insight-banner'),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: down ? AppColors.forest100 : AppColors.earth50,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
              color: down ? AppColors.forest200 : AppColors.earth200),
        ),
        child: Row(
          children: [
            Text(down ? '📉' : '📈', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: style,
                  children: [
                    TextSpan(
                        text:
                            'You ${down ? 'reduced' : 'increased'} your emissions by '),
                    TextSpan(
                        text: '${JsNumber.toJsString(change.abs())}%',
                        style: style.copyWith(fontWeight: FontWeight.w700)),
                    TextSpan(
                        text:
                            ' compared to last week. ${down ? 'Great work! Keep it up 🌿' : 'Try logging eco-friendly activities!'}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivities extends StatelessWidget {
  const _RecentActivities({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Activities', style: AppText.sectionTitle),
              InkWell(
                onTap: () => context.go('/tasks'),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text('View all →',
                      style: AppText.bodyStyle(12,
                          weight: FontWeight.w500, color: AppColors.forest600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final task in tasks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Row(
                children: [
                  Text(AppConstants.categoryMeta(task.category).emoji,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodyStyle(14,
                                weight: FontWeight.w500,
                                color: AppColors.forest900)),
                        Text(
                            '${task.date} · ${AppConstants.categoryMeta(task.category).label}',
                            style: AppText.small),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  CarbonPill(value: task.carbonValue),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
