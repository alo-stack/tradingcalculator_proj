import 'package:flutter/material.dart';
import '../../core/calculator_engine.dart';
import '../../data/currencies_data.dart';
import '../../data/symbols_data.dart';
import '../../widgets/currency_search_dialog.dart';
import '../../widgets/symbol_search_dialog.dart';
import '../widgets/number_input_field.dart';

class ForexMarginCalculatorScreen extends StatefulWidget {
  const ForexMarginCalculatorScreen({super.key});

  @override
  State<ForexMarginCalculatorScreen> createState() => _ForexMarginCalculatorScreenState();
}

class _ForexMarginCalculatorScreenState extends State<ForexMarginCalculatorScreen> {
  TradingSymbol? selectedSymbol;
  Currency? selectedCurrency;
  final List<String> leverageOptions = <String>['30:1', '50:1', '100:1', '200:1', '500:1'];
  String selectedLeverage = '100:1';

  final TextEditingController lotsController = TextEditingController(text: '1');
  final TextEditingController marketPriceController = TextEditingController(text: '1.15993');

  String? validationMessage;
  MarginResult? result;

  @override
  void initState() {
    super.initState();
    selectedSymbol = SymbolsData.findBySymbol('EUR/USD');
    selectedCurrency = CurrenciesData.findByCode('USD');
  }

  @override
  void dispose() {
    lotsController.dispose();
    marketPriceController.dispose();
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

  double _parseLeverage(String text) {
    return double.parse(text.split(':').first);
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

    final double? lots = double.tryParse(lotsController.text);
    final double? marketPrice = double.tryParse(marketPriceController.text);

    if (lots == null || marketPrice == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        result = null;
      });
      return;
    }

    try {
      final MarginResult calculatedResult = CalculatorEngine.forexMarginCalculator(
        lots: lots,
        contractSize: selectedSymbol!.baseSize,
        leverage: _parseLeverage(selectedLeverage),
        marketPrice: marketPrice,
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
      appBar: AppBar(title: const Text('Forex Margin Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Instrument', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    _buildSymbolSelector(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deposit currency', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    _buildCurrencySelector(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Leverage', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String>(selectedLeverage),
                      initialValue: selectedLeverage,
                      items: leverageOptions
                          .map((String leverage) => DropdownMenuItem<String>(
                                value: leverage,
                                child: Text(leverage),
                              ))
                          .toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            selectedLeverage = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selectedSymbol?.symbol.split('/').first ?? 'Asset'} lots (trade size)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    NumberInputField(controller: lotsController, label: '', hint: 'e.g. 1'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NumberInputField(
            controller: marketPriceController,
            label: '${selectedSymbol?.symbol ?? 'Instrument'} price',
            hint: 'e.g. 1.15993',
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: calculate, child: const Text('Calculate')),
          if (validationMessage != null) ...[
            const SizedBox(height: 14),
            Text(validationMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (result != null && selectedCurrency != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Deposit amount to open the trade',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${selectedCurrency!.symbol}${result!.requiredMargin.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (selectedSymbol != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getCategoryColor(selectedSymbol!.category).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(selectedSymbol!.category),
                  color: _getCategoryColor(selectedSymbol!.category),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedSymbol!.symbol,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else ...[
              const Expanded(child: Text('Select instrument')),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (selectedCurrency != null) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  selectedCurrency!.symbol,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedCurrency!.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else ...[
              const Expanded(child: Text('Select currency')),
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
