import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsArticle {
  final String title;
  final String description;
  final String source;
  final DateTime publishedAt;
  final String url;
  final String? urlToImage;
  final String sentimentLabel; // New field

  const NewsArticle({
    required this.title,
    required this.description,
    required this.source,
    required this.publishedAt,
    required this.url,
    this.urlToImage,
    required this.sentimentLabel, // Add this
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] as String? ?? 'No title',
      description: json['summary'] as String? ?? '',
      source: json['source'] as String? ?? 'Unknown',
      publishedAt: _parseAlphaDate(json['time_published']),
      url: json['url'] as String? ?? '',
      urlToImage: json['banner_image'] as String?,
      sentimentLabel:
          json['overall_sentiment_label'] as String? ?? 'Neutral', // New
    );
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

class NewsService {
  // Get your free key at https://www.alphavantage.co/support/#api-key
  static const String _apiKey = 'YOUR_ALPHA_VANTAGE_KEY';
  static const String _baseUrl = 'https://www.alphavantage.co/query';

  static Future<List<NewsArticle>> fetchMarketNews() async {
    try {
      // We are combining the specific topic keys from the documentation:
      // blockchain = Crypto
      // forex = Forex
      // financial_markets = Stock Market
      // energy_transportation = Commodities (Oil/Energy)
      // economy_monetary = Economic Indicators (Interest rates/Inflation)
      // economy_fiscal = Economic Indicators (Tax/Spending)

      const String topics =
          'blockchain,forex,financial_markets,energy_transportation,economy_monetary,economy_fiscal';

      final Uri uri = Uri.parse(
        '$_baseUrl?function=NEWS_SENTIMENT&topics=$topics&sort=LATEST&limit=50&apikey=$_apiKey',
      );

      final http.Response response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Handling the 'Note' which is Alpha Vantage's way of saying "Rate Limit Hit"
        if (data.containsKey('Note')) {
          throw Exception(
            'API Limit: You can use this 25 times per day on the free tier.',
          );
        }

        final List<dynamic> feed = data['feed'] as List<dynamic>? ?? [];

        return feed
            .map(
              (dynamic item) =>
                  NewsArticle.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Check your internet connection or API Key: $e');
    }
  }
}
