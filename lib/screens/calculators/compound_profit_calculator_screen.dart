import 'package:flutter/material.dart';
import '../../core/calculator_engine.dart';
import '../widgets/number_input_field.dart';

class CompoundProfitCalculatorScreen extends StatefulWidget {
  const CompoundProfitCalculatorScreen({super.key});

  @override
  State<CompoundProfitCalculatorScreen> createState() => _CompoundProfitCalculatorScreenState();
}

class _CompoundProfitCalculatorScreenState extends State<CompoundProfitCalculatorScreen> {
  final TextEditingController principalController = TextEditingController(text: '20000');
  final TextEditingController returnRateController = TextEditingController(text: '5');
  final TextEditingController periodsController = TextEditingController(text: '12');
  final TextEditingController contributionController = TextEditingController(text: '0');

  String? validationMessage;
  CompoundProfitResult? result;
  List<Map<String, dynamic>>? periodBreakdown;

  @override
  void dispose() {
    principalController.dispose();
    returnRateController.dispose();
    periodsController.dispose();
    contributionController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _calculatePeriodBreakdown(
    double principal,
    double returnRate,
    int periods,
    double contributionPerPeriod,
  ) {
    final List<Map<String, dynamic>> breakdown = [];
    double balance = principal;

    for (int i = 1; i <= periods; i++) {
      final double startingBalance = balance;
      final double periodGain = startingBalance * (returnRate / 100);
      balance = startingBalance + periodGain + contributionPerPeriod;

      breakdown.add({
        'period': i,
        'starting': startingBalance,
        'gain_percent': returnRate,
        'ending': balance,
      });
    }

    return breakdown;
  }

  void calculate() {
    final double? principal = double.tryParse(principalController.text);
    final double? returnRate = double.tryParse(returnRateController.text);
    final int? periods = int.tryParse(periodsController.text);
    final double? contribution = double.tryParse(contributionController.text);

    if (principal == null || returnRate == null || periods == null || contribution == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        result = null;
        periodBreakdown = null;
      });
      return;
    }

    try {
      final CompoundProfitResult calculatedResult = CalculatorEngine.compoundProfitCalculator(
        principal: principal,
        returnRatePercent: returnRate,
        periods: periods,
        contributionPerPeriod: contribution,
      );

      final List<Map<String, dynamic>> breakdown = _calculatePeriodBreakdown(
        principal,
        returnRate,
        periods,
        contribution,
      );

      setState(() {
        validationMessage = null;
        result = calculatedResult;
        periodBreakdown = breakdown;
      });
    } on ArgumentError catch (error) {
      setState(() {
        validationMessage = error.message.toString();
        result = null;
        periodBreakdown = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compounding Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Input row 1: Starting balance & Number of periods
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Starting balance', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    NumberInputField(controller: principalController, label: '', hint: 'e.g. 20000'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Number of periods', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    NumberInputField(controller: periodsController, label: '', hint: 'e.g. 12'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Input row 2: Gain % per period
          Text('Gain % per period', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          NumberInputField(controller: returnRateController, label: '', hint: 'e.g. 5'),
          const SizedBox(height: 24),

          // Calculate Button
          FilledButton(onPressed: calculate, child: const Text('Calculate')),

          // Error message
          if (validationMessage != null) ...[
            const SizedBox(height: 14),
            Text(validationMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],

          // Results
          if (result != null) ...[
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
                      result!.finalBalance.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('Total Gain', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Text(
                      '${(result!.totalProfit / (result!.finalBalance - result!.totalProfit) * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
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
                            width: 40,
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
                              'Total Gain',
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
                              width: 40,
                              child: Text(
                                '${period['period']}',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                period['starting'].toStringAsFixed(2),
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${period['gain_percent'].toStringAsFixed(2)}%',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                period['ending'].toStringAsFixed(2),
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
