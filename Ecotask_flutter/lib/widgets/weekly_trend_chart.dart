import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/chart_scale.dart';
import '../core/number_format.dart';
import '../models/dashboard_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// 7-day carbon trend (Recharts AreaChart -> fl_chart LineChart with gradient
/// area, monotone curve, 3px dots and a tooltip).
class WeeklyTrendChart extends StatelessWidget {
  const WeeklyTrendChart({super.key, required this.points, this.height = 200});

  final List<TrendPoint> points;
  final double height;

  static FlLine _dashed(double _) => const FlLine(
      color: AppColors.forest50, strokeWidth: 1, dashArray: [3, 3]);

  @override
  Widget build(BuildContext context) {
    final values = points.map((p) => p.carbon).toList();
    final scale = niceScale(
      values.reduce((a, b) => a < b ? a : b),
      values.reduce((a, b) => a > b ? a : b),
    );
    final labelStyle = AppText.bodyStyle(11, color: AppColors.sage500);

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, right: 8),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (points.length - 1).toDouble(),
            minY: scale.min,
            maxY: scale.max,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              horizontalInterval: scale.interval,
              verticalInterval: 1,
              getDrawingHorizontalLine: _dashed,
              getDrawingVerticalLine: _dashed,
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= points.length || value != i.toDouble()) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(points[i].day, style: labelStyle),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: scale.interval,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(JsNumber.toJsString(JsNumber.round(value, 2)),
                        style: labelStyle),
                  ),
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => Colors.white,
                getTooltipItems: (spots) => spots.map((s) {
                  final p = points[s.x.toInt()];
                  return LineTooltipItem(
                    '${p.day}\n',
                    AppText.bodyStyle(12,
                        weight: FontWeight.w600, color: AppColors.forest800),
                    children: [
                      TextSpan(
                        text: '${JsNumber.toJsString(p.carbon)} kg CO₂',
                        style: AppText.bodyStyle(12, color: AppColors.sage600),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < points.length; i++)
                    FlSpot(i.toDouble(), points[i].carbon)
                ],
                isCurved: true,
                preventCurveOverShooting: true,
                color: AppColors.forest600,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 3,
                    color: AppColors.forest600,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  applyCutOffY: true,
                  cutOffY: 0,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.forest600.withAlpha(77),
                      AppColors.forest600.withAlpha(5)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
