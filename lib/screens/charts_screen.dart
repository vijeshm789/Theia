// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/metal_price_provider.dart';
import '../providers/prediction_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/metal_toggle.dart';
import '../widgets/price_chart.dart';
import '../widgets/shimmer_loading.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer2<MetalPriceProvider, PredictionProvider>(
          builder: (context, priceProvider, predProvider, _) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Price Charts',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Historical trends & forecast overlay',
                          style: TextStyle(
                            color: AppTheme.textMuted.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Metal toggle
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Center(
                      child: MetalToggle(
                        selected: priceProvider.selectedMetal,
                        onChanged: (metal) {
                          priceProvider.setSelectedMetal(metal);
                          predProvider.setSelectedMetal(metal);
                        },
                      ),
                    ),
                  ),
                ),

                // Current price summary
                SliverToBoxAdapter(
                  child: _buildPriceSummary(priceProvider),
                ),

                // Main chart
                SliverToBoxAdapter(
                  child: _buildMainChart(priceProvider, predProvider),
                ),

                // Time range selector
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: TimeRangeSelector(
                      selected: priceProvider.selectedTimeRange,
                      onChanged: priceProvider.setTimeRange,
                    ),
                  ),
                ),

                // Chart stats
                SliverToBoxAdapter(
                  child: _buildChartStats(priceProvider),
                ),

                // Forecast toggle
                SliverToBoxAdapter(
                  child: _buildForecastSection(priceProvider, predProvider),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPriceSummary(MetalPriceProvider provider) {
    final isGold = provider.selectedMetal == 'Gold';
    final price = isGold ? provider.gold24k : provider.silverPerGram;
    final accentColor =
        isGold ? AppTheme.primaryGold : AppTheme.secondarySilver;

    if (price == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: ShimmerLoading(height: 60),
      );
    }

    final changeColor =
        price.isProfit ? AppTheme.profitGreen : AppTheme.lossRed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatters.formatCurrency(price.price),
            style: TextStyle(
              color: accentColor,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '/${price.unit}',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.formatPriceChange(price.dailyChange),
                style: TextStyle(
                  color: changeColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                Formatters.formatPercentChange(price.percentChange),
                style: TextStyle(
                  color: changeColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainChart(
    MetalPriceProvider priceProvider,
    PredictionProvider predProvider,
  ) {
    final history = priceProvider.currentHistory;
    if (priceProvider.isHistoryLoading && history == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: ShimmerLoading(height: 280),
      );
    }
    if (history == null || history.prices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: SizedBox(
          height: 280,
          child: Center(
            child: Text(
              'No data available',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
        ),
      );
    }

    final isGold = priceProvider.selectedMetal == 'Gold';
    final prediction = predProvider.currentPrediction;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 20, 0),
      child: PriceChartWidget(
        historicalData: history.prices,
        forecastData: prediction?.forecastPoints,
        isGold: isGold,
        height: 280,
        showGrid: true,
        showLabels: true,
        interactive: true,
      ),
    );
  }

  Widget _buildChartStats(MetalPriceProvider provider) {
    final history = provider.currentHistory;
    if (history == null || history.prices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _StatItem(
              label: 'High',
              value: Formatters.formatCurrency(history.highestPrice),
              color: AppTheme.profitGreen,
            ),
            Container(
              width: 1,
              height: 30,
              color: AppTheme.dividerColor,
            ),
            _StatItem(
              label: 'Low',
              value: Formatters.formatCurrency(history.lowestPrice),
              color: AppTheme.lossRed,
            ),
            Container(
              width: 1,
              height: 30,
              color: AppTheme.dividerColor,
            ),
            _StatItem(
              label: 'Latest',
              value: Formatters.formatCurrency(history.latestPrice),
              color: AppTheme.textPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastSection(
    MetalPriceProvider priceProvider,
    PredictionProvider predProvider,
  ) {
    final prediction = predProvider.currentPrediction;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome,
                      color: Colors.orangeAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Forecast Overlay',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (prediction != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 2,
                        color: Colors.orangeAccent,
                        margin: const EdgeInsets.only(right: 6),
                      ),
                      Container(
                        width: 8,
                        height: 2,
                        color: Colors.orangeAccent,
                        margin: const EdgeInsets.only(right: 6),
                      ),
                      const Text(
                        'Predicted',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          PredictionWindowSelector(
            selected: predProvider.selectedWindow,
            onChanged: (window) {
              predProvider.setWindow(
                window,
                goldPrice: priceProvider.gold24k?.price ?? 0,
                silverPrice: priceProvider.silverPerGram?.price ?? 0,
              );
            },
          ),
          if (prediction != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.orangeAccent.withOpacity(0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      prediction.summary,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
