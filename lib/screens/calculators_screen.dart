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

  const CalculatorModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
  });
}

class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});

  static const List<CalculatorModel> _calculators = [
    CalculatorModel(
      title: 'Pip Calculator',
      description: 'Calculate pip value for forex pairs',
      icon: Icons.monetization_on,
      route: '/calculator/pip',
    ),
    CalculatorModel(
      title: 'Position Size Calculator',
      description: 'Calculate position size and risk',
      icon: Icons.calculate,
      route: '/calculator/position-size',
    ),
    CalculatorModel(
      title: 'Forex Rebate Calculator',
      description: 'Calculate trading rebates',
      icon: Icons.card_giftcard,
      route: '/calculator/forex-rebate',
    ),
    CalculatorModel(
      title: 'Profit Calculator',
      description: 'Calculate profit/loss on trades',
      icon: Icons.trending_up,
      route: '/calculator/profit',
    ),
    CalculatorModel(
      title: 'Compound Profit Calculator',
      description: 'Calculate compounding returns',
      icon: Icons.auto_graph,
      route: '/calculator/compound-profit',
    ),
    CalculatorModel(
      title: 'Drawdown Calculator',
      description: 'Calculate drawdown and recovery',
      icon: Icons.trending_down,
      route: '/calculator/drawdown',
    ),
    CalculatorModel(
      title: 'Risk of Ruin Calculator',
      description: 'Calculate probability of account ruin',
      icon: Icons.warning_amber,
      route: '/calculator/risk-of-ruin',
    ),
    CalculatorModel(
      title: 'Pivot Points Calculator',
      description: 'Calculate pivot points and S/R levels',
      icon: Icons.show_chart,
      route: '/calculator/pivot-points',
    ),
    CalculatorModel(
      title: 'Fibonacci Calculator',
      description: 'Calculate Fibonacci retracement levels',
      icon: Icons.timeline,
      route: '/calculator/fibonacci',
    ),
    CalculatorModel(
      title: 'Forex Margin Calculator',
      description: 'Calculate required margin',
      icon: Icons.account_balance,
      route: '/calculator/forex-margin',
    ),
    CalculatorModel(
      title: 'Crypto Exchange Fees Calculator',
      description: 'Calculate crypto trading fees',
      icon: Icons.currency_bitcoin,
      route: '/calculator/crypto-fees',
    ),
    CalculatorModel(
      title: 'Crypto & FX Converter',
      description: 'Convert between currencies',
      icon: Icons.swap_horiz,
      route: '/calculator/currency-converter',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final int calculatorCount = _calculators.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'QuickPips',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '$calculatorCount calculators',
                  style: GoogleFonts.geist(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
              },
              borderRadius: AppRadius.sm,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: AppRadius.sm,
                  border: Border.all(
                    color: AppColors.border,
                    width: 0.5,
                  ),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
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
                'CALCULATORS',
                style: GoogleFonts.geist(
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
                  style: GoogleFonts.geist(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._calculators.asMap().entries.map((entry) {
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
            HapticFeedback.lightImpact();
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
                        style: GoogleFonts.geist(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        calculator.description,
                        style: GoogleFonts.geist(
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
