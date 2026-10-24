import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/dashboard/domain/models/dashboard_stats.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// The dashboard's two fl_chart area-style line charts: orders per day and
/// revenue per day across the selected window. Each chart is 180 tall; when
/// [chartData] is empty a 'Chưa có dữ liệu' placeholder replaces the chart.
class DashboardCharts extends StatelessWidget {
  const DashboardCharts({super.key, required this.chartData});

  final List<DashboardChartPoint> chartData;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChartCard(
          title: 'Số đơn theo ngày',
          spots: [
            for (var i = 0; i < chartData.length; i++)
              FlSpot(i.toDouble(), chartData[i].orders.toDouble()),
          ],
          lineColor: AppTheme.primaryPink,
        ),
        const Gap(AppSpacing.lg),
        _ChartCard(
          title: 'Doanh thu theo ngày',
          spots: [
            for (var i = 0; i < chartData.length; i++)
              FlSpot(i.toDouble(), chartData[i].revenue),
          ],
          lineColor: AppTheme.warmBrown,
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.spots,
    required this.lineColor,
  });

  final String title;
  final List<FlSpot> spots;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.inkBrown,
              ),
            ),
            const Gap(AppSpacing.md),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: spots.isEmpty
                  ? Center(
                      child: Text(
                        'Chưa có dữ liệu',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : LineChart(_chartData()),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _chartData() {
    // A flat series would collapse minY == maxY; give the axis headroom above
    // the max so the area fill stays visible (and a zero-only series is still
    // renderable).
    final maxY = spots.map((spot) => spot.y).reduce(math.max);
    final axisMax = maxY <= 0 ? 1.0 : maxY * 1.15;

    return LineChartData(
      minX: 0,
      // A single-point series needs a non-degenerate x range to draw on.
      maxX: math.max(spots.length - 1, 1).toDouble(),
      minY: 0,
      maxY: axisMax,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            const FlLine(color: AppTheme.chartGridLine, strokeWidth: 1),
      ),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 3,
          color: lineColor,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            // Area fill under the curve, fading out towards the x axis.
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                lineColor.withValues(alpha: 0.30),
                lineColor.withValues(alpha: 0.02),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
