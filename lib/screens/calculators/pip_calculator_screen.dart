import 'package:flutter/material.dart';
import '../../core/calculator_engine.dart';
import '../../data/symbols_data.dart';
import '../../data/currencies_data.dart';
import '../../widgets/symbol_search_dialog.dart';
import '../../widgets/currency_search_dialog.dart';
import '../widgets/number_input_field.dart';

class PipCalculatorScreen extends StatefulWidget {
  const PipCalculatorScreen({super.key});

  @override
  State<PipCalculatorScreen> createState() => _PipCalculatorScreenState();
}

class _PipCalculatorScreenState extends State<PipCalculatorScreen> {
  TradingSymbol? selectedSymbol;
  Currency? selectedCurrency;
  final TextEditingController pipsController = TextEditingController(text: '1');
  final TextEditingController lotsController = TextEditingController(text: '1');
  final TextEditingController pipSizeController = TextEditingController(text: '0.0001');

  String? validationMessage;
  PipValueResult? result;
  double? totalValue;

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
    pipsController.dispose();
    lotsController.dispose();
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
        totalValue = null;
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
        totalValue = null;
        validationMessage = null;
      });
    }
  }

  void calculate() {
    if (selectedSymbol == null) {
      setState(() {
        validationMessage = 'Please select an instrument first.';
        result = null;
        totalValue = null;
      });
      return;
    }

    if (selectedCurrency == null) {
      setState(() {
        validationMessage = 'Please select a deposit currency.';
        result = null;
        totalValue = null;
      });
      return;
    }

    final double? pips = double.tryParse(pipsController.text);
    final double? lots = double.tryParse(lotsController.text);
    final double? pipSize = double.tryParse(pipSizeController.text);

    if (pips == null || lots == null || pipSize == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        result = null;
        totalValue = null;
      });
      return;
    }

    try {
      final double lotSize = lots * selectedSymbol!.baseSize;
      final PipValueResult calculatedResult = CalculatorEngine.pipCalculator(
        lotSize: lotSize,
        pipSize: pipSize,
        quoteToAccountRate: 1.0,
      );

      final double calculatedTotal = calculatedResult.pipValueInAccount * pips;

      setState(() {
        validationMessage = null;
        result = calculatedResult;
        totalValue = calculatedTotal;
      });
    } on ArgumentError catch (error) {
      setState(() {
        validationMessage = error.message.toString();
        result = null;
        totalValue = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pip Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Instrument', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          _buildSymbolSelector(),
          const SizedBox(height: 16),
          NumberInputField(controller: pipsController, label: 'Pips', hint: 'e.g. 2'),
          const SizedBox(height: 10),
          NumberInputField(controller: lotsController, label: 'Lots (Trade Size)', hint: 'e.g. 1'),
          const SizedBox(height: 16),
          Text('Deposit Currency', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          _buildCurrencySelector(),
          const SizedBox(height: 16),
          NumberInputField(
            controller: pipSizeController,
            label: '${selectedSymbol?.symbol ?? 'Instrument'} Pip Size',
            hint: 'e.g. 0.0001',
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: calculate, child: const Text('Calculate')),
          if (validationMessage != null) ...[
            const SizedBox(height: 14),
            Text(validationMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (totalValue != null && selectedCurrency != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Result', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      '${selectedCurrency!.symbol}${totalValue!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
