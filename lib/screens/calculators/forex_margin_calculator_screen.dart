import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/calculator_engine.dart';
import '../../core/app_theme.dart';
import '../../data/currencies_data.dart';
import '../../data/symbols_data.dart';
import '../../widgets/calculator_components.dart';
import '../../widgets/currency_search_dialog.dart';
import '../../widgets/symbol_search_dialog.dart';

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
    final formatter = NumberFormat('#,##0.00');
    
    return CalculatorScaffold(
      title: 'Forex Margin Calculator',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instrument',
                          style: AppTypography.text(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSymbolSelector(),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deposit currency',
                          style: AppTypography.text(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildCurrencySelector(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leverage',
                          style: AppTypography.text(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          key: ValueKey<String>(selectedLeverage),
                          value: selectedLeverage,
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
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CalculatorInputField(
                      label: '${selectedSymbol?.symbol.split('/').first ?? 'Asset'} lots',
                      controller: lotsController,
                      hint: 'e.g. 1',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              CalculatorInputField(
                label: '${selectedSymbol?.symbol ?? 'Instrument'} price',
                controller: marketPriceController,
                hint: 'e.g. 1.15993',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          CalculateButton(onPressed: calculate),
          if (validationMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            MessageBanner(message: validationMessage!),
          ],
          if (result != null && selectedCurrency != null) ...[
            const SizedBox(height: AppSpacing.xl),
            CalculatorSection(
              title: 'Result',
              children: [
                ResultRow(
                  label: 'Margin required',
                  value: '${selectedCurrency!.symbol}${formatter.format(result!.requiredMargin)}',
                  isLarge: true,
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
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: AppRadius.sm,
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            if (selectedSymbol != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getCategoryColor(selectedSymbol!.category).withValues(alpha: 0.2),
                  borderRadius: AppRadius.xs,
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
                  style: AppTypography.text(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else ...[
              Expanded(
                child: Text(
                  'Select instrument',
                  style: AppTypography.text(
                    fontSize: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
            Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return InkWell(
      onTap: _selectCurrency,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: AppRadius.sm,
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            if (selectedCurrency != null) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                child: Text(
                  selectedCurrency!.symbol,
                  style: AppTypography.text(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedCurrency!.name,
                  style: AppTypography.text(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else ...[
              Expanded(
                child: Text(
                  'Select currency',
                  style: AppTypography.text(
                    fontSize: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
            Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20,
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
