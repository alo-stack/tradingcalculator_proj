import 'package:flutter/material.dart';
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

  String get _categoryLabel {
    switch (_selectedCategory) {
      case CalculatorCategory.forex:
        return 'FOREX';
      case CalculatorCategory.crypto:
        return 'CRYPTO';
      case CalculatorCategory.futures:
        return 'FUTURES';
    }
  }

  @override
  Widget build(BuildContext context) {
    final int calculatorCount = _visibleCalculators.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Calculators',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '$calculatorCount calculators',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            children: [
              Text(
                '$_categoryLabel CALCULATORS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfacePill,
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  '$calculatorCount',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _CategoryButton(
                  label: 'FOREX',
                  count: _countBy(CalculatorCategory.forex),
                  selected: _selectedCategory == CalculatorCategory.forex,
                  onTap: () => setState(() => _selectedCategory = CalculatorCategory.forex),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _CategoryButton(
                  label: 'CRYPTO',
                  count: _countBy(CalculatorCategory.crypto),
                  selected: _selectedCategory == CalculatorCategory.crypto,
                  onTap: () => setState(() => _selectedCategory = CalculatorCategory.crypto),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _CategoryButton(
                  label: 'FUTURES',
                  count: _countBy(CalculatorCategory.futures),
                  selected: _selectedCategory == CalculatorCategory.futures,
                  onTap: () => setState(() => _selectedCategory = CalculatorCategory.futures),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._visibleCalculators.asMap().entries.map((entry) {
            final int index = entry.key;
            final CalculatorModel calculator = entry.value;

            return _CalculatorCard(calculator: calculator)
                .animate(delay: Duration(milliseconds: index * 55))
                .fadeIn(duration: 250.ms)
                .slideY(begin: 0.05, curve: Curves.easeOut);
          }),
          const SizedBox(height: 96),
        ],
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.sm,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSurface : AppColors.surface,
            borderRadius: AppRadius.sm,
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 1.0 : 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.accent : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent.withValues(alpha: 0.15) : AppColors.surfaceHigh,
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: selected ? AppColors.accent : AppColors.textMuted,
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

class _CalculatorCard extends StatelessWidget {
  final CalculatorModel calculator;

  const _CalculatorCard({required this.calculator});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
