import 'package:flutter/material.dart';
import 'dart:math';
import '../../core/app_theme.dart';
import '../../widgets/calculator_components.dart';

class RiskOfRuinCalculatorScreen extends StatefulWidget {
  const RiskOfRuinCalculatorScreen({super.key});

  @override
  State<RiskOfRuinCalculatorScreen> createState() => _RiskOfRuinCalculatorScreenState();
}

class _RiskOfRuinCalculatorScreenState extends State<RiskOfRuinCalculatorScreen> {
  final TextEditingController winRateController = TextEditingController(text: '50');
  final TextEditingController avgProfitLossController = TextEditingController(text: '1');
  final TextEditingController riskPerTradeController = TextEditingController(text: '2');
  final TextEditingController numberOfTradesController = TextEditingController(text: '100');
  final TextEditingController maxDrawdownController = TextEditingController(text: '30');

  String? validationMessage;
  double? drawdownRisk;
  double? ruinRisk;

  @override
  void dispose() {
    winRateController.dispose();
    avgProfitLossController.dispose();
    riskPerTradeController.dispose();
    numberOfTradesController.dispose();
    maxDrawdownController.dispose();
    super.dispose();
  }

  void calculate() {
    final double? winRate = double.tryParse(winRateController.text);
    final double? avgProfitLoss = double.tryParse(avgProfitLossController.text);
    final double? riskPerTrade = double.tryParse(riskPerTradeController.text);
    final int? numTrades = int.tryParse(numberOfTradesController.text);
    final double? maxDrawdown = double.tryParse(maxDrawdownController.text);

    if (winRate == null || avgProfitLoss == null || riskPerTrade == null || numTrades == null || maxDrawdown == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        drawdownRisk = null;
        ruinRisk = null;
      });
      return;
    }

    if (winRate < 0 || winRate > 100 || avgProfitLoss < 0 || riskPerTrade < 0 || numTrades <= 0 || maxDrawdown < 0 || maxDrawdown > 100) {
      setState(() {
        validationMessage = 'Please enter valid positive numbers.';
        drawdownRisk = null;
        ruinRisk = null;
      });
      return;
    }

    try {
      // Run Monte Carlo simulation
      final Map<String, double> results = _monteCarloSimulation(
        winRate: winRate,
        avgProfitLoss: avgProfitLoss,
        riskPerTrade: riskPerTrade,
        numTrades: numTrades,
        maxDrawdown: maxDrawdown,
      );

      setState(() {
        validationMessage = null;
        drawdownRisk = results['drawdownRisk'];
        ruinRisk = results['ruinRisk'];
      });
    } catch (error) {
      setState(() {
        validationMessage = error.toString();
        drawdownRisk = null;
        ruinRisk = null;
      });
    }
  }

  Map<String, double> _monteCarloSimulation({
    required double winRate,
    required double avgProfitLoss,
    required double riskPerTrade,
    required int numTrades,
    required double maxDrawdown,
  }) {
    final int simulations = 10000; // Run 10,000 simulations for balance between accuracy and performance
    final double winRateDecimal = winRate / 100.0;
    final double maxDrawdownDecimal = maxDrawdown / 100.0;
    final double riskDecimal = riskPerTrade / 100.0;

    int drawdownHits = 0;
    int ruinHits = 0;

    final Random random = Random();

    for (int sim = 0; sim < simulations; sim++) {
      double equity = 1.0; // Start with equity of 1.0 (100%)
      double peakEquity = 1.0;
      bool hitDrawdown = false;
      bool hitRuin = false;

      for (int trade = 0; trade < numTrades; trade++) {
        final bool isWin = random.nextDouble() < winRateDecimal;
        double tradeReturn;

        if (isWin) {
          // Win amount = risk per trade × profit factor
          // E.g., if risking 2% with 1:1 ratio, gain 2%
          // If risking 2% with 2:1 ratio, gain 4%
          tradeReturn = riskDecimal * avgProfitLoss;
        } else {
          // Loss is always the fixed risk amount
          tradeReturn = -riskDecimal;
        }

        equity += equity * tradeReturn;

        // Track peak for drawdown calculation
        if (equity > peakEquity) {
          peakEquity = equity;
        }

        // Check for peak-to-valley drawdown
        final double drawdownFromPeak = (peakEquity - equity) / peakEquity;
        if (drawdownFromPeak >= maxDrawdownDecimal) {
          hitDrawdown = true;
        }

        // Check if equity dropped below starting equity minus max drawdown
        // Risk of ruin: probability of losing max_drawdown % of starting equity
        if (equity <= (1.0 - maxDrawdownDecimal)) {
          hitRuin = true;
          break; // Once account is ruined, stop simulation for this trade sequence
        }
      }

      if (hitDrawdown) {
        drawdownHits++;
      }
      if (hitRuin) {
        ruinHits++;
      }
    }

    final double drawdownPercentage = (drawdownHits / simulations) * 100.0;
    final double ruinPercentage = (ruinHits / simulations) * 100.0;

    return {
      'drawdownRisk': drawdownPercentage,
      'ruinRisk': ruinPercentage,
    };
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorScaffold(
      title: 'Risk of Ruin Calculator',
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 0,
        ),
        children: [
          CalculatorSection(
            title: 'Input Parameters',
            children: [
              Row(
                children: [
                  Expanded(
                    child: CalculatorInputField(
                      label: 'Win rate %',
                      controller: winRateController,
                      hint: 'e.g. 50',
                      suffix: '%',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CalculatorInputField(
                      label: 'Avg profit/loss',
                      controller: avgProfitLossController,
                      hint: 'e.g. 1',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: CalculatorInputField(
                      label: 'Risk per trade %',
                      controller: riskPerTradeController,
                      hint: 'e.g. 2',
                      suffix: '%',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CalculatorInputField(
                      label: 'Number of trades',
                      controller: numberOfTradesController,
                      hint: 'e.g. 100',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              CalculatorInputField(
                label: 'Max drawdown allowed %',
                controller: maxDrawdownController,
                hint: 'e.g. 30',
                suffix: '%',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          CalculateButton(onPressed: calculate),
          if (validationMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            MessageBanner(message: validationMessage!),
          ],
          if (drawdownRisk != null && ruinRisk != null) ...[
            const SizedBox(height: AppSpacing.xl),
            CalculatorSection(
              title: 'Results',
              children: [
                ResultRow(
                  label: 'Risk of peak-to-valley drawdown',
                  value: '${drawdownRisk!.toStringAsFixed(1)}%',
                  isNegative: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                ResultRow(
                  label: 'Risk of ruin',
                  value: '${ruinRisk!.toStringAsFixed(1)}%',
                  isNegative: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
