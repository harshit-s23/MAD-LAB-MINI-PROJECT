import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/number_format.dart';
import '../models/dashboard_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'category_colors.dart';

/// Category donut (Recharts PieChart: inner radius 50, outer 75, 3px padding).
///
/// Slices are sized by the absolute value of each category's net carbon so a
/// net-negative (saving) category still renders; the legend lists the
/// category names in their own colours, as Recharts does.
class CategoryPieChart extends StatefulWidget {
  const CategoryPieChart({super.key, required this.data});

  final List<CategoryStat> data;

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final slices =
        widget.data.where((d) => d.totalCarbon != 0).toList(growable: false);
    if (slices.isEmpty) {
      return SizedBox(
        height: 192,
        child: Center(
          child: Text('Add tasks across categories to see breakdown',
              textAlign: TextAlign.center,
              style: AppText.bodyStyle(14, color: AppColors.sage400)),
        ),
      );
    }
    final touched =
        (_touched >= 0 && _touched < slices.length) ? slices[_touched] : null;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 50,
                  startDegreeOffset: -90,
                  borderData: FlBorderData(show: false),
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      final idx =
                          response?.touchedSection?.touchedSectionIndex ?? -1;
                      final next = event.isInterestedForInteractions ? idx : -1;
                      if (next != _touched) setState(() => _touched = next);
                    },
                  ),
                  sections: [
                    for (var i = 0; i < slices.length; i++)
                      PieChartSectionData(
                        value: slices[i].totalCarbon.abs(),
                        color:
                            AppConstants.categoryMeta(slices[i].category).color,
                        radius: i == _touched ? 29 : 25,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              if (touched != null)
                IgnorePointer(
                  child: SizedBox(
                    width: 90,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppConstants.categoryMeta(touched.category).label,
                            style: AppText.bodyStyle(11,
                                weight: FontWeight.w600,
                                color: AppColors.forest800)),
                        Text(
                            '${JsNumber.toJsString(touched.totalCarbon)} kg CO₂',
                            textAlign: TextAlign.center,
                            style: AppText.bodyStyle(11,
                                color: AppColors.sage600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 4,
          children: [
            for (final s in slices)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: AppConstants.categoryMeta(s.category).color,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(AppConstants.categoryMeta(s.category).label,
                      style: AppText.bodyStyle(11,
                          color: AppConstants.categoryMeta(s.category).color)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
