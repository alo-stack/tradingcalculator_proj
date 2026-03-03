class Currency {
  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  final String code;
  final String name;
  final String symbol;
}

enum CurrencyCategory {
  all,
  forex,
  crypto,
}

extension CurrencyCategoryExtension on CurrencyCategory {
  String get displayName {
    switch (this) {
      case CurrencyCategory.all:
        return 'All';
      case CurrencyCategory.forex:
        return 'Forex';
      case CurrencyCategory.crypto:
        return 'Crypto';
    }
  }
}

class CurrenciesData {
  static const List<Currency> majorCurrencies = [
    Currency(code: 'USD', name: 'US Dollar', symbol: '\$'),
    Currency(code: 'EUR', name: 'Euro', symbol: '€'),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£'),
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
    Currency(code: 'CHF', name: 'Swiss Franc', symbol: 'Fr'),
    Currency(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$'),
    Currency(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$'),
    Currency(code: 'NZD', name: 'New Zealand Dollar', symbol: 'NZ\$'),
    Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
    Currency(code: 'SEK', name: 'Swedish Krona', symbol: 'kr'),
    Currency(code: 'NOK', name: 'Norwegian Krone', symbol: 'kr'),
    Currency(code: 'DKK', name: 'Danish Krone', symbol: 'kr'),
    Currency(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$'),
    Currency(code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK\$'),
    Currency(code: 'KRW', name: 'South Korean Won', symbol: '₩'),
    Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
    Currency(code: 'MXN', name: 'Mexican Peso', symbol: 'Mex\$'),
    Currency(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$'),
    Currency(code: 'ZAR', name: 'South African Rand', symbol: 'R'),
    Currency(code: 'RUB', name: 'Russian Ruble', symbol: '₽'),
    Currency(code: 'TRY', name: 'Turkish Lira', symbol: '₺'),
    Currency(code: 'PLN', name: 'Polish Zloty', symbol: 'zł'),
    Currency(code: 'THB', name: 'Thai Baht', symbol: '฿'),
    Currency(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp'),
    Currency(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM'),
    Currency(code: 'PHP', name: 'Philippine Peso', symbol: '₱'),
  ];

  static const List<Currency> cryptocurrencies = [
    Currency(code: 'BTC', name: 'Bitcoin', symbol: '₿'),
    Currency(code: 'ETH', name: 'Ethereum', symbol: 'Ξ'),
    Currency(code: 'USDT', name: 'Tether', symbol: '₮'),
    Currency(code: 'USDC', name: 'USD Coin', symbol: 'USDC'),
    Currency(code: 'BNB', name: 'Binance Coin', symbol: 'BNB'),
    Currency(code: 'XRP', name: 'Ripple', symbol: 'XRP'),
    Currency(code: 'ADA', name: 'Cardano', symbol: 'ADA'),
    Currency(code: 'SOL', name: 'Solana', symbol: 'SOL'),
    Currency(code: 'DOT', name: 'Polkadot', symbol: 'DOT'),
    Currency(code: 'DOGE', name: 'Dogecoin', symbol: 'DOGE'),
    Currency(code: 'MATIC', name: 'Polygon', symbol: 'MATIC'),
    Currency(code: 'LTC', name: 'Litecoin', symbol: 'Ł'),
    Currency(code: 'SHIB', name: 'Shiba Inu', symbol: 'SHIB'),
    Currency(code: 'TRX', name: 'Tron', symbol: 'TRX'),
    Currency(code: 'AVAX', name: 'Avalanche', symbol: 'AVAX'),
  ];

  static List<Currency> get allCurrencies => [...majorCurrencies, ...cryptocurrencies];

  static List<Currency> getByCategory(CurrencyCategory category) {
    switch (category) {
      case CurrencyCategory.all:
        return allCurrencies;
      case CurrencyCategory.forex:
        return majorCurrencies;
      case CurrencyCategory.crypto:
        return cryptocurrencies;
    }
  }

  static List<Currency> search(String query) {
    if (query.isEmpty) return allCurrencies;
    
    final String lowerQuery = query.toLowerCase();
    return allCurrencies.where((currency) {
      return currency.code.toLowerCase().contains(lowerQuery) ||
          currency.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  static Currency? findByCode(String code) {
    try {
      return allCurrencies.firstWhere((c) => c.code.toLowerCase() == code.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}
