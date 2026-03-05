import 'dart:convert';
import 'package:http/http.dart' as http;

enum NewsCategory { crypto, forex, futures, all }

class NewsArticle {
  final String title;
  final String description;
  final String source;
  final DateTime publishedAt;
  final String url;
  final String? urlToImage;
  final String sentimentLabel;
  final NewsCategory category;

  const NewsArticle({
    required this.title,
    required this.description,
    required this.source,
    required this.publishedAt,
    required this.url,
    this.urlToImage,
    required this.sentimentLabel,
    this.category = NewsCategory.all,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    final category = _categorizeNews(json);
    return NewsArticle(
      title: json['title'] as String? ?? 'No title',
      description: json['summary'] as String? ?? '',
      source: json['source'] as String? ?? 'Unknown',
      publishedAt: _parseAlphaDate(json['time_published']),
      url: json['url'] as String? ?? '',
      urlToImage: json['banner_image'] as String?,
      sentimentLabel: json['overall_sentiment_label'] as String? ?? 'Neutral',
      category: category,
    );
  }

  static NewsCategory _categorizeNews(Map<String, dynamic> json) {
    final topics = json['topics'] as List<dynamic>? ?? [];
    final topicStrings = topics.map((e) => (e as Map<String, dynamic>)['topic'].toString().toLowerCase());
    
    if (topicStrings.any((t) => t.contains('crypto') || t.contains('blockchain'))) {
      return NewsCategory.crypto;
    } else if (topicStrings.any((t) => t.contains('forex') || t.contains('currency'))) {
      return NewsCategory.forex;
    } else if (topicStrings.any((t) => t.contains('commodity') || t.contains('oil') || t.contains('gold'))) {
      return NewsCategory.futures;
    }
    return NewsCategory.all;
  }

  static DateTime _parseAlphaDate(String? dateStr) {
    if (dateStr == null || dateStr.length < 8) return DateTime.now();
    try {
      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));
      return DateTime(year, month, day);
    } catch (_) {
      return DateTime.now();
    }
  }

  String get timeAgo {
    final Duration difference = DateTime.now().difference(publishedAt);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    return '${difference.inMinutes}m ago';
  }
}

class EconomicEvent {
  final String event;
  final String country;
  final DateTime eventTime;
  final String impact; // HIGH, MEDIUM, LOW
  final String? forecast;
  final String? previous;
  final String? actual;

  const EconomicEvent({
    required this.event,
    required this.country,
    required this.eventTime,
    required this.impact,
    this.forecast,
    this.previous,
    this.actual,
  });

  factory EconomicEvent.fromJson(Map<String, dynamic> json) {
    return EconomicEvent(
      event: json['event'] as String? ?? 'Unknown Event',
      country: json['country'] as String? ?? 'Unknown',
      eventTime: _parseEventDate(json['date'] as String?, json['time'] as String?),
      impact: json['impact'] as String? ?? 'MEDIUM',
      forecast: json['forecast'] as String?,
      previous: json['previous'] as String?,
      actual: json['actual'] as String?,
    );
  }

  /// Create an event from the structure returned by Finnhub's API.
  factory EconomicEvent.fromFinnhubJson(Map<String, dynamic> json) {
    return EconomicEvent(
      event: json['event'] as String? ?? 'Unknown Event',
      country: json['country'] as String? ?? 'Unknown',
      eventTime: _parseEventDate(json['date'] as String?, json['time'] as String?),
      impact: (json['importance'] as String? ?? 'Medium').toUpperCase(),
      forecast: json['forecast'] as String?,
      previous: json['previous'] as String?,
      actual: json['actual'] as String?,
    );
  }

  static DateTime _parseEventDate(String? dateStr, String? timeStr) {
    try {
      if (dateStr == null) return DateTime.now();
      
      final dateParts = dateStr.split('-');
      if (dateParts.length < 3) return DateTime.now();
      
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      
      int hour = 0, minute = 0;
      if (timeStr != null) {
        final timeParts = timeStr.split(':');
        if (timeParts.length >= 2) {
          hour = int.parse(timeParts[0]);
          minute = int.parse(timeParts[1]);
        }
      }
      
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return DateTime.now();
    }
  }

  String get timeAgo {
    final Duration difference = DateTime.now().difference(eventTime);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'now';
  }

  String get impactColor {
    switch (impact.toUpperCase()) {
      case 'HIGH':
        return '#FF453A';
      case 'MEDIUM':
        return '#E8622A';
      default:
        return '#30D158';
    }
  }
}

class NewsService {
  // Get your free key at https://www.alphavantage.co/support/#api-key
  static const String _apiKey = '49V7T5J27HVYGD0O';
  static const String _baseUrl = 'https://www.alphavantage.co/query';

  // Key for Finnhub economic calendar (get one at https://finnhub.io)
  static const String _finnhubKey = 'd6kg891r01qg51f3qs30d6kg891r01qg51f3qs3g';

  /// Fetch market news with optional category filter
  static Future<List<NewsArticle>> fetchMarketNews({
    NewsCategory category = NewsCategory.all,
  }) async {
    try {
      const String topics =
          'blockchain,forex,crypto,gold,stock,oil,silver,indices,bonds,commodities';

      final Uri uri = Uri.parse(
        '$_baseUrl?function=NEWS_SENTIMENT&topics=$topics&sort=LATEST&limit=50&apikey=$_apiKey',
      );

      final http.Response response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('Note')) {
          // API limit reached, use mock data
          return _getMockNews(category);
        }

        final List<dynamic> feed = data['feed'] as List<dynamic>? ?? [];

        if (feed.isEmpty) {
          return _getMockNews(category);
        }

        var articles = feed
            .map(
              (dynamic item) =>
                  NewsArticle.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        // Filter by category if specified
        if (category != NewsCategory.all) {
          articles = articles
              .where((article) =>
                  article.category == category || article.category == NewsCategory.all)
              .toList();
        }

        // If no articles for this category, return mock data
        if (articles.isEmpty) {
          return _getMockNews(category);
        }

        return articles;
      } else {
        // Server error, use mock data
        return _getMockNews(category);
      }
    } catch (e) {
      // On any error, fall back to mock news
      return _getMockNews(category);
    }
  }

  /// Fetch the economic calendar with a wider date range.
  /// Client-side filtering handles countries and impacts.
  /// By default, fetches 14 days in the past and 21 days in the future.
  static Future<List<EconomicEvent>> fetchEconomicCalendar({
    List<String>? countries,
    List<String>? impacts,
    DateTime? start,
    DateTime? end,
  }) async {
    final now = DateTime.now();
    final fromDate = start ?? now.subtract(const Duration(days: 14));
    final toDate = end ?? now.add(const Duration(days: 21));

    try {
      // if the developer hasn't provided a real key, fall back to mock data
      if (_finnhubKey.startsWith('YOUR')) {
        // very similar to the previous hard‑coded list
        final now = DateTime.now();
        final events = <EconomicEvent>[
          EconomicEvent(
            event: 'Non-Farm Payroll',
            country: 'US',
            eventTime: now.add(const Duration(hours: 13, minutes: 30)),
            impact: 'HIGH',
            forecast: '200K',
            previous: '227K',
            actual: null,
          ),
          EconomicEvent(
            event: 'ECB Interest Rate Decision',
            country: 'EU',
            eventTime: now.add(const Duration(hours: 12, minutes: 15)),
            impact: 'HIGH',
            forecast: '3.50%',
            previous: '3.50%',
            actual: null,
          ),
          // ... you can add additional mock items here as needed
        ];
        return events
            .where((event) =>
                event.eventTime.isBefore(toDate) &&
                event.eventTime.isAfter(fromDate.subtract(const Duration(days: 1))))
            .toList()
          ..sort((a, b) => a.eventTime.compareTo(b.eventTime));
      }

      // build the query for Finnhub - fetch all data, filter client-side
      final queryParams = <String, String>{
        'token': _finnhubKey,
        'from': '${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}',
        'to': '${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}',
      };
      // Don't filter by country at API level - get all countries and filter client-side
      // This allows the UI to show available countries dynamically

      final uri = Uri.https('finnhub.io', '/api/v1/calendar/economic', queryParams);
      final http.Response response = await http.get(uri);

      // If API fails (403, 429, etc), fall back to mock data
      if (response.statusCode != 200) {
        return _getMockEconomicEvents(fromDate, toDate, countries, impacts);
      }

      try {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> feed = jsonData['economicCalendar'] as List<dynamic>? ?? [];

        if (feed.isEmpty) {
          return _getMockEconomicEvents(fromDate, toDate, countries, impacts);
        }

        final events = feed
            .map((dynamic item) => EconomicEvent.fromFinnhubJson(item as Map<String, dynamic>))
            .toList();

        // Sort by event time
        events.sort((a, b) => a.eventTime.compareTo(b.eventTime));
        
        // Client-side filtering by country and impact if specified
        var filtered = events;
        if (countries != null && countries.isNotEmpty) {
          filtered = filtered.where((e) => countries.contains(e.country)).toList();
        }
        if (impacts != null && impacts.isNotEmpty) {
          final impactUppercase = impacts.map((i) => i.toUpperCase()).toList();
          filtered = filtered.where((e) => impactUppercase.contains(e.impact.toUpperCase())).toList();
        }
        
        return filtered;
      } catch (_) {
        return _getMockEconomicEvents(fromDate, toDate, countries, impacts);
      }
    } catch (e) {
      throw Exception('Failed to fetch economic calendar: $e');
    }
  }

  /// Generate mock economic events for testing or when API fails
  static List<EconomicEvent> _getMockEconomicEvents(
    DateTime fromDate,
    DateTime toDate,
    List<String>? countries,
    List<String>? impacts,
  ) {
    final now = DateTime.now();
    final events = <EconomicEvent>[
      // USA Events
      EconomicEvent(
        event: 'Non-Farm Payroll',
        country: 'US',
        eventTime: now.add(const Duration(days: 2, hours: 13, minutes: 30)),
        impact: 'HIGH',
        forecast: '210K',
        previous: '227K',
        actual: null,
      ),
      EconomicEvent(
        event: 'Fed Funds Rate Decision',
        country: 'US',
        eventTime: now.add(const Duration(days: 5, hours: 19)),
        impact: 'HIGH',
        forecast: '4.50%',
        previous: '4.50%',
        actual: null,
      ),
      EconomicEvent(
        event: 'Initial Jobless Claims',
        country: 'US',
        eventTime: now.add(const Duration(days: 1, hours: 13, minutes: 30)),
        impact: 'MEDIUM',
        forecast: '215K',
        previous: '208K',
        actual: null,
      ),
      EconomicEvent(
        event: 'Consumer Price Index',
        country: 'US',
        eventTime: now.add(const Duration(days: 3, hours: 13, minutes: 30)),
        impact: 'HIGH',
        forecast: '3.2%',
        previous: '3.4%',
        actual: null,
      ),
      // Eurozone Events
      EconomicEvent(
        event: 'ECB Interest Rate Decision',
        country: 'EU',
        eventTime: now.add(const Duration(days: 7, hours: 12, minutes: 45)),
        impact: 'HIGH',
        forecast: '3.50%',
        previous: '3.50%',
        actual: null,
      ),
      EconomicEvent(
        event: 'Eurozone CPI',
        country: 'EU',
        eventTime: now.add(const Duration(days: 4, hours: 10)),
        impact: 'HIGH',
        forecast: '2.8%',
        previous: '2.9%',
        actual: null,
      ),
      EconomicEvent(
        event: 'German ZEW Sentiment',
        country: 'DE',
        eventTime: now.add(const Duration(days: 6, hours: 10)),
        impact: 'MEDIUM',
        forecast: '15.2',
        previous: '12.3',
        actual: null,
      ),
      // UK Events
      EconomicEvent(
        event: 'Bank of England Rate Decision',
        country: 'GB',
        eventTime: now.add(const Duration(days: 8, hours: 12)),
        impact: 'HIGH',
        forecast: '5.00%',
        previous: '5.00%',
        actual: null,
      ),
      EconomicEvent(
        event: 'UK Inflation Rate',
        country: 'GB',
        eventTime: now.add(const Duration(days: 6, hours: 9, minutes: 30)),
        impact: 'HIGH',
        forecast: '3.4%',
        previous: '3.9%',
        actual: null,
      ),
      // Japan Events
      EconomicEvent(
        event: 'BOJ Policy Rate Decision',
        country: 'JP',
        eventTime: now.add(const Duration(days: 4, hours: 6)),
        impact: 'HIGH',
        forecast: '-0.10%',
        previous: '-0.10%',
        actual: null,
      ),
      EconomicEvent(
        event: 'Japan CPI',
        country: 'JP',
        eventTime: now.add(const Duration(days: 2, hours: 23, minutes: 30)),
        impact: 'MEDIUM',
        forecast: '2.5%',
        previous: '2.8%',
        actual: null,
      ),
      // Canada Events
      EconomicEvent(
        event: 'Bank of Canada Rate Decision',
        country: 'CA',
        eventTime: now.add(const Duration(days: 8, hours: 14)),
        impact: 'HIGH',
        forecast: '4.25%',
        previous: '4.25%',
        actual: null,
      ),
      // Australia Events
      EconomicEvent(
        event: 'RBA Rate Decision',
        country: 'AU',
        eventTime: now.add(const Duration(days: 3, hours: 5, minutes: 30)),
        impact: 'HIGH',
        forecast: '4.35%',
        previous: '4.10%',
        actual: null,
      ),
      // Switzerland Events
      EconomicEvent(
        event: 'SNB Interest Rate Decision',
        country: 'CH',
        eventTime: now.add(const Duration(days: 6, hours: 9)),
        impact: 'HIGH',
        forecast: '1.75%',
        previous: '1.75%',
        actual: null,
      ),
      // Past events
      EconomicEvent(
        event: 'Previous NFP',
        country: 'US',
        eventTime: now.subtract(const Duration(days: 5, hours: 2)),
        impact: 'HIGH',
        forecast: '227K',
        previous: '199K',
        actual: '227K',
      ),
      EconomicEvent(
        event: 'Previous Fed Decision',
        country: 'US',
        eventTime: now.subtract(const Duration(days: 10, hours: 5)),
        impact: 'HIGH',
        forecast: '4.50%',
        previous: '4.50%',
        actual: '4.50%',
      ),
    ];

    // Filter by date range
    var result = events
        .where((event) =>
            event.eventTime.isAfter(fromDate) && event.eventTime.isBefore(toDate))
        .toList();

    // Filter by country if specified
    if (countries != null && countries.isNotEmpty) {
      result = result.where((e) => countries.contains(e.country)).toList();
    }

    // Filter by impact if specified
    if (impacts != null && impacts.isNotEmpty) {
      final impactUppercase = impacts.map((i) => i.toUpperCase()).toList();
      result = result.where((e) => impactUppercase.contains(e.impact.toUpperCase())).toList();
    }

    result.sort((a, b) => a.eventTime.compareTo(b.eventTime));
    return result;
  }

  /// Generate mock news for testing or when API fails
  static List<NewsArticle> _getMockNews(NewsCategory category) {
    final now = DateTime.now();
    final mockArticles = <NewsArticle>[
      // Crypto News
      NewsArticle(
        title: 'Bitcoin Surges Past \$43,000 Amid Institutional Adoption',
        description: 'Bitcoin reaches new highs as major institutions announce crypto holdings',
        source: 'CryptoNews Daily',
        publishedAt: now.subtract(const Duration(hours: 2)),
        url: 'https://cryptonewsdaily.com',
        urlToImage: null,
        sentimentLabel: 'Positive',
        category: NewsCategory.crypto,
      ),
      NewsArticle(
        title: 'Ethereum Network Upgrade Improves Scalability by 40%',
        description: 'Latest Ethereum update shows significant improvement in transaction speeds',
        source: 'Blockchain Journal',
        publishedAt: now.subtract(const Duration(hours: 5)),
        url: 'https://blockchainjournal.com',
        urlToImage: null,
        sentimentLabel: 'Positive',
        category: NewsCategory.crypto,
      ),
      NewsArticle(
        title: 'Altcoins Rally as Bitcoin Consolidates',
        description: 'Market enthusiasm shifts to alternative cryptocurrencies during Bitcoin consolidation',
        source: 'Crypto Market Watch',
        publishedAt: now.subtract(const Duration(hours: 8)),
        url: 'https://cryptomarketwatch.com',
        urlToImage: null,
        sentimentLabel: 'Neutral',
        category: NewsCategory.crypto,
      ),
      NewsArticle(
        title: 'NFT Market Shows Signs of Recovery',
        description: 'Trading volume in NFT sector increases for third consecutive week',
        source: 'NFT Insider',
        publishedAt: now.subtract(const Duration(hours: 12)),
        url: 'https://nftinsider.com',
        urlToImage: null,
        sentimentLabel: 'Positive',
        category: NewsCategory.crypto,
      ),
      NewsArticle(
        title: 'Regulatory Clarity Needed in Crypto Space',
        description: 'Industry leaders call for clearer crypto regulations in 2026',
        source: 'Finance Today',
        publishedAt: now.subtract(const Duration(hours: 15)),
        url: 'https://financetoday.com',
        urlToImage: null,
        sentimentLabel: 'Neutral',
        category: NewsCategory.crypto,
      ),
      
      // Futures News
      NewsArticle(
        title: 'Oil Prices Rise on OPEC Production Concerns',
        description: 'Crude oil futures surge as OPEC signals potential supply cuts',
        source: 'Energy Markets Daily',
        publishedAt: now.subtract(const Duration(hours: 3)),
        url: 'https://energymarketsdaily.com',
        urlToImage: null,
        sentimentLabel: 'Positive',
        category: NewsCategory.futures,
      ),
      NewsArticle(
        title: 'Gold Hits 3-Month High Amid Economic Uncertainty',
        description: 'Gold futures reach highest level since December as investors seek safe haven',
        source: 'Commodity Markets',
        publishedAt: now.subtract(const Duration(hours: 6)),
        url: 'https://commoditymarkets.com',
        urlToImage: null,
        sentimentLabel: 'Positive',
        category: NewsCategory.futures,
      ),
      NewsArticle(
        title: 'Silver Volatility Increases on Industrial Demand',
        description: 'Silver futures experience significant price swings due to manufacturing surge',
        source: 'Metal Insights',
        publishedAt: now.subtract(const Duration(hours: 9)),
        url: 'https://metalinsights.com',
        urlToImage: null,
        sentimentLabel: 'Neutral',
        category: NewsCategory.futures,
      ),
      NewsArticle(
        title: 'Agricultural Futures Rally on Weather Concerns',
        description: 'Wheat and corn futures jump as drought reports impact supply expectations',
        source: 'Agricultural News',
        publishedAt: now.subtract(const Duration(hours: 11)),
        url: 'https://agriculturenews.com',
        urlToImage: null,
        sentimentLabel: 'Positive',
        category: NewsCategory.futures,
      ),
      NewsArticle(
        title: 'Natural Gas Futures Decline on Mild Weather Outlook',
        description: 'Natural gas prices fall as forecasts predict warmer temperatures',
        source: 'Energy Insights',
        publishedAt: now.subtract(const Duration(hours: 14)),
        url: 'https://energyinsights.com',
        urlToImage: null,
        sentimentLabel: 'Negative',
        category: NewsCategory.futures,
      ),
    ];

    // Filter by category
    var result = mockArticles;
    if (category != NewsCategory.all) {
      result = result.where((article) => article.category == category).toList();
    }

    return result;
  }

  /// Fetch news by specific category
  static Future<List<NewsArticle>> fetchNewsByCategory(NewsCategory category) async {
    return fetchMarketNews(category: category);
  }
}
