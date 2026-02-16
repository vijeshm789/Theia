// ignore_for_file: deprecated_member_use

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/metal_price.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class PriceChartWidget extends StatelessWidget {
  final List<PricePoint> historicalData;
  final List<PricePoint>? forecastData;
  final bool isGold;
  final double? height;
  final bool showGrid;
  final bool showLabels;
  final bool interactive;

  const PriceChartWidget({
    super.key,
    required this.historicalData,
    this.forecastData,
    this.isGold = true,
    this.height = 250,
    this.showGrid = true,
    this.showLabels = true,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    if (historicalData.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'No chart data available',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }

    final accentColor =
        isGold ? AppTheme.primaryGold : AppTheme.secondarySilver;

    // Build historical spots
    final historicalSpots = <FlSpot>[];
    for (int i = 0; i < historicalData.length; i++) {
      historicalSpots.add(FlSpot(i.toDouble(), historicalData[i].price));
    }

    // Build forecast spots if available
    final forecastSpots = <FlSpot>[];
    if (forecastData != null && forecastData!.isNotEmpty) {
      // Start forecast from the last historical point
      forecastSpots.add(FlSpot(
        (historicalData.length - 1).toDouble(),
        historicalData.last.price,
      ));
      for (int i = 0; i < forecastData!.length; i++) {
        forecastSpots.add(FlSpot(
          (historicalData.length + i).toDouble(),
          forecastData![i].price,
        ));
      }
    }

    // Calculate bounds
    final allPrices = [
      ...historicalData.map((p) => p.price),
      if (forecastData != null) ...forecastData!.map((p) => p.price),
    ];
    final minPrice = allPrices.reduce((a, b) => a < b ? a : b);
    final maxPrice = allPrices.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    final padding = priceRange * 0.1;

    final totalPoints = historicalData.length +
        (forecastData != null ? forecastData!.length : 0);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: showGrid,
            drawVerticalLine: false,
            horizontalInterval: priceRange > 0 ? priceRange / 4 : 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.dividerColor.withOpacity(0.3),
                strokeWidth: 0.5,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: showLabels,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showLabels,
                reservedSize: 30,
                interval:
                    (totalPoints / 5).ceilToDouble().clamp(1, double.infinity),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= historicalData.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      Formatters.formatChartDate(historicalData[index].date),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showLabels,
                reservedSize: 55,
                interval: priceRange > 0 ? priceRange / 4 : 1,
                getTitlesWidget: (value, meta) {
                  return Text(
                    Formatters.formatNumber(value),
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (totalPoints - 1).toDouble(),
          minY: minPrice - padding,
          maxY: maxPrice + padding,
          lineTouchData: LineTouchData(
            enabled: interactive,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppTheme.cardColorLight,
              tooltipBorder: BorderSide(
                color: accentColor.withOpacity(0.3),
              ),
              tooltipRoundedRadius: 12,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final isForecast = spot.x >= historicalData.length;
                  return LineTooltipItem(
                    '\$${spot.y.toStringAsFixed(2)}',
                    TextStyle(
                      color: isForecast ? Colors.orangeAccent : accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: isForecast ? '\n(forecast)' : '',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            // Historical line
            LineChartBarData(
              spots: historicalSpots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: accentColor,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accentColor.withOpacity(0.25),
                    accentColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
            // Forecast line (dashed)
            if (forecastSpots.isNotEmpty)
              LineChartBarData(
                spots: forecastSpots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: Colors.orangeAccent,
                barWidth: 2,
                isStrokeCapRound: true,
                dashArray: [8, 4],
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.orangeAccent.withOpacity(0.1),
                      Colors.orangeAccent.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }
}

class MiniSparkline extends StatelessWidget {
  final List<PricePoint> data;
  final bool isGold;
  final double height;
  final double width;

  const MiniSparkline({
    super.key,
    required this.data,
    this.isGold = true,
    this.height = 40,
    this.width = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height, width: width);

    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].price));
    }

    final isUp = data.last.price >= data.first.price;
    final color = isUp ? AppTheme.profitGreen : AppTheme.lossRed;

    return SizedBox(
      height: height,
      width: width,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: color,
              barWidth: 1.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}
