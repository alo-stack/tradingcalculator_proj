import 'package:flutter/material.dart';
import '../../core/calculator_engine.dart';
import '../../core/app_theme.dart';
import '../../data/symbols_data.dart';
import '../../data/currencies_data.dart';
import '../../widgets/symbol_search_dialog.dart';
import '../../widgets/currency_search_dialog.dart';
import '../../widgets/calculator_components.dart';
import 'package:intl/intl.dart';

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
    final NumberFormat formatter = NumberFormat.currency(
      symbol: selectedCurrency?.symbol ?? '\$',
      decimalDigits: 2,
    );

    return CalculatorScaffold(
      title: 'Pip Calculator',
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 0,
        ),
        children: [
          CalculatorSection(
            title: 'Instrument',
            padding: const EdgeInsets.all(AppSpacing.sm),
            children: [
              CalculatorSelector(
                label: 'Trading Pair',
                value: selectedSymbol != null
                    ? '${selectedSymbol!.symbol} - ${selectedSymbol!.description}'
                    : null,
                placeholder: 'Select an instrument',
                onTap: _selectSymbol,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          CalculatorSection(
            title: 'Trade Details',
            padding: const EdgeInsets.all(AppSpacing.sm),
            children: [
              CalculatorInputField(
                label: 'Pips',
                controller: pipsController,
                hint: 'e.g. 10',
              ),
              const SizedBox(height: AppSpacing.sm),
              CalculatorInputField(
                label: 'Lots (Trade Size)',
                controller: lotsController,
                hint: 'e.g. 1.0',
              ),
              const SizedBox(height: AppSpacing.sm),
              CalculatorInputField(
                label: 'Pip Size',
                controller: pipSizeController,
                hint: 'e.g. 0.0001',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          CalculatorSection(
            title: 'Account Currency',
            padding: const EdgeInsets.all(AppSpacing.sm),
            children: [
              CalculatorSelector(
                label: 'Deposit Currency',
                value: selectedCurrency?.name,
                placeholder: 'Select currency',
                onTap: _selectCurrency,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CalculateButton(
            onPressed: calculate,
            label: 'Calculate Pip Value',
          ),
          if (validationMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            MessageBanner(
              message: validationMessage!,
              isError: true,
            ),
          ],
          if (totalValue != null && result != null) ...[
            const SizedBox(height: AppSpacing.md),
            CalculatorSection(
              title: 'Result',
              padding: const EdgeInsets.all(AppSpacing.sm),
              children: [
                ResultRow(
                  label: 'Total Value',
                  value: formatter.format(totalValue),
                  isLarge: true,
                ),
                const SizedBox(height: AppSpacing.xs),
                Divider(color: AppColors.border),
                const SizedBox(height: AppSpacing.xs),
                ResultRow(
                  label: 'Per Pip',
                  value: formatter.format(result!.pipValueInAccount),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
