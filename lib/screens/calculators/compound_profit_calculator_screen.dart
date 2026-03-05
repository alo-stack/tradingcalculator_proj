import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/calculator_engine.dart';
import '../../core/app_theme.dart';
import '../../widgets/calculator_components.dart';

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
    final formatter = NumberFormat('#,##0.00');
    
    return CalculatorScaffold(
      title: 'Compounding Calculator',
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
                      controller: principalController,
                      hint: 'e.g. 20000',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CalculatorInputField(
                      label: 'Number of periods',
                      controller: periodsController,
                      hint: 'e.g. 12',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              CalculatorInputField(
                label: 'Gain % per period',
                controller: returnRateController,
                hint: 'e.g. 5',
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
          if (result != null) ...[
            const SizedBox(height: AppSpacing.xl),
            CalculatorSection(
              title: 'Results',
              children: [
                ResultRow(
                  label: 'Ending balance',
                  value: formatter.format(result!.finalBalance),
                  isLarge: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                ResultRow(
                  label: 'Total Gain',
                  value: '${(result!.totalProfit / (result!.finalBalance - result!.totalProfit) * 100).toStringAsFixed(1)}%',
                  isPositive: true,
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
                                width: 40,
                                child: Text(
                                  'Period',
                                  style: AppTypography.text(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
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
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Gain',
                                  style: AppTypography.text(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
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
                                    fontWeight: FontWeight.bold,
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
                                  width: 40,
                                  child: Text(
                                    '${period['period']}',
                                    style: AppTypography.text(fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    period['starting'].toStringAsFixed(2),
                                    style: AppTypography.text(fontSize: 13),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${period['gain_percent'].toStringAsFixed(2)}%',
                                    style: AppTypography.text(
                                      fontSize: 13,
                                      color: AppColors.positive,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    period['ending'].toStringAsFixed(2),
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
