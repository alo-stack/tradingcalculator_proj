import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../widgets/calculator_components.dart';

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
    final formatter = NumberFormat('#,##0.00');
    
    return CalculatorScaffold(
      title: 'Forex Drawdown Calculator',
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
                      label: 'Starting balance',
                      controller: startingBalanceController,
                      hint: 'e.g. 20000',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CalculatorInputField(
                      label: 'Consecutive losses',
                      controller: consecutiveLossesController,
                      hint: 'e.g. 10',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              CalculatorInputField(
                label: 'Loss % per trade',
                controller: lossPercentController,
                hint: 'e.g. 2',
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
          if (endingBalance != null && totalLossPercent != null) ...[
            const SizedBox(height: AppSpacing.xl),
            CalculatorSection(
              title: 'Results',
              children: [
                ResultRow(
                  label: 'Ending balance',
                  value: formatter.format(endingBalance!),
                  isLarge: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                ResultRow(
                  label: 'Total Loss',
                  value: '${totalLossPercent!.toStringAsFixed(1)}%',
                  isNegative: true,
                ),
              ],
            ),
            if (periodBreakdown != null && periodBreakdown!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              CalculatorSection(
                title: 'Period Breakdown',
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.sm,
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          color: AppColors.surfaceElevated,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                            horizontal: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: Text(
                                  'Period',
                                  style: AppTypography.text(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Starting',
                                  style: AppTypography.text(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Loss',
                                  style: AppTypography.text(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Ending',
                                  style: AppTypography.text(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...periodBreakdown!.map((period) {
                          final isEvenRow = period['period'] % 2 == 0;
                          return Container(
                            color: isEvenRow ? AppColors.surfaceHigh : Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                              horizontal: AppSpacing.md,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    '${period['period']}',
                                    style: AppTypography.text(fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    period['starting'].toStringAsFixed(0),
                                    style: AppTypography.text(fontSize: 13),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${period['loss_percent'].toStringAsFixed(2)}%',
                                    style: AppTypography.text(
                                      fontSize: 13,
                                      color: AppColors.negative,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    period['ending'].toStringAsFixed(0),
                                    style: AppTypography.text(
                                      fontSize: 13,
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
              ),
            ],
          ],
        ],
      ),
    );
  }
}
