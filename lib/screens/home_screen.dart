// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/metal_price_provider.dart';
import '../providers/prediction_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/price_card.dart';
import '../widgets/price_chart.dart';
import '../widgets/prediction_card.dart';
import '../widgets/shimmer_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MetalPriceProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer<MetalPriceProvider>(
          builder: (context, priceProvider, _) {
            return RefreshIndicator(
              onRefresh: priceProvider.refresh,
              color: AppTheme.primaryGold,
              backgroundColor: AppTheme.cardColor,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // App bar
                  SliverToBoxAdapter(
                    child: _buildHeader(priceProvider),
                  ),
                  // Live rates section
                  SliverToBoxAdapter(
                    child: _buildSectionTitle('Live Rates'),
                  ),
                  SliverToBoxAdapter(
                    child:
                        priceProvider.isLoading && priceProvider.prices.isEmpty
                            ? _buildLoadingPrices()
                            : _buildPriceCards(priceProvider),
                  ),
                  // Quick chart
                  SliverToBoxAdapter(
                    child: _buildSectionTitle('Quick Chart'),
                  ),
                  SliverToBoxAdapter(
                    child: _buildQuickChart(priceProvider),
                  ),
                  // AI Prediction highlight
                  SliverToBoxAdapter(
                    child: _buildSectionTitle('AI Prediction'),
                  ),
                  SliverToBoxAdapter(
                    child: _buildPredictionHighlight(priceProvider),
                  ),
                  // Disclaimer
                  const SliverToBoxAdapter(
                    child: _DisclaimerBanner(),
                  ),
                  // Bottom spacing
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(MetalPriceProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  color: AppTheme.primaryGold,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppConstants.appTagline,
                style: TextStyle(
                  color: AppTheme.textMuted.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          // if (provider.lastUpdated != null)
          //   Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          //     decoration: BoxDecoration(
          //       color: AppTheme.surface,
          //       borderRadius: BorderRadius.circular(10),
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Icon(
          //           Icons.access_time,
          //           color: AppTheme.textMuted.withOpacity(0.7),
          //           size: 13,
          //         ),
          //         const SizedBox(width: 4),
          //         Text(
          //           Formatters.formatTime(provider.lastUpdated!),
          //           style: TextStyle(
          //             color: AppTheme.textMuted.withOpacity(0.8),
          //             fontSize: 11,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoadingPrices() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: ShimmerPriceCard()),
              SizedBox(width: 12),
              Expanded(child: ShimmerPriceCard()),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ShimmerPriceCard()),
              SizedBox(width: 12),
              Expanded(child: ShimmerPriceCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCards(MetalPriceProvider provider) {
    if (provider.error != null && provider.prices.isEmpty) {
      return _buildErrorWidget(provider.error!);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Gold row
          Row(
            children: [
              Expanded(
                child: provider.gold24k != null
                    ? PriceCard(price: provider.gold24k!, isGold: true)
                    : const ShimmerPriceCard(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: provider.gold22k != null
                    ? PriceCard(price: provider.gold22k!, isGold: true)
                    : const ShimmerPriceCard(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Silver row
          Row(
            children: [
              Expanded(
                child: provider.silverPerGram != null
                    ? PriceCard(price: provider.silverPerGram!, isGold: false)
                    : const ShimmerPriceCard(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: provider.silverPerKg != null
                    ? PriceCard(price: provider.silverPerKg!, isGold: false)
                    : const ShimmerPriceCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChart(MetalPriceProvider provider) {
    final history = provider.goldHistory;
    if (provider.isHistoryLoading && history == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: ShimmerLoading(height: 180),
      );
    }
    if (history == null || history.prices.isEmpty) {
      return const SizedBox.shrink();
    }

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
                Text(
                  'Gold — ${provider.selectedTimeRange}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  Formatters.formatCurrency(history.latestPrice),
                  style: const TextStyle(
                    color: AppTheme.primaryGold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PriceChartWidget(
              historicalData: history.prices,
              isGold: true,
              height: 160,
              showLabels: false,
              showGrid: false,
              interactive: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionHighlight(MetalPriceProvider priceProvider) {
    return Consumer<PredictionProvider>(
      builder: (context, predProvider, _) {
        // Auto-fetch predictions when price data is available
        if (predProvider.goldPrediction == null &&
            !predProvider.isLoading &&
            priceProvider.gold24k != null &&
            priceProvider.silverPerGram != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            predProvider.fetchPredictions(
              goldPrice: priceProvider.gold24k!.price,
              silverPrice: priceProvider.silverPerGram!.price,
              goldHistory: priceProvider.goldHistory?.prices,
              silverHistory: priceProvider.silverHistory?.prices,
            );
          });
        }

        if (predProvider.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ShimmerLoading(height: 200),
          );
        }

        final prediction = predProvider.goldPrediction;
        if (prediction == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: PredictionCard(prediction: prediction),
        );
      },
    );
  }

  Widget _buildErrorWidget(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off,
              color: AppTheme.textMuted,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}
