import 'package:flutter/material.dart';
import '../../core/calculator_engine.dart';
import '../widgets/number_input_field.dart';
import '../widgets/result_row.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Forex Rebate Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NumberInputField(controller: tradedLotsController, label: 'Traded Lots', hint: 'e.g. 10'),
          const SizedBox(height: 10),
          NumberInputField(controller: rebatePerLotController, label: 'Rebate Per Lot', hint: 'e.g. 2.5'),
          const SizedBox(height: 14),
          FilledButton(onPressed: calculate, child: const Text('Calculate')),
          if (validationMessage != null) ...[
            const SizedBox(height: 14),
            Text(validationMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (result != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: ResultRow(label: 'Total Rebate', value: result!.toStringAsFixed(2)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
