import 'dart:convert';

import 'package:http/http.dart' as http;

class MarketCandle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  const MarketCandle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });
}

class MarketDataService {
  static const String _host = 'api.twelvedata.com';
  static const String _apiKey = String.fromEnvironment('f23193a588b347d2987a613b922291a8');

  static bool get hasApiKey => _apiKey.isNotEmpty;

  static Future<double?> fetchPrice({required String symbol}) async {
    if (!hasApiKey) return null;

    try {
      final uri = Uri.https(_host, '/price', {
        'symbol': symbol,
        'apikey': _apiKey,
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data.containsKey('code')) return null;

      final rawPrice = data['price']?.toString();
      return double.tryParse(rawPrice ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<List<MarketCandle>> fetchCandles({
    required String symbol,
    String interval = '5min',
    int outputSize = 80,
  }) async {
    if (!hasApiKey) return const [];

    try {
      final uri = Uri.https(_host, '/time_series', {
        'symbol': symbol,
        'interval': interval,
        'outputsize': '$outputSize',
        'apikey': _apiKey,
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) return const [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data.containsKey('code')) return const [];

      final values = data['values'] as List<dynamic>?;
      if (values == null || values.isEmpty) return const [];

      final candles = values
          .map((entry) => _parseCandle(entry as Map<String, dynamic>))
          .whereType<MarketCandle>()
          .toList()
        ..sort((a, b) => a.time.compareTo(b.time));

      return candles;
    } catch (_) {
      return const [];
    }
  }

  static MarketCandle? _parseCandle(Map<String, dynamic> raw) {
    final dt = DateTime.tryParse(raw['datetime']?.toString() ?? '');
    final open = double.tryParse(raw['open']?.toString() ?? '');
    final high = double.tryParse(raw['high']?.toString() ?? '');
    final low = double.tryParse(raw['low']?.toString() ?? '');
    final close = double.tryParse(raw['close']?.toString() ?? '');

    if (dt == null || open == null || high == null || low == null || close == null) {
      return null;
    }

    return MarketCandle(
      time: dt,
      open: open,
      high: high,
      low: low,
      close: close,
    );
  }
}
