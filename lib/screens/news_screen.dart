import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../services/news_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsArticle> cryptoNews = [];
  List<NewsArticle> forexNews = [];
  List<NewsArticle> futuresNews = [];
  List<EconomicEvent> economicEvents = [];

  // filter-related state for forex calendar
  List<String> availableCountries = ['All'];
  String countryFilter = 'All';
  String impactFilter = 'All';

  NewsCategory selectedCategory = NewsCategory.crypto;
  bool isLoading = false;
  String? errorMessage;
  DateTime? lastUpdated;

  @override
  void initState() {
    super.initState();
    fetchAllNews();
  }

  Future<void> fetchAllNews() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Fetch news from all categories in parallel
      // Economic calendar will fetch all countries/impacts, UI filters client-side
      final results = await Future.wait([
        NewsService.fetchMarketNews(category: NewsCategory.crypto),
        NewsService.fetchMarketNews(category: NewsCategory.forex),
        NewsService.fetchMarketNews(category: NewsCategory.futures),
        NewsService.fetchEconomicCalendar(),
      ]);

      if (mounted) {
        setState(() {
          cryptoNews = results[0] as List<NewsArticle>;
          forexNews = results[1] as List<NewsArticle>;
          futuresNews = results[2] as List<NewsArticle>;
          economicEvents = results[3] as List<EconomicEvent>;

          // update list of countries for selector
          final countries = economicEvents
              .map((e) => e.country)
              .toSet()
              .toList();
          countries.sort();
          availableCountries = ['All', ...countries];

          isLoading = false;
          lastUpdated = DateTime.now();
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = error.toString();
          isLoading = false;
        });
      }
    }
  }

  List<NewsArticle> _getSelectedNews() {
    switch (selectedCategory) {
      case NewsCategory.crypto:
        return cryptoNews;
      case NewsCategory.forex:
        return forexNews;
      case NewsCategory.futures:
        return futuresNews;
      case NewsCategory.all:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // Pinned category tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabHeaderDelegate(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 6,
                  bottom: 10,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF0A0A0A),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF1F1F21), width: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'MARKET NEWS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          color: const Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _CategoryTab(
                                  label: 'CRYPTO',
                                  isSelected: selectedCategory == NewsCategory.crypto,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(
                                      () => selectedCategory = NewsCategory.crypto,
                                    );
                                  },
                                ),
                                _CategoryTab(
                                  label: 'FOREX',
                                  isSelected: selectedCategory == NewsCategory.forex,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => selectedCategory = NewsCategory.forex);
                                  },
                                ),
                                _CategoryTab(
                                  label: 'FUTURES',
                                  isSelected: selectedCategory == NewsCategory.futures,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(
                                      () => selectedCategory = NewsCategory.futures,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          _buildSliverBody(),
        ],
      ),
    );
  }

  SliverList _buildSliverBody() {
    if (isLoading && cryptoNews.isEmpty && economicEvents.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([_buildShimmerLoading()]),
      );
    }

    if (errorMessage != null && cryptoNews.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([_buildErrorState()]),
      );
    }

    // For Forex, show economic calendar + news
    if (selectedCategory == NewsCategory.forex) {
      return _buildSliverForexTab();
    }

    // For Crypto and Futures, show only news
    final articles = _getSelectedNews();
    if (articles.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([_buildEmptyState()]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == 0) {
          return _buildHeaderSection();
        }

        final article = articles[index - 1];
        return Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: _NewsCard(article: article)
              .animate(delay: Duration(milliseconds: (index - 1) * 60))
              .fadeIn(duration: 250.ms)
              .slideY(begin: 0.04, curve: Curves.easeOut),
        );
      }, childCount: articles.length + 1),
    );
  }

  SliverList _buildSliverForexTab() {
    final children = <Widget>[
      _buildHeaderSection(),
      // Filters for economic calendar
      if (economicEvents.isNotEmpty) _buildFilterRow(),
      // Economic Calendar Section
      if (_filteredEconomicEvents.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.sm,
            left: AppSpacing.md,
            right: AppSpacing.md,
          ),
          child: Text(
            'ECONOMIC CALENDAR',
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ),
        ..._filteredEconomicEvents.asMap().entries.map((entry) {
          final event = entry.value;
          return Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: _EconomicEventCard(event: event)
                .animate(delay: Duration(milliseconds: entry.key * 50))
                .fadeIn(duration: 250.ms)
                .slideY(begin: 0.04, curve: Curves.easeOut),
          );
        }),
      ],
      // Forex News Section
      if (forexNews.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.sm,
            left: AppSpacing.md,
            right: AppSpacing.md,
          ),
          child: Text(
            'FOREX NEWS',
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ),
        ...forexNews.asMap().entries.map((entry) {
          final article = entry.value;
          return Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: _NewsCard(article: article)
                .animate(delay: Duration(milliseconds: entry.key * 50))
                .fadeIn(duration: 250.ms)
                .slideY(begin: 0.04, curve: Curves.easeOut),
          );
        }),
      ],
      if (forexNews.isEmpty && economicEvents.isEmpty) _buildEmptyState(),
    ];

    return SliverList(delegate: SliverChildListDelegate(children));
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      child: Row(
        children: [
          Text(
            selectedCategory.name.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const Spacer(),
          Text(
            'Updated ${_formatTime(lastUpdated ?? DateTime.now())}',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          _buildHeaderSection(),
          const SizedBox(height: AppSpacing.sm),
          Shimmer.fromColors(
            baseColor: AppColors.surface,
            highlightColor: AppColors.surfaceHigh,
            child: Column(
              children: List.generate(
                4,
                (_) => Container(
                  height: 130,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.md,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Error loading news',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorMessage ?? 'Unknown error',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: fetchAllNews,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: Text(
              'Retry',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.newspaper, size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No news available',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Check back later for updates',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  List<EconomicEvent> get _filteredEconomicEvents {
    var list = economicEvents;
    if (countryFilter != 'All') {
      list = list.where((e) => e.country == countryFilter).toList();
    }
    if (impactFilter != 'All') {
      list = list
          .where((e) => e.impact.toUpperCase() == impactFilter.toUpperCase())
          .toList();
    }
    return list;
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: DropdownButton<String>(
                value: countryFilter,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                underline: const SizedBox.shrink(),
                items: availableCountries
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          c,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    countryFilter = v;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: DropdownButton<String>(
                value: impactFilter,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                underline: const SizedBox.shrink(),
                items: ['All', 'HIGH', 'MEDIUM', 'LOW']
                    .map(
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text(
                          i,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    impactFilter = v;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.only(left: 10, right: 10, top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A1810) : const Color(0xFF1C1C1E),
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE8622A)
                : const Color(0xFF2C2C2E),
            width: isSelected ? 1.0 : 0.5,
          ),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 0.1,
            color: isSelected
                ? const Color(0xFFE8622A)
                : const Color(0xFF8E8E93),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _TabHeaderDelegate({required this.child});

  @override
  double get minExtent => 71;

  @override
  double get maxExtent => 71;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_TabHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _NewsCard extends StatelessWidget {
  final NewsArticle article;

  const _NewsCard({required this.article});

  Future<void> _openArticle() async {
    if (article.url.isEmpty) return;

    final uri = Uri.parse(article.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openArticle,
          borderRadius: AppRadius.md,
          splashColor: AppColors.accent.withValues(alpha: 0.1),
          highlightColor: AppColors.inkwellHighlight,
          child: Column(
            children: [
              if (article.urlToImage != null)
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(article.urlToImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            article.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getSentimentColor(article.sentimentLabel),
                            borderRadius: AppRadius.pill,
                          ),
                          child: Text(
                            article.sentimentLabel.substring(0, 1),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      article.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  article.source,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '•',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                article.timeAgo,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toUpperCase()) {
      case 'POSITIVE':
        return AppColors.positive;
      case 'NEGATIVE':
        return AppColors.negative;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _EconomicEventCard extends StatelessWidget {
  final EconomicEvent event;

  const _EconomicEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.event,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.country,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getImpactColor(event.impact),
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    event.impact,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Event Time
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: AppRadius.sm,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Time',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '${event.eventTime.hour.toString().padLeft(2, '0')}:${event.eventTime.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '${event.eventTime.year}-${event.eventTime.month.toString().padLeft(2, '0')}-${event.eventTime.day.toString().padLeft(2, '0')}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Forecast & Previous Data
            Row(
              children: [
                Expanded(
                  child: _DataField(
                    label: 'Forecast',
                    value: event.forecast ?? 'N/A',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _DataField(
                    label: 'Previous',
                    value: event.previous ?? 'N/A',
                  ),
                ),
                if (event.actual != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _DataField(
                      label: 'Actual',
                      value: event.actual ?? 'N/A',
                      highlight: true,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getImpactColor(String impact) {
    switch (impact.toUpperCase()) {
      case 'HIGH':
        return AppColors.negative;
      case 'MEDIUM':
        return AppColors.accent;
      default:
        return AppColors.positive;
    }
  }
}

class _DataField extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _DataField({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: highlight ? AppColors.accentSurface : AppColors.surfaceHigh,
        borderRadius: AppRadius.sm,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: highlight ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
