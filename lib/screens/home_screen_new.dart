import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  int _selectedTabIndex = 0; // 0: Calculators, 1: News Calendar, 2: Market Watch, 3: Daily Motivations, 4: Brokers, 5: Prop Firms, 6: Contacts, 7: Settings
  late DateTime _currentTime;
  late final Timer _clockTimer;
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
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    final marketTick = MarketDataService.hasApiKey
        ? const Duration(seconds: 8)
        : const Duration(milliseconds: 1200);
    _marketTimer = Timer.periodic(marketTick, (_) => _updateMarket());
    _updateMarket();
  }

  void _updateTime() {
    if (!mounted) return;
    setState(() => _currentTime = DateTime.now());
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

    // Close drawer after selecting an item on compact layouts.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  int _mobileNavIndexForTab(int tabIndex) {
    if (tabIndex <= 4) return tabIndex;
    return 2;
  }

  int _tabIndexForMobileNav(int navIndex) {
    return navIndex;
  }

  void _openQuickActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QuickActionTile(
                  icon: Icons.calculate_outlined,
                  label: 'Calculator',
                  onTap: () {
                    Navigator.of(context).pop();
                    _onTabSelected(0);
                  },
                ),
                _QuickActionTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'News Calendar',
                  onTap: () {
                    Navigator.of(context).pop();
                    _onTabSelected(1);
                  },
                ),
                _QuickActionTile(
                  icon: Icons.candlestick_chart,
                  label: 'Market Watch',
                  onTap: () {
                    Navigator.of(context).pop();
                    _onTabSelected(2);
                  },
                ),
                _QuickActionTile(
                  icon: Icons.auto_awesome,
                  label: 'Daily Motivations',
                  onTap: () {
                    Navigator.of(context).pop();
                    _onTabSelected(3);
                  },
                ),
                _QuickActionTile(
                  icon: Icons.contact_phone_outlined,
                  label: 'Contacts',
                  onTap: () {
                    Navigator.of(context).pop();
                    _onTabSelected(6);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _marketTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;
    final isCompactMobile = screenWidth < 600;
    final sidebarWidth = (screenWidth * 0.2).clamp(180.0, 230.0);
    final location = GoRouterState.of(context).uri.path;
    final showingLocalTab = _selectedTabIndex >= 2;

    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: isMobile
          ? Drawer(
              child: SafeArea(
                child: _ToolsPanel(
                  width: 280,
                  location: location,
                  showingLocalTab: showingLocalTab,
                  selectedTabIndex: _selectedTabIndex,
                  onTabSelected: _onTabSelected,
                ),
              ),
            )
          : null,
      bottomNavigationBar: isMobile
          ? _MobileBottomNav(
              selectedIndex: _mobileNavIndexForTab(_selectedTabIndex),
              onSelected: (index) => _onTabSelected(_tabIndexForMobileNav(index)),
            )
          : null,
      body: Row(
        children: [
          // LEFT SIDEBAR - Tools/Tabs
          if (!isMobile)
            _ToolsPanel(
              width: sidebarWidth,
              location: location,
              showingLocalTab: showingLocalTab,
              selectedTabIndex: _selectedTabIndex,
              onTabSelected: _onTabSelected,
            ),

          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                // TOP BAR - Time, Search, Notifications
                Container(
                  height: isMobile ? 56 : 64,
                  color: AppColors.surface,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 24,
                    vertical: isMobile ? 8 : 12,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final showSearch = !isMobile && width >= 760;
                      final showNotification = width >= (isMobile ? 420 : 560);
                      final showDate = !isMobile && width >= 680;
                      final searchWidth = width >= 980 ? 250.0 : 180.0;

                      return Row(
                        children: [
                          if (isMobile)
                            Builder(
                              builder: (context) => IconButton(
                                icon: Icon(Icons.menu, color: AppColors.textMuted),
                                splashRadius: 20,
                                onPressed: () => Scaffold.of(context).openDrawer(),
                              ),
                            ),
                          if (isMobile) const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Trading Calculator',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isCompactMobile ? 17 : null,
                                  ),
                            ),
                          ),
                          if (showSearch) ...[
                            Container(
                              width: searchWidth,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: AppRadius.md,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (isMobile) ...[
                            IconButton(
                              tooltip: 'Quick Actions',
                              icon: Icon(Icons.search, color: AppColors.textMuted),
                              splashRadius: 20,
                              onPressed: () => _openQuickActions(context),
                            ),
                          ],
                          if (showNotification) ...[
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: AppRadius.md,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(Icons.notifications_outlined, color: AppColors.textMuted),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompactMobile ? 8 : 12,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: AppRadius.md,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('HH:mm:ss').format(_currentTime),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (showDate)
                                  Text(
                                    DateFormat('MMM dd').format(_currentTime),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                
                // MAIN CONTENT AREA
                Expanded(
                  child: _selectedTabIndex >= 2
                      ? _buildTabContent(_selectedTabIndex)
                      : widget.child,
                ),
              ],
            ),
          ),
        ],
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

class _ToolsPanel extends StatelessWidget {
  final double width;
  final String location;
  final bool showingLocalTab;
  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;

  const _ToolsPanel({
    required this.width,
    required this.location,
    required this.showingLocalTab,
    required this.selectedTabIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF08A3C), Color(0xFFE8622A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'QuickPips',
                  style: GoogleFonts.orbitron(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Tools',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          _TabButton(
            icon: Icons.calculate_outlined,
            label: 'Calculator',
            isActive: !showingLocalTab && location == '/calculators',
            onTap: () => onTabSelected(0),
          ),
          _TabButton(
            icon: Icons.calendar_month_outlined,
            label: 'News Calendar',
            isActive: !showingLocalTab && location == '/news',
            onTap: () => onTabSelected(1),
          ),
          _TabButton(
            icon: Icons.candlestick_chart,
            label: 'Market Watch',
            isActive: selectedTabIndex == 2,
            onTap: () => onTabSelected(2),
          ),
          _TabButton(
            icon: Icons.auto_awesome,
            label: 'Daily Motivations',
            isActive: selectedTabIndex == 3,
            onTap: () => onTabSelected(3),
          ),
          _TabButton(
            icon: Icons.business_outlined,
            label: 'Brokers',
            isActive: selectedTabIndex == 4,
            onTap: () => onTabSelected(4),
          ),
          _TabButton(
            icon: Icons.workspace_premium_outlined,
            label: 'Prop Firms',
            isActive: selectedTabIndex == 5,
            onTap: () => onTabSelected(5),
          ),
          const Spacer(),
          _TabButton(
            icon: Icons.contact_phone_outlined,
            label: 'Contacts',
            isActive: selectedTabIndex == 6,
            onTap: () => onTabSelected(6),
          ),
          _TabButton(
            icon: Icons.settings_outlined,
            label: 'Settings',
            isActive: selectedTabIndex == 7,
            onTap: () => onTabSelected(7),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: AppRadius.md,
          border: Border.all(
            color: isActive ? AppColors.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? AppColors.accent : AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? AppColors.accent : AppColors.textMuted,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent),
      title: Text(label),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1020;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Market Watch',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
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
              const SizedBox(height: 8),
              Text(
                'Select an instrument to view candlestick chart, current price, and history.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: 16),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Motivations',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Post quotes, mindset reminders, and optional images for your team.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
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
    );
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
