import 'package:flutter/material.dart';
import '../widgets/number_input_field.dart';
import 'dart:math';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Risk of Ruin Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Row 1: Win rate & Avg profit/loss
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Win rate %', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    NumberInputField(controller: winRateController, label: '', hint: 'e.g. 50'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Avg profit/loss', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    NumberInputField(controller: avgProfitLossController, label: '', hint: 'e.g. 1'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2: Risk per trade & Number of trades
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Risk per trade %', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    NumberInputField(controller: riskPerTradeController, label: '', hint: 'e.g. 2'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Number of trades', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    NumberInputField(controller: numberOfTradesController, label: '', hint: 'e.g. 100'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Max drawdown
          Text('Max drawdown allowed %', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          NumberInputField(controller: maxDrawdownController, label: '', hint: 'e.g. 30'),
          const SizedBox(height: 24),

          // Calculate Button
          FilledButton(onPressed: calculate, child: const Text('Calculate')),

          // Error message
          if (validationMessage != null) ...[
            const SizedBox(height: 14),
            Text(validationMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],

          // Results
          if (drawdownRisk != null && ruinRisk != null) ...[
            const SizedBox(height: 24),

            // Summary Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      'Risk of peak-to-valley\ndrawdown',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${drawdownRisk!.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Risk of ruin',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${ruinRisk!.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
