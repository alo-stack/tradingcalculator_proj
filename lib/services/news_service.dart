import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.description,
    required this.source,
    required this.publishedAt,
    required this.url,
    this.urlToImage,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] as String? ?? 'No title',
      description: json['description'] as String? ?? '',
      source: json['source']?['name'] as String? ?? 'Unknown',
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? '') ?? DateTime.now(),
      url: json['url'] as String? ?? '',
      urlToImage: json['urlToImage'] as String?,
    );
  }

  final String title;
  final String description;
  final String source;
  final DateTime publishedAt;
  final String url;
  final String? urlToImage;

  String get timeAgo {
    final Duration difference = DateTime.now().difference(publishedAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class NewsService {
  // Using NewsAPI.org free tier - Get your own key at https://newsapi.org/
  // This demo key has limited requests. For production, sign up for your own key.
  static const String _apiKey = 'a4a82b5881ef4f8cbb8c23576d95b1a8';
  static const String _baseUrl = 'https://newsapi.org/v2';

  static Future<List<NewsArticle>> fetchBusinessNews() async {
    try {
      final Uri uri = Uri.parse(
        '$_baseUrl/top-headlines?category=business&language=en&apiKey=$_apiKey',
      );
      
      final http.Response response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> articles = data['articles'] as List<dynamic>? ?? <dynamic>[];
        
        return articles
            .map((dynamic article) => NewsArticle.fromJson(article as Map<String, dynamic>))
            .where((NewsArticle article) => article.title.isNotEmpty && article.title != '[Removed]')
            .take(20)
            .toList();
      } else if (response.statusCode == 426) {
        throw Exception('API upgrade required. This is a demo API key with limited requests.');
      } else if (response.statusCode == 429) {
        throw Exception('Too many requests. Please try again later.');
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  static Future<List<NewsArticle>> searchNews(String query) async {
    try {
      final Uri uri = Uri.parse(
        '$_baseUrl/everything?q=$query&language=en&sortBy=publishedAt&apiKey=$_apiKey',
      );
      
      final http.Response response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> articles = data['articles'] as List<dynamic>? ?? <dynamic>[];
        
        return articles
            .map((dynamic article) => NewsArticle.fromJson(article as Map<String, dynamic>))
            .where((NewsArticle article) => article.title.isNotEmpty && article.title != '[Removed]')
            .take(20)
            .toList();
      } else if (response.statusCode == 426) {
        throw Exception('API upgrade required. This is a demo API key with limited requests.');
      } else if (response.statusCode == 429) {
        throw Exception('Too many requests. Please try again later.');
      } else {
        throw Exception('Failed to search news: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }
}
