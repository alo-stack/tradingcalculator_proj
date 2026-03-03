import 'dart:convert';
import 'package:http/http.dart' as http;

class ConversionRatesSnapshot {
  const ConversionRatesSnapshot({
    required this.usdPerUnit,
    required this.fetchedAt,
  });

  final Map<String, double> usdPerUnit;
  final DateTime fetchedAt;
}

class ConversionRatesService {
  static const String _fiatUrl = 'https://open.er-api.com/v6/latest/USD';
  static const String _cryptoBaseUrl = 'https://api.coingecko.com/api/v3/simple/price';

  static const Map<String, String> _cryptoIdsByCode = <String, String>{
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'USDT': 'tether',
    'USDC': 'usd-coin',
    'BNB': 'binancecoin',
    'XRP': 'ripple',
    'ADA': 'cardano',
    'SOL': 'solana',
    'DOT': 'polkadot',
    'DOGE': 'dogecoin',
    'MATIC': 'matic-network',
    'LTC': 'litecoin',
    'SHIB': 'shiba-inu',
    'TRX': 'tron',
    'AVAX': 'avalanche-2',
  };

  static Future<ConversionRatesSnapshot> fetchUsdPerUnitRates({
    required Set<String> fiatCodes,
    required Set<String> cryptoCodes,
  }) async {
    final Map<String, double> usdPerUnit = <String, double>{'USD': 1.0};

    final Uri fiatUri = Uri.parse(_fiatUrl);
    final http.Response fiatResponse = await http.get(fiatUri);

    if (fiatResponse.statusCode != 200) {
      throw Exception('Failed to fetch fiat rates: ${fiatResponse.statusCode}');
    }

    final Map<String, dynamic> fiatJson = json.decode(fiatResponse.body) as Map<String, dynamic>;
    final Map<String, dynamic>? rates = fiatJson['rates'] as Map<String, dynamic>?;

    if (rates == null || rates.isEmpty) {
      throw Exception('Fiat rates response is empty.');
    }

    for (final String code in fiatCodes) {
      if (code == 'USD') {
        usdPerUnit['USD'] = 1.0;
        continue;
      }
      final dynamic value = rates[code];
      if (value is num && value > 0) {
        usdPerUnit[code] = 1.0 / value.toDouble();
      }
    }

    final List<String> cryptoIds = cryptoCodes
        .map((String code) => _cryptoIdsByCode[code])
        .whereType<String>()
        .toList();

    if (cryptoIds.isNotEmpty) {
      final Uri cryptoUri = Uri.parse('$_cryptoBaseUrl?ids=${cryptoIds.join(',')}&vs_currencies=usd');
      final http.Response cryptoResponse = await http.get(cryptoUri);

      if (cryptoResponse.statusCode == 200) {
        final Map<String, dynamic> cryptoJson = json.decode(cryptoResponse.body) as Map<String, dynamic>;
        for (final MapEntry<String, String> entry in _cryptoIdsByCode.entries) {
          if (!cryptoCodes.contains(entry.key)) {
            continue;
          }
          final dynamic item = cryptoJson[entry.value];
          final dynamic usdValue = item is Map<String, dynamic> ? item['usd'] : null;
          if (usdValue is num && usdValue > 0) {
            usdPerUnit[entry.key] = usdValue.toDouble();
          }
        }
      }
    }

    return ConversionRatesSnapshot(
      usdPerUnit: usdPerUnit,
      fetchedAt: DateTime.now(),
    );
  }
}
