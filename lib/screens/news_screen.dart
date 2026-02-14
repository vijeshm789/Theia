import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/news_card.dart';
import '../widgets/shimmer_loading.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().fetchNews();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NewsProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer<NewsProvider>(
          builder: (context, newsProvider, _) {
            return RefreshIndicator(
              onRefresh: newsProvider.refresh,
              color: AppTheme.primaryGold,
              backgroundColor: AppTheme.cardColor,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Market News',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Latest precious metals & commodity news',
                            style: TextStyle(
                              color: AppTheme.textMuted.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  if (newsProvider.isLoading && newsProvider.articles.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const ShimmerNewsCard(),
                          childCount: 4,
                        ),
                      ),
                    )
                  else if (newsProvider.error != null &&
                      newsProvider.articles.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildError(newsProvider.error!),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= newsProvider.articles.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primaryGold,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            return NewsCard(
                              article: newsProvider.articles[index],
                            );
                          },
                          childCount: newsProvider.articles.length +
                              (newsProvider.hasMore ? 1 : 0),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.newspaper,
            color: AppTheme.textMuted.withOpacity(0.5),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => context.read<NewsProvider>().fetchNews(),
            child: const Text(
              'Retry',
              style: TextStyle(
                color: AppTheme.primaryGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
