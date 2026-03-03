import 'package:flutter/material.dart';
import '../widgets/number_input_field.dart';

class DrawdownCalculatorScreen extends StatefulWidget {
  const DrawdownCalculatorScreen({super.key});

  @override
  State<DrawdownCalculatorScreen> createState() => _DrawdownCalculatorScreenState();
}

class _DrawdownCalculatorScreenState extends State<DrawdownCalculatorScreen> {
  final TextEditingController startingBalanceController = TextEditingController(text: '20000');
  final TextEditingController consecutiveLossesController = TextEditingController(text: '10');
  final TextEditingController lossPercentController = TextEditingController(text: '2');

  String? validationMessage;
  double? endingBalance;
  double? totalLossPercent;
  List<Map<String, dynamic>>? periodBreakdown;

  @override
  void dispose() {
    startingBalanceController.dispose();
    consecutiveLossesController.dispose();
    lossPercentController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _calculateDrawdownBreakdown(
    double startingBalance,
    int consecutiveLosses,
    double lossPercent,
  ) {
    final List<Map<String, dynamic>> breakdown = [];
    double balance = startingBalance;

    for (int i = 1; i <= consecutiveLosses; i++) {
      final double previousBalance = balance;
      final double loss = previousBalance * (lossPercent / 100);
      balance = previousBalance - loss;

      breakdown.add({
        'period': i,
        'starting': previousBalance,
        'loss_percent': lossPercent,
        'ending': balance,
      });
    }

    return breakdown;
  }

  void calculate() {
    final double? startingBalance = double.tryParse(startingBalanceController.text);
    final int? consecutiveLosses = int.tryParse(consecutiveLossesController.text);
    final double? lossPercent = double.tryParse(lossPercentController.text);

    if (startingBalance == null || consecutiveLosses == null || lossPercent == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        endingBalance = null;
        totalLossPercent = null;
        periodBreakdown = null;
      });
      return;
    }

    if (startingBalance <= 0 || consecutiveLosses <= 0 || lossPercent < 0) {
      setState(() {
        validationMessage = 'Please enter positive numbers.';
        endingBalance = null;
        totalLossPercent = null;
        periodBreakdown = null;
      });
      return;
    }

    try {
      final List<Map<String, dynamic>> breakdown = _calculateDrawdownBreakdown(
        startingBalance,
        consecutiveLosses,
        lossPercent,
      );

      double finalBalance = startingBalance;
      for (int i = 0; i < consecutiveLosses; i++) {
        finalBalance = finalBalance * (1 - lossPercent / 100);
      }

      final double totalLoss = ((startingBalance - finalBalance) / startingBalance) * 100;

      setState(() {
        validationMessage = null;
        endingBalance = finalBalance;
        totalLossPercent = totalLoss;
        periodBreakdown = breakdown;
      });
    } catch (error) {
      setState(() {
        validationMessage = error.toString();
        endingBalance = null;
        totalLossPercent = null;
        periodBreakdown = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forex Drawdown Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Row 1: Starting balance & Consecutive losses
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Starting balance', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    NumberInputField(controller: startingBalanceController, label: '', hint: 'e.g. 20000'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Consecutive losses', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    NumberInputField(controller: consecutiveLossesController, label: '', hint: 'e.g. 10'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Loss % per trade
          Text('Loss % per trade', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          NumberInputField(controller: lossPercentController, label: '', hint: 'e.g. 2'),
          const SizedBox(height: 24),

          // Calculate Button
          FilledButton(onPressed: calculate, child: const Text('Calculate')),

          // Error message
          if (validationMessage != null) ...[
            const SizedBox(height: 14),
            Text(validationMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],

          // Results
          if (endingBalance != null && totalLossPercent != null) ...[
            const SizedBox(height: 24),

            // Summary Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('Ending balance', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Text(
                      endingBalance!.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('Total Loss', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Text(
                      '${totalLossPercent!.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Detailed breakdown table
            if (periodBreakdown != null && periodBreakdown!.isNotEmpty)
              Card(
                child: Column(
                  children: [
                    // Table header
                    Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text(
                              'Period',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Starting balance',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Total Loss',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Ending balance',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Table rows
                    ...periodBreakdown!.map((period) {
                      final isEvenRow = period['period'] % 2 == 0;
                      return Container(
                        color: isEvenRow ? Theme.of(context).colorScheme.surfaceContainerLow : Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: Text(
                                '${period['period']}',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                period['starting'].toStringAsFixed(0),
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${period['loss_percent'].toStringAsFixed(2)}%',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                period['ending'].toStringAsFixed(0),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
