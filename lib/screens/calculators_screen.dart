import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';

class CalculatorModel {
  final String title;
  final String description;
  final IconData icon;
  final String route;
  final CalculatorCategory category;

  const CalculatorModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
    required this.category,
  });
}

enum CalculatorCategory { forex, crypto, futures }

class CalculatorsScreen extends StatefulWidget {
  const CalculatorsScreen({super.key});

  @override
  State<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends State<CalculatorsScreen> {
  CalculatorCategory _selectedCategory = CalculatorCategory.forex;

  static const List<CalculatorModel> _calculators = [
    CalculatorModel(
      title: 'Pip Calculator',
      description: 'Calculate pip value for forex pairs',
      icon: Icons.monetization_on,
      route: '/calculator/pip',
      category: CalculatorCategory.forex,
    ),
    CalculatorModel(
      title: 'Position Size Calculator',
      description: 'Calculate position size and risk',
      icon: Icons.calculate,
      route: '/calculator/position-size',
      category: CalculatorCategory.forex,
    ),
    CalculatorModel(
      title: 'Forex Rebate Calculator',
      description: 'Calculate trading rebates',
      icon: Icons.card_giftcard,
      route: '/calculator/forex-rebate',
      category: CalculatorCategory.forex,
    ),
    CalculatorModel(
      title: 'Profit Calculator',
      description: 'Calculate profit/loss on trades',
      icon: Icons.trending_up,
      route: '/calculator/profit',
      category: CalculatorCategory.forex,
    ),
    CalculatorModel(
      title: 'Compound Profit Calculator',
      description: 'Calculate compounding returns',
      icon: Icons.auto_graph,
      route: '/calculator/compound-profit',
      category: CalculatorCategory.forex,
    ),
    CalculatorModel(
      title: 'Drawdown Calculator',
      description: 'Calculate drawdown and recovery',
      icon: Icons.trending_down,
      route: '/calculator/drawdown',
      category: CalculatorCategory.forex,
    ),
    CalculatorModel(
      title: 'Risk of Ruin Calculator',
      description: 'Calculate probability of account ruin',
      icon: Icons.warning_amber,
      route: '/calculator/risk-of-ruin',
      category: CalculatorCategory.forex,
    ),
    CalculatorModel(
      title: 'Pivot Points Calculator',
      description: 'Calculate pivot points and S/R levels',
      icon: Icons.show_chart,
      route: '/calculator/pivot-points',
      category: CalculatorCategory.forex,
    ),
    CalculatorModel(
      title: 'Fibonacci Calculator',
      description: 'Calculate Fibonacci retracement levels',
      icon: Icons.timeline,
      route: '/calculator/fibonacci',
      category: CalculatorCategory.forex,
    ),
    CalculatorModel(
      title: 'Forex Margin Calculator',
      description: 'Calculate required margin',
      icon: Icons.account_balance,
      route: '/calculator/forex-margin',
      category: CalculatorCategory.forex,
    ),
    CalculatorModel(
      title: 'Crypto Exchange Fees Calculator',
      description: 'Calculate crypto trading fees',
      icon: Icons.currency_bitcoin,
      route: '/calculator/crypto-fees',
      category: CalculatorCategory.crypto,
    ),
    CalculatorModel(
      title: 'Crypto & FX Converter',
      description: 'Convert between currencies',
      icon: Icons.swap_horiz,
      route: '/calculator/currency-converter',
      category: CalculatorCategory.crypto,
    ),
    CalculatorModel(
      title: 'Futures Calculators',
      description: 'Risk, margin, and contract tools for futures',
      icon: Icons.candlestick_chart,
      route: '/calculator/futures',
      category: CalculatorCategory.futures,
    ),
  ];

  List<CalculatorModel> get _visibleCalculators {
    return _calculators.where((c) => c.category == _selectedCategory).toList();
  }

  int _countBy(CalculatorCategory category) {
    return _calculators.where((c) => c.category == category).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // Pinned category buttons
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryHeaderDelegate(
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
                        'CALCULATORS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          color: const Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _FilterPill(
                                  label: 'FOREX',
                                  count: _countBy(CalculatorCategory.forex),
                                  isActive:
                                      _selectedCategory == CalculatorCategory.forex,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(
                                      () => _selectedCategory =
                                          CalculatorCategory.forex,
                                    );
                                  },
                                ),
                                _FilterPill(
                                  label: 'CRYPTO',
                                  count: _countBy(CalculatorCategory.crypto),
                                  isActive:
                                      _selectedCategory ==
                                      CalculatorCategory.crypto,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(
                                      () => _selectedCategory =
                                          CalculatorCategory.crypto,
                                    );
                                  },
                                ),
                                _FilterPill(
                                  label: 'FUTURES',
                                  count: _countBy(CalculatorCategory.futures),
                                  isActive:
                                      _selectedCategory ==
                                      CalculatorCategory.futures,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(
                                      () => _selectedCategory =
                                          CalculatorCategory.futures,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Calculator cards
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final CalculatorModel calculator = _visibleCalculators[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: index == 0 ? AppSpacing.sm : 0,
                  bottom: AppSpacing.sm,
                ),
                child: _CalculatorCard(calculator: calculator)
                    .animate(delay: Duration(milliseconds: index * 55))
                    .fadeIn(duration: 250.ms)
                    .slideY(begin: 0.05, curve: Curves.easeOut),
              );
            }, childCount: _visibleCalculators.length),
          ),
          // Bottom padding
          SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _CategoryHeaderDelegate({required this.child});

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
  bool shouldRebuild(_CategoryHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.only(left: 10, right: 7, top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2A1810) : const Color(0xFF1C1C1E),
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: isActive ? const Color(0xFFE8622A) : const Color(0xFF2C2C2E),
            width: isActive ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.1,
                color: isActive
                    ? const Color(0xFFE8622A)
                    : const Color(0xFF8E8E93),
              ),
              child: Text(label),
            ),
            const SizedBox(width: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minWidth: 20),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFE8622A).withValues(alpha: 0.18)
                    : const Color(0xFF252527),
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? const Color(0xFFE8622A)
                      : const Color(0xFF48484A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculatorCard extends StatelessWidget {
  final CalculatorModel calculator;

  const _CalculatorCard({required this.calculator});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push(calculator.route);
          },
          borderRadius: AppRadius.md,
          splashColor: Colors.transparent,
          highlightColor: AppColors.inkwellHighlight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface,
                    borderRadius: AppRadius.sm,
                  ),
                  child: Icon(
                    calculator.icon,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        calculator.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        calculator.description,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: AppRadius.xs,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
