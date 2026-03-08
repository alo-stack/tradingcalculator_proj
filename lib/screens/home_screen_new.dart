import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../services/market_data_service.dart';

class HomeScreenNew extends StatefulWidget {
  final Widget child;

  const HomeScreenNew({super.key, required this.child});

  @override
  State<HomeScreenNew> createState() => _HomeScreenNewState();
}

class _HomeScreenNewState extends State<HomeScreenNew> {
  int _selectedTabIndex = 0;
  late final Timer _marketTimer;
  final Random _random = Random();
  bool _marketUpdateInProgress = false;

  final List<_InstrumentTick> _instruments = [
    _InstrumentTick(symbol: 'EURUSD', price: 1.0824),
    _InstrumentTick(symbol: 'GBPUSD', price: 1.2691),
    _InstrumentTick(symbol: 'XAUUSD', price: 2144.85),
    _InstrumentTick(symbol: 'BTCUSD', price: 62450.0),
    _InstrumentTick(symbol: 'ETHUSD', price: 3410.20),
    _InstrumentTick(symbol: 'US100', price: 18024.5),
  ];

  @override
  void initState() {
    super.initState();
    final marketTick = MarketDataService.hasApiKey
        ? const Duration(seconds: 8)
        : const Duration(milliseconds: 1200);
    _marketTimer = Timer.periodic(marketTick, (_) => _updateMarket());
    _updateMarket();
  }

  Future<void> _updateMarket() async {
    if (!mounted || _marketUpdateInProgress) return;

    _marketUpdateInProgress = true;
    try {
      if (!MarketDataService.hasApiKey) {
        _updateMarketFallback();
        return;
      }

      final quoteResults = await Future.wait(
        _instruments.map((instrument) async {
          final apiSymbol = _toApiSymbol(instrument.symbol);
          final price = await MarketDataService.fetchPrice(symbol: apiSymbol);
          return (instrument, price);
        }),
      );

      if (!mounted) return;
      var anyLiveUpdate = false;

      setState(() {
        for (final result in quoteResults) {
          final instrument = result.$1;
          final livePrice = result.$2;
          if (livePrice == null) continue;

          anyLiveUpdate = true;
          instrument.price = livePrice;
          instrument.history.add(livePrice);
          if (instrument.history.length > 40) {
            instrument.history.removeAt(0);
          }
        }
      });

      if (!anyLiveUpdate) {
        _updateMarketFallback();
      }
    } finally {
      _marketUpdateInProgress = false;
    }
  }

  void _updateMarketFallback() {
    if (!mounted) return;

    setState(() {
      for (final instrument in _instruments) {
        final volatility = instrument.symbol.contains('BTC') || instrument.symbol.contains('ETH') ? 0.007 : 0.0018;
        final drift = (_random.nextDouble() - 0.5) * volatility;
        instrument.price = instrument.price * (1 + drift);
        instrument.history.add(instrument.price);
        if (instrument.history.length > 40) {
          instrument.history.removeAt(0);
        }
      }
    });
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTabIndex = index);
    if (index == 0) {
      context.go('/calculators');
    } else if (index == 1) {
      context.go('/news');
    }
  }

  @override
  void dispose() {
    _marketTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: _MobileBottomNav(
        selectedIndex: _selectedTabIndex <= 4 ? _selectedTabIndex : 2,
        onSelected: _onTabSelected,
      ),
      body: SafeArea(
        child: _selectedTabIndex >= 2
            ? _buildTabContent(_selectedTabIndex)
            : widget.child,
      ),
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 2:
        return _MarketWatchTab(instruments: _instruments);
      case 3:
        return const _DailyMotivationsTab();
      case 4:
        return const _ComingSoonTab(
          icon: Icons.business_outlined,
          title: 'Brokers Coming Soon',
          message: 'Broker comparison and ratings are currently in development.',
        );
      case 5:
        return const _ComingSoonTab(
          icon: Icons.workspace_premium_outlined,
          title: 'Prop Firms Coming Soon',
          message: 'Prop firm analytics and comparison tools are in active development.',
        );
      case 6:
        return const _ComingSoonTab(
          icon: Icons.contact_phone_outlined,
          title: 'Contacts Coming Soon',
          message: 'Social media links, email, and phone contact details will be available soon.',
        );
      case 7:
        return const _ComingSoonTab(
          icon: Icons.settings_outlined,
          title: 'Settings Coming Soon',
          message: 'Platform and profile settings will be available in the next release.',
        );
      default:
        return const SizedBox();
    }
  }
}

class _MobileBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _MobileBottomNav({required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accent.withValues(alpha: 0.16),
      onDestinationSelected: onSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.calculate_outlined),
          selectedIcon: Icon(Icons.calculate),
          label: 'Calc',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'News',
        ),
        NavigationDestination(
          icon: Icon(Icons.candlestick_chart),
          selectedIcon: Icon(Icons.candlestick_chart),
          label: 'Market',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: 'Daily',
        ),
        NavigationDestination(
          icon: Icon(Icons.business_outlined),
          selectedIcon: Icon(Icons.business),
          label: 'Brokers',
        ),
      ],
    );
  }
}

class _MarketWatchTab extends StatefulWidget {
  final List<_InstrumentTick> instruments;

  const _MarketWatchTab({required this.instruments});

  @override
  State<_MarketWatchTab> createState() => _MarketWatchTabState();
}

class _MarketWatchTabState extends State<_MarketWatchTab> {
  static const List<String> _intervals = ['1min', '5min', '15min', '1h', '4h', '1day', '1week'];

  String _selectedSymbol = '';
  String _selectedInterval = '5min';
  List<MarketCandle> _candles = const [];
  bool _loadingCandles = true;
  bool _usingLiveData = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (widget.instruments.isNotEmpty) {
      _selectedSymbol = widget.instruments.first.symbol;
    }

    _refreshCandles();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _refreshCandles());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshCandles() async {
    if (_selectedSymbol.isEmpty) return;

    setState(() => _loadingCandles = true);
    final candles = await MarketDataService.fetchCandles(
      symbol: _toApiSymbol(_selectedSymbol),
      interval: _selectedInterval,
      outputSize: 80,
    );

    if (!mounted) return;

    final useLive = candles.isNotEmpty;
    final fallbackCount = _pointsForInterval(_selectedInterval);
    setState(() {
      _usingLiveData = useLive;
      _candles = useLive
          ? candles
          : _generateFallbackCandles(
              symbol: _selectedSymbol,
              basePrice: _selectedInstrument?.price ?? 1,
              interval: _selectedInterval,
              points: fallbackCount,
            );
      _loadingCandles = false;
    });
  }

  _InstrumentTick? get _selectedInstrument {
    for (final instrument in widget.instruments) {
      if (instrument.symbol == _selectedSymbol) return instrument;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedInstrument;
    final selectedPrice = selected?.price ?? 0;
    final selectedChange = selected?.changePct ?? 0;

    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _MarketWatchHeaderDelegate(
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
                      'MARKET WATCH',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _usingLiveData ? AppColors.positiveBg : AppColors.surfaceHigh,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      _usingLiveData ? 'Live (Twelve Data)' : 'Fallback Data',
                      style: TextStyle(
                        fontSize: 11,
                        color: _usingLiveData ? AppColors.positive : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1020;

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 300,
                            child: _buildWatchlist(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildChartCard(selectedPrice, selectedChange),
                          ),
                        ],
                      )
                    else ...[
                      _buildChartCard(selectedPrice, selectedChange),
                      const SizedBox(height: 16),
                      _buildWatchlist(),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWatchlist() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Watchlist',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.instruments.map((instrument) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _MarketInstrumentCard(
                instrument: instrument,
                isSelected: instrument.symbol == _selectedSymbol,
                onTap: () {
                  setState(() => _selectedSymbol = instrument.symbol);
                  _refreshCandles();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChartCard(double selectedPrice, double selectedChange) {
    final selectedCandle = _candles.isNotEmpty ? _candles.last : null;
    final positive = selectedChange >= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;

              final intervalChips = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _intervals.map((interval) {
                  final selected = interval == _selectedInterval;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedInterval = interval);
                      _refreshCandles();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accentSurface : AppColors.bg,
                        borderRadius: AppRadius.sm,
                        border: Border.all(
                          color: selected ? AppColors.accent : AppColors.border,
                        ),
                      ),
                      child: Text(
                        interval,
                        style: TextStyle(
                          fontSize: 11,
                          color: selected ? AppColors.accent : AppColors.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _selectedSymbol,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          _formatInstrumentPrice(_selectedSymbol, selectedPrice),
                          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                        ),
                        Text(
                          '${positive ? '+' : ''}${selectedChange.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: positive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: intervalChips,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Text(
                    _selectedSymbol,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatInstrumentPrice(_selectedSymbol, selectedPrice),
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${positive ? '+' : ''}${selectedChange.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: positive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: intervalChips,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            width: double.infinity,
            child: _loadingCandles
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _candles.isEmpty
                    ? Center(
                        child: Text(
                          'No chart data available for $_selectedSymbol',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : CustomPaint(
                        key: ValueKey('$_selectedSymbol-$_selectedInterval-${_candles.length}'),
                        painter: _CandlestickPainter(candles: _candles),
                      ),
          ),
          const SizedBox(height: 10),
          if (selectedCandle != null)
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _StatPill(label: 'Open', value: selectedCandle.open.toStringAsFixed(4)),
                _StatPill(label: 'High', value: selectedCandle.high.toStringAsFixed(4)),
                _StatPill(label: 'Low', value: selectedCandle.low.toStringAsFixed(4)),
                _StatPill(label: 'Close', value: selectedCandle.close.toStringAsFixed(4)),
              ],
            ),
        ],
      ),
    );
  }

  List<MarketCandle> _generateFallbackCandles({
    required String symbol,
    required double basePrice,
    required String interval,
    required int points,
  }) {
    final random = Random(Object.hash(symbol, interval));
    final result = <MarketCandle>[];
    var previousClose = basePrice;
    final now = DateTime.now();

    for (var i = points; i >= 0; i--) {
      final time = now.subtract(_intervalDuration(interval, i));
      final volatility = _volatilityForInterval(symbol, interval);
      final open = previousClose;
      final close = open * (1 + ((random.nextDouble() - 0.5) * volatility));
      final high = max(open, close) * (1 + random.nextDouble() * volatility * 0.4);
      final low = min(open, close) * (1 - random.nextDouble() * volatility * 0.4);

      result.add(MarketCandle(
        time: time,
        open: open,
        high: high,
        low: low,
        close: close,
      ));
      previousClose = close;
    }

    return result;
  }

  int _pointsForInterval(String interval) {
    switch (interval) {
      case '1min':
        return 120;
      case '5min':
        return 100;
      case '15min':
        return 96;
      case '1h':
        return 96;
      case '4h':
        return 84;
      case '1day':
        return 90;
      case '1week':
        return 78;
      default:
        return 80;
    }
  }

  double _volatilityForInterval(String symbol, String interval) {
    final base = symbol.contains('BTC') || symbol.contains('ETH') ? 0.012 : 0.0025;
    switch (interval) {
      case '1min':
        return base * 0.65;
      case '5min':
        return base * 0.85;
      case '15min':
        return base;
      case '1h':
        return base * 1.3;
      case '4h':
        return base * 1.7;
      case '1day':
        return base * 2.2;
      case '1week':
        return base * 2.8;
      default:
        return base;
    }
  }

  Duration _intervalDuration(String interval, int stepsBack) {
    switch (interval) {
      case '1min':
        return Duration(minutes: stepsBack);
      case '5min':
        return Duration(minutes: stepsBack * 5);
      case '15min':
        return Duration(minutes: stepsBack * 15);
      case '1h':
        return Duration(hours: stepsBack);
      case '4h':
        return Duration(hours: stepsBack * 4);
      case '1day':
        return Duration(days: stepsBack);
      case '1week':
        return Duration(days: stepsBack * 7);
      default:
        return Duration(minutes: stepsBack * 5);
    }
  }
}

class _MarketWatchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _MarketWatchHeaderDelegate({required this.child});

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
  bool shouldRebuild(_MarketWatchHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _MarketInstrumentCard extends StatelessWidget {
  final _InstrumentTick instrument;
  final bool isSelected;
  final VoidCallback onTap;

  const _MarketInstrumentCard({
    required this.instrument,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = instrument.changePct >= 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.md,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentSurface : AppColors.bg,
            borderRadius: AppRadius.md,
            border: Border.all(color: isSelected ? AppColors.accent : AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    instrument.symbol,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${instrument.changePct.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatInstrumentPrice(instrument.symbol, instrument.price),
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                width: double.infinity,
                child: CustomPaint(
                  painter: _MiniCandlestickPainter(
                    candles: _buildMiniCandles(instrument.history),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<MarketCandle> _buildMiniCandles(List<double> history) {
  if (history.length < 2) return const [];

  final candles = <MarketCandle>[];
  final now = DateTime.now();
  for (var i = 1; i < history.length; i++) {
    final open = history[i - 1];
    final close = history[i];
    final high = max(open, close) * 1.0008;
    final low = min(open, close) * 0.9992;

    candles.add(
      MarketCandle(
        time: now.subtract(Duration(minutes: history.length - i)),
        open: open,
        high: high,
        low: low,
        close: close,
      ),
    );
  }

  return candles;
}

class _MiniCandlestickPainter extends CustomPainter {
  final List<MarketCandle> candles;

  _MiniCandlestickPainter({required this.candles});

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final minPrice = candles.map((c) => c.low).reduce(min);
    final maxPrice = candles.map((c) => c.high).reduce(max);
    final range = (maxPrice - minPrice).abs() < 0.0000001 ? 1.0 : (maxPrice - minPrice);

    final candleSpace = size.width / candles.length;
    final bodyWidth = max(1.4, candleSpace * 0.5);

    for (var i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = (i * candleSpace) + (candleSpace / 2);

      final yHigh = size.height - ((candle.high - minPrice) / range * size.height);
      final yLow = size.height - ((candle.low - minPrice) / range * size.height);
      final yOpen = size.height - ((candle.open - minPrice) / range * size.height);
      final yClose = size.height - ((candle.close - minPrice) / range * size.height);
      final bullish = candle.close >= candle.open;

      final wickPaint = Paint()
        ..color = bullish ? Colors.green : Colors.red
        ..strokeWidth = 1;
      canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), wickPaint);

      final top = min(yOpen, yClose);
      final bottom = max(yOpen, yClose);
      final bodyHeight = max(1.0, bottom - top);
      final bodyPaint = Paint()
        ..color = bullish ? Colors.green : Colors.red
        ..style = PaintingStyle.fill;

      final rect = Rect.fromCenter(
        center: Offset(x, top + bodyHeight / 2),
        width: bodyWidth,
        height: bodyHeight,
      );
      canvas.drawRect(rect, bodyPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniCandlestickPainter oldDelegate) {
    return oldDelegate.candles != candles;
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CandlestickPainter extends CustomPainter {
  final List<MarketCandle> candles;

  _CandlestickPainter({required this.candles});

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final minPrice = candles.map((c) => c.low).reduce(min);
    final maxPrice = candles.map((c) => c.high).reduce(max);
    final range = (maxPrice - minPrice).abs() < 0.0000001 ? 1.0 : (maxPrice - minPrice);

    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final candleSpace = size.width / candles.length;
    final bodyWidth = max(2.0, candleSpace * 0.55);

    for (var i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = (i * candleSpace) + (candleSpace / 2);

      final yHigh = size.height - ((candle.high - minPrice) / range * size.height);
      final yLow = size.height - ((candle.low - minPrice) / range * size.height);
      final yOpen = size.height - ((candle.open - minPrice) / range * size.height);
      final yClose = size.height - ((candle.close - minPrice) / range * size.height);
      final bullish = candle.close >= candle.open;

      final wickPaint = Paint()
        ..color = bullish ? Colors.green : Colors.red
        ..strokeWidth = 1;
      canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), wickPaint);

      final bodyTop = min(yOpen, yClose);
      final bodyBottom = max(yOpen, yClose);
      final bodyHeight = max(1.2, bodyBottom - bodyTop);
      final bodyRect = Rect.fromCenter(
        center: Offset(x, bodyTop + bodyHeight / 2),
        width: bodyWidth,
        height: bodyHeight,
      );

      final bodyPaint = Paint()
        ..color = bullish ? Colors.green : Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, const Radius.circular(1.2)),
        bodyPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter oldDelegate) {
    return oldDelegate.candles != candles;
  }
}

class _InstrumentTick {
  final String symbol;
  final double openPrice;
  double price;
  final List<double> history;

  _InstrumentTick({required this.symbol, required this.price})
      : openPrice = price,
        history = [price];

  double get changePct => ((price - openPrice) / openPrice) * 100;
}

const Map<String, String> _symbolToApiSymbol = {
  'EURUSD': 'EUR/USD',
  'GBPUSD': 'GBP/USD',
  'XAUUSD': 'XAU/USD',
  'BTCUSD': 'BTC/USD',
  'ETHUSD': 'ETH/USD',
  'US100': 'NDX',
};

String _toApiSymbol(String symbol) {
  return _symbolToApiSymbol[symbol] ?? symbol;
}

String _formatInstrumentPrice(String symbol, double value) {
  if (symbol.contains('BTC') || symbol.contains('ETH')) {
    return value >= 1000 ? '\$${NumberFormat('#,##0.00').format(value)}' : '\$${value.toStringAsFixed(2)}';
  }
  if (symbol.contains('XAU') || symbol.contains('US')) {
    return value.toStringAsFixed(2);
  }
  return value.toStringAsFixed(5);
}

class _DailyMotivationsTab extends StatefulWidget {
  const _DailyMotivationsTab();

  @override
  State<_DailyMotivationsTab> createState() => _DailyMotivationsTabState();
}

class _DailyMotivationsTabState extends State<_DailyMotivationsTab> {
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  final List<_MotivationPost> _posts = [
    const _MotivationPost(
      quote: 'Discipline is choosing between what you want now and what you want most.',
      author: 'Abraham Lincoln',
      imageUrl: '',
    ),
    const _MotivationPost(
      quote: 'Risk comes from not knowing what you are doing.',
      author: 'Warren Buffett',
      imageUrl: '',
    ),
  ];

  @override
  void dispose() {
    _quoteController.dispose();
    _authorController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _addPost() {
    final quote = _quoteController.text.trim();
    final author = _authorController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    if (quote.isEmpty) return;

    setState(() {
      _posts.insert(
        0,
        _MotivationPost(
          quote: quote,
          author: author.isEmpty ? 'Team QuickPips' : author,
          imageUrl: imageUrl,
        ),
      );
    });

    _quoteController.clear();
    _authorController.clear();
    _imageUrlController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _DailyMotivationsHeaderDelegate(
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
              child: Center(
                child: Text(
                  'DAILY MOTIVATIONS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _quoteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Write a motivational quote...',
                          filled: true,
                          fillColor: AppColors.bg,
                          border: OutlineInputBorder(borderRadius: AppRadius.sm),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _authorController,
                        decoration: InputDecoration(
                          hintText: 'Author (optional)',
                          filled: true,
                          fillColor: AppColors.bg,
                          border: OutlineInputBorder(borderRadius: AppRadius.sm),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _imageUrlController,
                        decoration: InputDecoration(
                          hintText: 'Image URL (optional)',
                          filled: true,
                          fillColor: AppColors.bg,
                          border: OutlineInputBorder(borderRadius: AppRadius.sm),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addPost,
                          icon: const Icon(Icons.post_add),
                          label: const Text('Post Motivation'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ..._posts.map((post) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.md,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (post.imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: AppRadius.sm,
                            child: Image.network(
                              post.imageUrl,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 120,
                                color: AppColors.bg,
                                alignment: Alignment.center,
                                child: Text('Unable to load image', style: TextStyle(color: AppColors.textMuted)),
                              ),
                            ),
                          ),
                        if (post.imageUrl.isNotEmpty) const SizedBox(height: 10),
                        Text(
                          '"${post.quote}"',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '- ${post.author}',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyMotivationsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _DailyMotivationsHeaderDelegate({required this.child});

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
  bool shouldRebuild(_DailyMotivationsHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _MotivationPost {
  final String quote;
  final String author;
  final String imageUrl;

  const _MotivationPost({
    required this.quote,
    required this.author,
    required this.imageUrl,
  });
}

class _ComingSoonTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ComingSoonTab({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
