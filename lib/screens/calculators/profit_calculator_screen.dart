import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/calculator_engine.dart';
import '../../core/app_theme.dart';
import '../../data/symbols_data.dart';
import '../../data/currencies_data.dart';
import '../../widgets/symbol_search_dialog.dart';
import '../../widgets/currency_search_dialog.dart';
import '../../widgets/calculator_components.dart';
import 'package:intl/intl.dart';

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
    final NumberFormat formatter = NumberFormat.currency(
      symbol: selectedCurrency?.symbol ?? '\$',
      decimalDigits: 2,
    );

    return CalculatorScaffold(
      title: 'Profit Calculator',
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
              const SizedBox(height: AppSpacing.md),
              CalculatorSelector(
                label: 'Deposit Currency',
                value: selectedCurrency?.name,
                placeholder: 'Select currency',
                onTap: _selectCurrency,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CalculatorSection(
            title: 'Trade Details',
            children: [
              Text(
                'Position Type',
                style: AppTypography.text(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: AppRadius.sm,
                  border: Border.all(
                    color: AppColors.border,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          if (!isLong) {
                            setState(() {
                              isLong = true;
                              result = null;
                              profitInMoney = null;
                              profitInPips = null;
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: isLong ? AppColors.accent : Colors.transparent,
                            borderRadius: AppRadius.xs,
                          ),
                          child: Text(
                            'Buy',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.geist(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isLong ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          if (isLong) {
                            setState(() {
                              isLong = false;
                              result = null;
                              profitInMoney = null;
                              profitInPips = null;
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: !isLong ? AppColors.accent : Colors.transparent,
                            borderRadius: AppRadius.xs,
                          ),
                          child: Text(
                            'Sell',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.geist(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: !isLong ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              CalculatorInputField(
                label: 'Lots (Trade Size)',
                controller: lotsController,
                hint: 'e.g. 1',
              ),
              const SizedBox(height: AppSpacing.md),
              CalculatorInputField(
                label: 'Open Price',
                controller: openPriceController,
                hint: 'e.g. 1.16085',
              ),
              const SizedBox(height: AppSpacing.md),
              CalculatorInputField(
                label: 'Close Price',
                controller: closePriceController,
                hint: 'e.g. 1.18085',
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
            label: 'Calculate Profit',
          ),
          if (validationMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            MessageBanner(
              message: validationMessage!,
              isError: true,
            ),
          ],
          if (profitInMoney != null && profitInPips != null) ...[
            const SizedBox(height: AppSpacing.xl),
            CalculatorSection(
              title: 'Results',
              children: [
                ResultRow(
                  label: 'Profit in Money',
                  value: formatter.format(profitInMoney),
                  isLarge: true,
                  isPositive: profitInMoney! >= 0,
                  isNegative: profitInMoney! < 0,
                ),
                const SizedBox(height: AppSpacing.sm),
                Divider(color: AppColors.border),
                const SizedBox(height: AppSpacing.sm),
                ResultRow(
                  label: 'Profit in Pips',
                  value: profitInPips!.toStringAsFixed(1),
                  isPositive: profitInPips! >= 0,
                  isNegative: profitInPips! < 0,
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
