import 'package:flutter/material.dart';
import '../../core/calculator_engine.dart';
import '../../data/symbols_data.dart';
import '../../data/currencies_data.dart';
import '../../widgets/symbol_search_dialog.dart';
import '../../widgets/currency_search_dialog.dart';
import '../widgets/number_input_field.dart';
import '../widgets/result_row.dart';

class PositionSizeCalculatorScreen extends StatefulWidget {
  const PositionSizeCalculatorScreen({super.key});

  @override
  State<PositionSizeCalculatorScreen> createState() => _PositionSizeCalculatorScreenState();
}

class _PositionSizeCalculatorScreenState extends State<PositionSizeCalculatorScreen> {
  TradingSymbol? selectedSymbol;
  Currency? selectedCurrency;
  final TextEditingController stopLossPipsController = TextEditingController(text: '200');
  final TextEditingController accountBalanceController = TextEditingController(text: '100000');
  final TextEditingController riskPercentController = TextEditingController(text: '2');
  final TextEditingController pipSizeController = TextEditingController(text: '0.0001');

  String? validationMessage;
  RiskByPositionResult? result;

  @override
  void initState() {
    super.initState();
    // Set defaults
    selectedSymbol = SymbolsData.findBySymbol('EUR/USD');
    selectedCurrency = CurrenciesData.findByCode('USD');
    if (selectedSymbol != null) {
      pipSizeController.text = selectedSymbol!.pipSize.toString();
    }
  }

  @override
  void dispose() {
    stopLossPipsController.dispose();
    accountBalanceController.dispose();
    riskPercentController.dispose();
    pipSizeController.dispose();
    super.dispose();
  }

  Future<void> _selectSymbol() async {
    final TradingSymbol? selected = await showDialog<TradingSymbol>(
      context: context,
      builder: (context) => SymbolSearchDialog(selectedSymbol: selectedSymbol),
    );

    if (selected != null) {
      setState(() {
        selectedSymbol = selected;
        pipSizeController.text = selected.pipSize.toString();
        result = null;
        validationMessage = null;
      });
    }
  }

  Future<void> _selectCurrency() async {
    final Currency? selected = await showDialog<Currency>(
      context: context,
      builder: (context) => CurrencySearchDialog(selectedCurrency: selectedCurrency),
    );

    if (selected != null) {
      setState(() {
        selectedCurrency = selected;
        result = null;
        validationMessage = null;
      });
    }
  }

  void calculate() {
    if (selectedSymbol == null) {
      setState(() {
        validationMessage = 'Please select an instrument first.';
        result = null;
      });
      return;
    }

    if (selectedCurrency == null) {
      setState(() {
        validationMessage = 'Please select a deposit currency.';
        result = null;
      });
      return;
    }

    final double? stopLossPips = double.tryParse(stopLossPipsController.text);
    final double? accountBalance = double.tryParse(accountBalanceController.text);
    final double? riskPercent = double.tryParse(riskPercentController.text);
    final double? pipSize = double.tryParse(pipSizeController.text);

    if (stopLossPips == null || accountBalance == null || riskPercent == null || pipSize == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        result = null;
      });
      return;
    }

    try {
      final RiskByPositionResult calculatedResult = CalculatorEngine.riskByPositionCalculator(
        accountBalance: accountBalance,
        riskPercent: riskPercent,
        stopLossPips: stopLossPips,
        pipSize: pipSize,
        baseSize: selectedSymbol!.baseSize,
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
      appBar: AppBar(title: const Text('Position Size Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Instrument
          Text('Instrument', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          _buildSymbolSelector(),
          const SizedBox(height: 16),

          // Section 2: Deposit Currency
          Text('Deposit Currency', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          _buildCurrencySelector(),
          const SizedBox(height: 16),

          // Section 3: Stop Loss (Pips)
          NumberInputField(
            controller: stopLossPipsController,
            label: 'Stop Loss (pips)',
            hint: 'e.g. 200',
          ),
          const SizedBox(height: 10),

          // Section 4: Account Balance
          NumberInputField(
            controller: accountBalanceController,
            label: 'Account Balance',
            hint: 'e.g. 100000',
          ),
          const SizedBox(height: 10),

          // Section 5: Risk Percentage
          NumberInputField(
            controller: riskPercentController,
            label: 'Risk (%)',
            hint: 'e.g. 2',
          ),
          const SizedBox(height: 16),

          // Section 6: Pip Size (Read-only)
          _buildReadOnlyPipSize(),
          const SizedBox(height: 14),

          // Calculate Button
          FilledButton(onPressed: calculate, child: const Text('Calculate')),
          if (validationMessage != null) ...[
            const SizedBox(height: 14),
            Text(validationMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],

          // Results
          if (result != null) ...[
            const SizedBox(height: 16),
            _buildResultsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildSymbolSelector() {
    return InkWell(
      onTap: _selectSymbol,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (selectedSymbol != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getCategoryColor(selectedSymbol!.category).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(selectedSymbol!.category),
                  color: _getCategoryColor(selectedSymbol!.category),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selectedSymbol!.symbol, style: Theme.of(context).textTheme.titleMedium),
                    Text(selectedSymbol!.description, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ] else ...[
              const Expanded(child: Text('Select an instrument')),
            ],
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return InkWell(
      onTap: _selectCurrency,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (selectedCurrency != null) ...[
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  selectedCurrency!.symbol,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selectedCurrency!.name, style: Theme.of(context).textTheme.titleMedium),
                    Text(selectedCurrency!.code, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ] else ...[
              const Expanded(child: Text('Select a currency')),
            ],
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyPipSize() {
    return TextField(
      controller: pipSizeController,
      enabled: false,
      decoration: InputDecoration(
        labelText: '${selectedSymbol?.symbol ?? 'Instrument'} 1 Pip Size',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildResultsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Results', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ResultRow(
              label: 'Lots (trade size)',
              value: result!.lotSize.toStringAsFixed(2),
            ),
            const SizedBox(height: 8),
            ResultRow(
              label: 'Units (trade size)',
              value: result!.units.toStringAsFixed(0),
            ),
            const SizedBox(height: 8),
            ResultRow(
              label: 'Money at risk',
              value: '${selectedCurrency!.symbol}${result!.riskAmount.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(SymbolCategory category) {
    switch (category) {
      case SymbolCategory.forex:
        return Icons.currency_exchange;
      case SymbolCategory.cryptocurrency:
        return Icons.currency_bitcoin;
      case SymbolCategory.stock:
        return Icons.trending_up;
      case SymbolCategory.indices:
        return Icons.show_chart;
      case SymbolCategory.commodity:
        return Icons.brightness_7;
    }
  }

  Color _getCategoryColor(SymbolCategory category) {
    switch (category) {
      case SymbolCategory.forex:
        return Colors.blue;
      case SymbolCategory.cryptocurrency:
        return Colors.orange;
      case SymbolCategory.stock:
        return Colors.green;
      case SymbolCategory.indices:
        return Colors.purple;
      case SymbolCategory.commodity:
        return Colors.amber;
    }
  }
}
