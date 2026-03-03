import 'package:flutter/material.dart';
import '../../core/calculator_engine.dart';
import '../../data/symbols_data.dart';
import '../../data/currencies_data.dart';
import '../../widgets/symbol_search_dialog.dart';
import '../../widgets/currency_search_dialog.dart';
import '../widgets/number_input_field.dart';

class ProfitCalculatorScreen extends StatefulWidget {
  const ProfitCalculatorScreen({super.key});

  @override
  State<ProfitCalculatorScreen> createState() => _ProfitCalculatorScreenState();
}

class _ProfitCalculatorScreenState extends State<ProfitCalculatorScreen> {
  TradingSymbol? selectedSymbol;
  Currency? selectedCurrency;
  bool isLong = true;
  final TextEditingController lotsController = TextEditingController(text: '1');
  final TextEditingController openPriceController = TextEditingController(text: '1.16085');
  final TextEditingController closePriceController = TextEditingController(text: '1.18085');
  final TextEditingController pipSizeController = TextEditingController(text: '0.0001');

  String? validationMessage;
  ProfitResult? result;
  double? profitInMoney;
  double? profitInPips;

  @override
  void initState() {
    super.initState();
    selectedSymbol = SymbolsData.findBySymbol('EUR/USD');
    selectedCurrency = CurrenciesData.findByCode('USD');
    if (selectedSymbol != null) {
      pipSizeController.text = selectedSymbol!.pipSize.toString();
    }
  }

  @override
  void dispose() {
    lotsController.dispose();
    openPriceController.dispose();
    closePriceController.dispose();
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
        profitInMoney = null;
        profitInPips = null;
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
        profitInMoney = null;
        profitInPips = null;
        validationMessage = null;
      });
    }
  }

  void calculate() {
    if (selectedSymbol == null) {
      setState(() {
        validationMessage = 'Please select an instrument first.';
        result = null;
        profitInMoney = null;
        profitInPips = null;
      });
      return;
    }

    if (selectedCurrency == null) {
      setState(() {
        validationMessage = 'Please select a deposit currency.';
        result = null;
        profitInMoney = null;
        profitInPips = null;
      });
      return;
    }

    final double? lots = double.tryParse(lotsController.text);
    final double? openPrice = double.tryParse(openPriceController.text);
    final double? closePrice = double.tryParse(closePriceController.text);
    final double? pipSize = double.tryParse(pipSizeController.text);

    if (lots == null || openPrice == null || closePrice == null || pipSize == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        result = null;
        profitInMoney = null;
        profitInPips = null;
      });
      return;
    }

    try {
      final double units = lots * selectedSymbol!.baseSize;
      final ProfitResult calculatedResult = CalculatorEngine.profitCalculator(
        entryPrice: openPrice,
        exitPrice: closePrice,
        units: units,
        isLong: isLong,
        pointValue: 1.0,
      );

      // Calculate pips profit
      final double priceDiff = isLong ? (closePrice - openPrice) : (openPrice - closePrice);
      final double pipsProfit = priceDiff / pipSize;

      setState(() {
        validationMessage = null;
        result = calculatedResult;
        profitInMoney = calculatedResult.grossProfit;
        profitInPips = pipsProfit;
      });
    } on ArgumentError catch (error) {
      setState(() {
        validationMessage = error.message.toString();
        result = null;
        profitInMoney = null;
        profitInPips = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forex Profit Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Row 1: Instrument & Deposit Currency
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

          // Row 2: Buy/Sell & Lots
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buy or Sell', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    _buildBuySellSelector(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('◆Lots (trade size)', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    NumberInputField(controller: lotsController, label: '', hint: 'e.g. 1'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 3: Open Price & Close Price
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Open price', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    NumberInputField(controller: openPriceController, label: '', hint: 'e.g. 1.16085'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Close price', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    NumberInputField(controller: closePriceController, label: '', hint: 'e.g. 1.18085'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pip Size (Read-only)
          Text('${selectedSymbol?.symbol ?? 'Instrument'} 1 Pip Size',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          TextField(
            controller: pipSizeController,
            enabled: false,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 24),

          // Calculate Button
          FilledButton(
            onPressed: calculate,
            child: const Text('Calculate'),
          ),

          // Error message
          if (validationMessage != null) ...[
            const SizedBox(height: 14),
            Text(validationMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],

          // Results
          if (profitInMoney != null && selectedCurrency != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('Profit in money', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Text(
                      '${selectedCurrency!.symbol}${profitInMoney!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: profitInMoney! >= 0
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('Profit in pips', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Text(
                      profitInPips!.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: profitInPips! >= 0
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
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
              Expanded(
                child: Text(
                  selectedSymbol!.symbol,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else ...[
              const Expanded(child: Text('Select')),
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
              Expanded(
                child: Text(
                  selectedCurrency!.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else ...[
              const Expanded(child: Text('Select')),
            ],
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildBuySellSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: true, label: Text('Buy')),
          ButtonSegment(value: false, label: Text('Sell')),
        ],
        selected: {isLong},
        onSelectionChanged: (Set<bool> selection) {
          setState(() {
            isLong = selection.first;
            result = null;
            profitInMoney = null;
            profitInPips = null;
          });
        },
      ),
    );
  }
}
