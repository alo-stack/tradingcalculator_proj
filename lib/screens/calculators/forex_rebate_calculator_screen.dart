import 'package:flutter/material.dart';
import '../../core/calculator_engine.dart';
import '../../core/app_theme.dart';
import '../../widgets/calculator_components.dart';
import 'package:intl/intl.dart';

class ForexRebateCalculatorScreen extends StatefulWidget {
  const ForexRebateCalculatorScreen({super.key});

  @override
  State<ForexRebateCalculatorScreen> createState() => _ForexRebateCalculatorScreenState();
}

class _ForexRebateCalculatorScreenState extends State<ForexRebateCalculatorScreen> {
  final TextEditingController tradedLotsController = TextEditingController(text: '10');
  final TextEditingController rebatePerLotController = TextEditingController(text: '2.5');

  String? validationMessage;
  double? result;

  @override
  void dispose() {
    tradedLotsController.dispose();
    rebatePerLotController.dispose();
    super.dispose();
  }

  void calculate() {
    final double? tradedLots = double.tryParse(tradedLotsController.text);
    final double? rebatePerLot = double.tryParse(rebatePerLotController.text);

    if (tradedLots == null || rebatePerLot == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        result = null;
      });
      return;
    }

    try {
      final double calculatedResult = CalculatorEngine.forexRebateCalculator(
        tradedLots: tradedLots,
        rebatePerLot: rebatePerLot,
      );

      setState(() {
        validationMessage = null;
        result = calculatedResult;
      });
    } on ArgumentError catch (error) {
      setState(() {
        validationMessage = error.message.toString();
        result = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return CalculatorScaffold(
      title: 'Forex Rebate Calculator',
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 0,
        ),
        children: [
          CalculatorSection(
            title: 'Rebate Details',
            children: [
              CalculatorInputField(
                label: 'Traded Lots',
                controller: tradedLotsController,
                hint: 'e.g. 10',
              ),
              const SizedBox(height: AppSpacing.md),
              CalculatorInputField(
                label: 'Rebate Per Lot',
                controller: rebatePerLotController,
                hint: 'e.g. 2.5',
                suffix: '\$',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          CalculateButton(
            onPressed: calculate,
            label: 'Calculate Rebate',
          ),
          if (validationMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            MessageBanner(
              message: validationMessage!,
              isError: true,
            ),
          ],
          if (result != null) ...[
            const SizedBox(height: AppSpacing.xl),
            CalculatorSection(
              title: 'Result',
              children: [
                ResultRow(
                  label: 'Total Rebate',
                  value: formatter.format(result),
                  isLarge: true,
                  isPositive: true,
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
