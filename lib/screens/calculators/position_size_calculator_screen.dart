import 'package:flutter/material.dart';
import '../../core/calculator_engine.dart';
import '../../core/app_theme.dart';
import '../../data/symbols_data.dart';
import '../../data/currencies_data.dart';
import '../../widgets/symbol_search_dialog.dart';
import '../../widgets/currency_search_dialog.dart';
import '../../widgets/calculator_components.dart';
import 'package:intl/intl.dart';

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
    final NumberFormat formatter = NumberFormat.currency(
      symbol: selectedCurrency?.symbol ?? '\$',
      decimalDigits: 2,
    );

    return CalculatorScaffold(
      title: 'Position Size Calculator',
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 0,
        ),
        children: [
          CalculatorSection(
            title: 'Instrument',
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
          const SizedBox(height: AppSpacing.md),
          CalculatorSection(
            title: 'Account Details',
            children: [
              CalculatorSelector(
                label: 'Deposit Currency',
                value: selectedCurrency?.name,
                placeholder: 'Select currency',
                onTap: _selectCurrency,
              ),
              const SizedBox(height: AppSpacing.md),
              CalculatorInputField(
                label: 'Account Balance',
                controller: accountBalanceController,
                hint: 'e.g. 100000',
              ),
              const SizedBox(height: AppSpacing.md),
              CalculatorInputField(
                label: 'Risk Percentage (%)',
                controller: riskPercentController,
                hint: 'e.g. 2',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CalculatorSection(
            title: 'Trade Settings',
            children: [
              CalculatorInputField(
                label: 'Stop Loss (Pips)',
                controller: stopLossPipsController,
                hint: 'e.g. 200',
              ),
              const SizedBox(height: AppSpacing.md),
              CalculatorInputField(
                label: 'Pip Size',
                controller: pipSizeController,
                hint: 'e.g. 0.0001',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          CalculateButton(
            onPressed: calculate,
            label: 'Calculate Position Size',
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
              title: 'Results',
              children: [
                ResultRow(
                  label: 'Lots (Trade Size)',
                  value: result!.lotSize.toStringAsFixed(2),
                  isLarge: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                Divider(color: AppColors.border),
                const SizedBox(height: AppSpacing.sm),
                ResultRow(
                  label: 'Units',
                  value: result!.units.toStringAsFixed(0),
                ),
                const SizedBox(height: AppSpacing.sm),
                ResultRow(
                  label: 'Money at Risk',
                  value: formatter.format(result!.riskAmount),
                  isNegative: true,
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
