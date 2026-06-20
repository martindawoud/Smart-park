// lib/widgets/occupancy_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_theme.dart';

class OccupancyChart extends StatelessWidget {
  final int available;
  final int occupied;
  final int total;

  const OccupancyChart({
    super.key,
    required this.available,
    required this.occupied,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 3,
              centerSpaceRadius: 38,
              sections: [
                if (available > 0)
                  PieChartSectionData(
                    value: available.toDouble(),
                    color: AppColors.slotVacantFg,
                    title: '',
                    radius: 22,
                  ),
                if (occupied > 0)
                  PieChartSectionData(
                    value: occupied.toDouble(),
                    color: AppColors.slotOccupiedFg,
                    title: '',
                    radius: 22,
                  ),
                if (available == 0 && occupied == 0)
                  PieChartSectionData(
                    value: 1,
                    color: Colors.grey.shade300,
                    title: '',
                    radius: 22,
                  ),
              ],
            ),
            swapAnimationDuration: const Duration(milliseconds: 600),
            swapAnimationCurve: Curves.easeInOut,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$available',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'of $total',
                style: const TextStyle(fontSize: 11, color: Color(0xFF546E7A)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
