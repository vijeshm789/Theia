// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prediction.dart';
import '../providers/metal_price_provider.dart';
import '../providers/prediction_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/metal_toggle.dart';
import '../widgets/prediction_card.dart';
import '../widgets/price_chart.dart';
import '../widgets/shimmer_loading.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPredictionsIfNeeded();
    });
  }

  void _fetchPredictionsIfNeeded() {
    final priceProvider = context.read<MetalPriceProvider>();
    final predProvider = context.read<PredictionProvider>();

    if (predProvider.goldPrediction == null &&
        !predProvider.isLoading &&
        priceProvider.gold24k != null &&
        priceProvider.silverPerGram != null) {
      predProvider.fetchPredictions(
        goldPrice: priceProvider.gold24k!.price,
        silverPrice: priceProvider.silverPerGram!.price,
        goldHistory: priceProvider.goldHistory?.prices,
        silverHistory: priceProvider.silverHistory?.prices,
      );
    }
  }

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
                        const Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: AppTheme.primaryGold,
                              size: 24,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'AI Insights',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'AI-powered price predictions & market analysis',
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
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Center(
                      child: MetalToggle(
                        selected: predProvider.selectedMetal,
                        onChanged: (metal) {
                          predProvider.setSelectedMetal(metal);
                        },
                      ),
                    ),
                  ),
                ),

                // Prediction window selector
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: PredictionWindowSelector(
                      selected: predProvider.selectedWindow,
                      onChanged: (window) {
                        predProvider.setWindow(
                          window,
                          goldPrice: priceProvider.gold24k?.price ?? 0,
                          silverPrice: priceProvider.silverPerGram?.price ?? 0,
                        );
                      },
                    ),
                  ),
                ),

                // Prediction card
                SliverToBoxAdapter(
                  child: _buildPredictionSection(predProvider),
                ),

                // Forecast chart
                SliverToBoxAdapter(
                  child: _buildForecastChart(priceProvider, predProvider),
                ),

                // Market trend insights
                SliverToBoxAdapter(
                  child: _buildMarketInsights(predProvider),
                ),

                // Disclaimer
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.stableYellow.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.stableYellow.withOpacity(0.6),
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              AppConstants.predictionDisclaimer,
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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

  Widget _buildPredictionSection(PredictionProvider provider) {
    if (provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: ShimmerLoading(height: 250),
      );
    }

    final prediction = provider.currentPrediction;
    if (prediction == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppTheme.textMuted.withOpacity(0.5),
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                'Predictions will appear once price data loads.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: PredictionCard(prediction: prediction),
    );
  }

  Widget _buildForecastChart(
    MetalPriceProvider priceProvider,
    PredictionProvider predProvider,
  ) {
    final history = priceProvider.currentHistory;
    final prediction = predProvider.currentPrediction;

    if (history == null || history.prices.isEmpty) {
      return const SizedBox.shrink();
    }

    final isGold = predProvider.selectedMetal == AppConstants.gold;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Historical vs Predicted',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 2,
                      color: isGold
                          ? AppTheme.primaryGold
                          : AppTheme.secondarySilver,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Actual',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 6,
                      height: 2,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 6,
                      height: 2,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Forecast',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            PriceChartWidget(
              historicalData: history.prices,
              forecastData: prediction?.forecastPoints,
              isGold: isGold,
              height: 220,
              showGrid: true,
              showLabels: true,
              interactive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketInsights(PredictionProvider provider) {
    final prediction = provider.currentPrediction;
    if (prediction == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Market Trend Insights',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _InsightTile(
            icon: Icons.trending_up,
            title: 'Price Momentum',
            value: prediction.trendLabel,
            color: prediction.trend == TrendDirection.uptrend
                ? AppTheme.profitGreen
                : prediction.trend == TrendDirection.downtrend
                    ? AppTheme.lossRed
                    : AppTheme.stableYellow,
          ),
          const SizedBox(height: 10),
          _InsightTile(
            icon: Icons.speed,
            title: 'Confidence',
            value: '${(prediction.confidenceLevel * 100).round()}%',
            color: prediction.confidenceLevel >= 0.7
                ? AppTheme.profitGreen
                : prediction.confidenceLevel >= 0.5
                    ? AppTheme.stableYellow
                    : AppTheme.lossRed,
          ),
          const SizedBox(height: 10),
          _InsightTile(
            icon: Icons.show_chart,
            title: 'Expected Change',
            value: Formatters.formatPercentChange(prediction.percentChange),
            color: prediction.percentChange >= 0
                ? AppTheme.profitGreen
                : AppTheme.lossRed,
          ),
          const SizedBox(height: 10),
          _InsightTile(
            icon: Icons.schedule,
            title: 'Forecast Window',
            value: prediction.window,
            color: AppTheme.primaryGold,
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InsightTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
