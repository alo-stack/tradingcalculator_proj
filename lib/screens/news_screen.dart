import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
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
          final countries = economicEvents.map((e) => e.country).toSet().toList();
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
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Row(
          children: [
            Text(
              'Market News',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.positiveBg,
                borderRadius: AppRadius.pill,
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.positive,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Live',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.positive,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Category tabs
          Container(
            height: 50,
            color: AppColors.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _CategoryTab(
                  label: 'CRYPTO',
                  isSelected: selectedCategory == NewsCategory.crypto,
                  onTap: () => setState(() => selectedCategory = NewsCategory.crypto),
                ),
                _CategoryTab(
                  label: 'FOREX',
                  isSelected: selectedCategory == NewsCategory.forex,
                  onTap: () => setState(() => selectedCategory = NewsCategory.forex),
                ),
                _CategoryTab(
                  label: 'FUTURES',
                  isSelected: selectedCategory == NewsCategory.futures,
                  onTap: () => setState(() => selectedCategory = NewsCategory.futures),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && cryptoNews.isEmpty && economicEvents.isEmpty) {
      return _buildShimmerLoading();
    }

    if (errorMessage != null && cryptoNews.isEmpty) {
      return _buildErrorState();
    }

    // For Forex, show economic calendar + news
    if (selectedCategory == NewsCategory.forex) {
      return _buildForexTab();
    }

    // For Crypto and Futures, show only news
    final articles = _getSelectedNews();
    if (articles.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: fetchAllNews,
      backgroundColor: AppColors.surface,
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: articles.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeaderSection();
          }

          final article = articles[index - 1];
          return _NewsCard(article: article)
              .animate(delay: Duration(milliseconds: (index - 1) * 60))
              .fadeIn(duration: 250.ms)
              .slideY(begin: 0.04, curve: Curves.easeOut);
        },
      ),
    );
  }

  Widget _buildForexTab() {
    return RefreshIndicator(
      onRefresh: fetchAllNews,
      backgroundColor: AppColors.surface,
      color: AppColors.accent,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildHeaderSection(),
          // Filters for economic calendar
          if (economicEvents.isNotEmpty) ...[
            _buildFilterRow(),
          ],
          // Economic Calendar Section
          if (_filteredEconomicEvents.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.md),
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
              return _EconomicEventCard(event: event)
                  .animate(delay: Duration(milliseconds: entry.key * 50))
                  .fadeIn(duration: 250.ms)
                  .slideY(begin: 0.04, curve: Curves.easeOut);
            }),
          ],
          // Forex News Section
          if (forexNews.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.md),
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
              return _NewsCard(article: article)
                  .animate(delay: Duration(milliseconds: entry.key * 50))
                  .fadeIn(duration: 250.ms)
                  .slideY(begin: 0.04, curve: Curves.easeOut);
            }),
          ],
          if (forexNews.isEmpty && economicEvents.isEmpty)
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
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
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.textMuted,
          ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
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
          Icon(
            Icons.newspaper,
            size: 48,
            color: AppColors.textMuted,
          ),
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
      list = list.where((e) => e.impact.toUpperCase() == impactFilter.toUpperCase()).toList();
    }
    return list;
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: countryFilter,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              underline: const SizedBox.shrink(),
              items: availableCountries
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          c,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  countryFilter = v;
                });
                fetchAllNews();
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DropdownButton<String>(
              value: impactFilter,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              underline: const SizedBox.shrink(),
              items: ['All', 'HIGH', 'MEDIUM', 'LOW']
                  .map((i) => DropdownMenuItem(
                        value: i,
                        child: Text(
                          i,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  impactFilter = v;
                });
                fetchAllNews();
              },
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsArticle article;

  const _NewsCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          if (article.urlToImage != null)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                image: DecorationImage(
                  image: NetworkImage(article.urlToImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
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
                    Text(
                      article.timeAgo,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
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
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
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
