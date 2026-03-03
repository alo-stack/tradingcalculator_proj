class TradingSymbol {
  const TradingSymbol({
    required this.symbol,
    required this.description,
    required this.category,
    required this.pipSize,
    this.baseSize = 100000,
  });

  final String symbol;
  final String description;
  final SymbolCategory category;
  final double pipSize;
  final double baseSize;
}

enum SymbolCategory {
  forex,
  cryptocurrency,
  stock,
  indices,
  commodity,
}

extension SymbolCategoryExtension on SymbolCategory {
  String get displayName {
    switch (this) {
      case SymbolCategory.forex:
        return 'Forex';
      case SymbolCategory.cryptocurrency:
        return 'Cryptocurrency';
      case SymbolCategory.stock:
        return 'Stock';
      case SymbolCategory.indices:
        return 'Indices';
      case SymbolCategory.commodity:
        return 'Commodity';
    }
  }
}

class SymbolsData {
  static final List<TradingSymbol> allSymbols = [
    // Forex - Major Pairs
    const TradingSymbol(
      symbol: 'EUR/USD',
      description: 'Euro / US Dollar',
      category: SymbolCategory.forex,
      pipSize: 0.0001,
    ),
    const TradingSymbol(
      symbol: 'GBP/USD',
      description: 'British Pound / US Dollar',
      category: SymbolCategory.forex,
      pipSize: 0.0001,
    ),
    const TradingSymbol(
      symbol: 'USD/JPY',
      description: 'US Dollar / Japanese Yen',
      category: SymbolCategory.forex,
      pipSize: 0.01,
    ),
    const TradingSymbol(
      symbol: 'USD/CHF',
      description: 'US Dollar / Swiss Franc',
      category: SymbolCategory.forex,
      pipSize: 0.0001,
    ),
    const TradingSymbol(
      symbol: 'AUD/USD',
      description: 'Australian Dollar / US Dollar',
      category: SymbolCategory.forex,
      pipSize: 0.0001,
    ),
    const TradingSymbol(
      symbol: 'USD/CAD',
      description: 'US Dollar / Canadian Dollar',
      category: SymbolCategory.forex,
      pipSize: 0.0001,
    ),
    const TradingSymbol(
      symbol: 'NZD/USD',
      description: 'New Zealand Dollar / US Dollar',
      category: SymbolCategory.forex,
      pipSize: 0.0001,
    ),
    
    // Forex - Cross Pairs
    const TradingSymbol(
      symbol: 'EUR/GBP',
      description: 'Euro / British Pound',
      category: SymbolCategory.forex,
      pipSize: 0.0001,
    ),
    const TradingSymbol(
      symbol: 'EUR/JPY',
      description: 'Euro / Japanese Yen',
      category: SymbolCategory.forex,
      pipSize: 0.01,
    ),
    const TradingSymbol(
      symbol: 'GBP/JPY',
      description: 'British Pound / Japanese Yen',
      category: SymbolCategory.forex,
      pipSize: 0.01,
    ),
    const TradingSymbol(
      symbol: 'AUD/CAD',
      description: 'Australian Dollar / Canadian Dollar',
      category: SymbolCategory.forex,
      pipSize: 0.0001,
    ),
    const TradingSymbol(
      symbol: 'AUD/JPY',
      description: 'Australian Dollar / Japanese Yen',
      category: SymbolCategory.forex,
      pipSize: 0.01,
    ),
    const TradingSymbol(
      symbol: 'AUD/NZD',
      description: 'Australian Dollar / New Zealand Dollar',
      category: SymbolCategory.forex,
      pipSize: 0.0001,
    ),
    const TradingSymbol(
      symbol: 'CAD/JPY',
      description: 'Canadian Dollar / Japanese Yen',
      category: SymbolCategory.forex,
      pipSize: 0.01,
    ),
    const TradingSymbol(
      symbol: 'EUR/AUD',
      description: 'Euro / Australian Dollar',
      category: SymbolCategory.forex,
      pipSize: 0.0001,
    ),
    const TradingSymbol(
      symbol: 'EUR/CAD',
      description: 'Euro / Canadian Dollar',
      category: SymbolCategory.forex,
      pipSize: 0.0001,
    ),
    const TradingSymbol(
      symbol: 'GBP/AUD',
      description: 'British Pound / Australian Dollar',
      category: SymbolCategory.forex,
      pipSize: 0.0001,
    ),
    const TradingSymbol(
      symbol: 'GBP/CAD',
      description: 'British Pound / Canadian Dollar',
      category: SymbolCategory.forex,
      pipSize: 0.0001,
    ),
    const TradingSymbol(
      symbol: 'NZD/JPY',
      description: 'New Zealand Dollar / Japanese Yen',
      category: SymbolCategory.forex,
      pipSize: 0.01,
    ),

    // Cryptocurrency
    const TradingSymbol(
      symbol: 'BTC/USD',
      description: 'Bitcoin / US Dollar',
      category: SymbolCategory.cryptocurrency,
      pipSize: 0.01,
      baseSize: 1,
    ),
    const TradingSymbol(
      symbol: 'ETH/USD',
      description: 'Ethereum / US Dollar',
      category: SymbolCategory.cryptocurrency,
      pipSize: 0.01,
      baseSize: 1,
    ),
    const TradingSymbol(
      symbol: 'XRP/USD',
      description: 'Ripple / US Dollar',
      category: SymbolCategory.cryptocurrency,
      pipSize: 0.0001,
      baseSize: 1,
    ),
    const TradingSymbol(
      symbol: 'LTC/USD',
      description: 'Litecoin / US Dollar',
      category: SymbolCategory.cryptocurrency,
      pipSize: 0.01,
      baseSize: 1,
    ),
    const TradingSymbol(
      symbol: 'ADA/USD',
      description: 'Cardano / US Dollar',
      category: SymbolCategory.cryptocurrency,
      pipSize: 0.0001,
      baseSize: 1,
    ),
    const TradingSymbol(
      symbol: 'SOL/USD',
      description: 'Solana / US Dollar',
      category: SymbolCategory.cryptocurrency,
      pipSize: 0.01,
      baseSize: 1,
    ),
    const TradingSymbol(
      symbol: 'DOT/USD',
      description: 'Polkadot / US Dollar',
      category: SymbolCategory.cryptocurrency,
      pipSize: 0.01,
      baseSize: 1,
    ),

    // Indices
    const TradingSymbol(
      symbol: 'US500',
      description: 'S&P 500 Index',
      category: SymbolCategory.indices,
      pipSize: 0.01,
      baseSize: 1,
    ),
    const TradingSymbol(
      symbol: 'US30',
      description: 'Dow Jones Industrial Average',
      category: SymbolCategory.indices,
      pipSize: 1,
      baseSize: 1,
    ),
    const TradingSymbol(
      symbol: 'NAS100',
      description: 'NASDAQ 100 Index',
      category: SymbolCategory.indices,
      pipSize: 0.01,
      baseSize: 1,
    ),
    const TradingSymbol(
      symbol: 'UK100',
      description: 'FTSE 100 Index',
      category: SymbolCategory.indices,
      pipSize: 0.01,
      baseSize: 1,
    ),
    const TradingSymbol(
      symbol: 'GER40',
      description: 'DAX 40 Index',
      category: SymbolCategory.indices,
      pipSize: 0.01,
      baseSize: 1,
    ),
    const TradingSymbol(
      symbol: 'JP225',
      description: 'Nikkei 225 Index',
      category: SymbolCategory.indices,
      pipSize: 1,
      baseSize: 1,
    ),

    // Commodities
    const TradingSymbol(
      symbol: 'XAU/USD',
      description: 'Gold / US Dollar',
      category: SymbolCategory.commodity,
      pipSize: 0.01,
      baseSize: 100,
    ),
    const TradingSymbol(
      symbol: 'XAG/USD',
      description: 'Silver / US Dollar',
      category: SymbolCategory.commodity,
      pipSize: 0.001,
      baseSize: 5000,
    ),
    const TradingSymbol(
      symbol: 'USOIL',
      description: 'US Crude Oil',
      category: SymbolCategory.commodity,
      pipSize: 0.01,
      baseSize: 1000,
    ),
    const TradingSymbol(
      symbol: 'UKOIL',
      description: 'UK Brent Crude Oil',
      category: SymbolCategory.commodity,
      pipSize: 0.01,
      baseSize: 1000,
    ),
    const TradingSymbol(
      symbol: 'NATGAS',
      description: 'Natural Gas',
      category: SymbolCategory.commodity,
      pipSize: 0.001,
      baseSize: 10000,
    ),

    // Popular Stocks
    const TradingSymbol(
      symbol: 'AAPL',
      description: 'Apple Inc',
      category: SymbolCategory.stock,
      pipSize: 0.01,
      baseSize: 1,
    ),
    const TradingSymbol(
      symbol: 'MSFT',
      description: 'Microsoft Corporation',
      category: SymbolCategory.stock,
      pipSize: 0.01,
      baseSize: 1,
    ),
    const TradingSymbol(
      symbol: 'GOOGL',
      description: 'Alphabet Inc (Google)',
      category: SymbolCategory.stock,
      pipSize: 0.01,
      baseSize: 1,
    ),
    const TradingSymbol(
      symbol: 'AMZN',
      description: 'Amazon.com Inc',
      category: SymbolCategory.stock,
      pipSize: 0.01,
      baseSize: 1,
    ),
    const TradingSymbol(
      symbol: 'TSLA',
      description: 'Tesla Inc',
      category: SymbolCategory.stock,
      pipSize: 0.01,
      baseSize: 1,
    ),
    const TradingSymbol(
      symbol: 'NVDA',
      description: 'NVIDIA Corporation',
      category: SymbolCategory.stock,
      pipSize: 0.01,
      baseSize: 1,
    ),
    const TradingSymbol(
      symbol: 'META',
      description: 'Meta Platforms Inc (Facebook)',
      category: SymbolCategory.stock,
      pipSize: 0.01,
      baseSize: 1,
    ),
  ];

  static List<TradingSymbol> getByCategory(SymbolCategory category) {
    return allSymbols.where((symbol) => symbol.category == category).toList();
  }

  static List<TradingSymbol> search(String query) {
    if (query.isEmpty) return allSymbols;
    
    final String lowerQuery = query.toLowerCase();
    return allSymbols.where((symbol) {
      return symbol.symbol.toLowerCase().contains(lowerQuery) ||
          symbol.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  static TradingSymbol? findBySymbol(String symbol) {
    try {
      return allSymbols.firstWhere((s) => s.symbol.toLowerCase() == symbol.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}
