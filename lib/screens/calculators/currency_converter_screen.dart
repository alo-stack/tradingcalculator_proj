import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../data/currencies_data.dart';
import '../../services/conversion_rates_service.dart';
import '../../widgets/calculator_components.dart';
import '../../widgets/currency_search_dialog.dart';

class CryptoFxConverterScreen extends StatefulWidget {
  const CryptoFxConverterScreen({super.key});

  @override
  State<CryptoFxConverterScreen> createState() => _CryptoFxConverterScreenState();
}

class _CryptoFxConverterScreenState extends State<CryptoFxConverterScreen> {
  Currency? fromCurrency;
  Currency? toCurrency;

  final TextEditingController fromAmountController = TextEditingController(text: '1');
  final TextEditingController toAmountController = TextEditingController();

  bool isUpdatingFrom = false;
  bool isUpdatingTo = false;
  bool isLoadingRates = true;
  String? validationMessage;

  Map<String, double> usdPerUnit = <String, double>{};
  DateTime? lastUpdated;

  Timer? refreshTimer;
  Timer? clockTimer;

  @override
  void initState() {
    super.initState();
    fromCurrency = CurrenciesData.findByCode('EUR');
    toCurrency = CurrenciesData.findByCode('USD');
    _loadRates();
    refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadRates(silent: true));
    clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    clockTimer?.cancel();
    fromAmountController.dispose();
    toAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadRates({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoadingRates = true;
      });
    }

    try {
      final Set<String> fiatCodes = CurrenciesData.majorCurrencies.map((Currency c) => c.code).toSet();
      final Set<String> cryptoCodes = CurrenciesData.cryptocurrencies.map((Currency c) => c.code).toSet();
      final ConversionRatesSnapshot snapshot = await ConversionRatesService.fetchUsdPerUnitRates(
        fiatCodes: fiatCodes,
        cryptoCodes: cryptoCodes,
      );

      setState(() {
        usdPerUnit = snapshot.usdPerUnit;
        lastUpdated = snapshot.fetchedAt;
        validationMessage = null;
        isLoadingRates = false;
      });
      _updateToFromFromAmount();
    } catch (_) {
      setState(() {
        isLoadingRates = false;
        validationMessage = 'Unable to fetch live rates. Please try again.';
      });
    }
  }

  bool get _canConvert {
    if (fromCurrency == null || toCurrency == null) {
      return false;
    }
    return usdPerUnit.containsKey(fromCurrency!.code) && usdPerUnit.containsKey(toCurrency!.code);
  }

  double? get _rateFromTo {
    if (!_canConvert) {
      return null;
    }
    final double fromUsd = usdPerUnit[fromCurrency!.code]!;
    final double toUsd = usdPerUnit[toCurrency!.code]!;
    return fromUsd / toUsd;
  }

  double? get _rateToFrom {
    if (!_canConvert) {
      return null;
    }
    final double fromUsd = usdPerUnit[fromCurrency!.code]!;
    final double toUsd = usdPerUnit[toCurrency!.code]!;
    return toUsd / fromUsd;
  }

  void _updateToFromFromAmount() {
    if (isUpdatingTo) {
      return;
    }
    final double? rate = _rateFromTo;
    final double? fromAmount = double.tryParse(fromAmountController.text);
    if (rate == null || fromAmount == null) {
      return;
    }

    isUpdatingFrom = true;
    toAmountController.text = _formatAmount(fromAmount * rate);
    isUpdatingFrom = false;
  }

  void _updateFromFromToAmount() {
    if (isUpdatingFrom) {
      return;
    }
    final double? rate = _rateToFrom;
    final double? toAmount = double.tryParse(toAmountController.text);
    if (rate == null || toAmount == null) {
      return;
    }

    isUpdatingTo = true;
    fromAmountController.text = _formatAmount(toAmount * rate);
    isUpdatingTo = false;
  }

  String _formatAmount(double value) {
    if (value.abs() >= 1000) {
      return value.toStringAsFixed(2);
    }
    if (value.abs() >= 1) {
      return value.toStringAsFixed(3);
    }
    return value.toStringAsFixed(6);
  }

  String _formatRate(double value) {
    if (value.abs() >= 1000) {
      return value.toStringAsFixed(2);
    }
    return value.toStringAsFixed(3);
  }

  String _relativeTime() {
    if (lastUpdated == null) {
      return '';
    }
    final int seconds = DateTime.now().difference(lastUpdated!).inSeconds;
    if (seconds < 60) {
      return 'Rates updated ${seconds}s ago';
    }
    final int minutes = seconds ~/ 60;
    return 'Rates updated ${minutes}m ago';
  }

  Future<void> _selectFromCurrency() async {
    final Currency? selected = await showDialog<Currency>(
      context: context,
      builder: (context) => CurrencySearchDialog(selectedCurrency: fromCurrency),
    );

    if (selected != null) {
      setState(() {
        fromCurrency = selected;
      });
      _updateToFromFromAmount();
    }
  }

  Future<void> _selectToCurrency() async {
    final Currency? selected = await showDialog<Currency>(
      context: context,
      builder: (context) => CurrencySearchDialog(selectedCurrency: toCurrency),
    );

    if (selected != null) {
      setState(() {
        toCurrency = selected;
      });
      _updateToFromFromAmount();
    }
  }

  void _swapCurrencies() {
    setState(() {
      final Currency? previousFrom = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = previousFrom;

      final String previousFromAmount = fromAmountController.text;
      fromAmountController.text = toAmountController.text;
      toAmountController.text = previousFromAmount;
    });

    _updateToFromFromAmount();
  }

  Widget _buildCompactCurrencySelector({
    required Currency? currency,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
            if (currency != null) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                child: Text(
                  currency.symbol,
                  style: AppTypography.text(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currency.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.text(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: Text(
                  'Select currency',
                  style: AppTypography.text(
                    fontSize: 15,
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

  @override
  Widget build(BuildContext context) {
    final double? directRate = _rateFromTo;
    final double? inverseRate = _rateToFrom;

    return CalculatorScaffold(
      title: 'Real-time Currency Converter',
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 0,
        ),
        children: [
          CalculatorSection(
            title: 'Currencies',
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildCompactCurrencySelector(
                      currency: fromCurrency,
                      onTap: _selectFromCurrency,
                    ),
                  ),
                  IconButton(
                    onPressed: _swapCurrencies,
                    icon: const Icon(Icons.swap_horiz),
                  ),
                  Expanded(
                    child: _buildCompactCurrencySelector(
                      currency: toCurrency,
                      onTap: _selectToCurrency,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: CalculatorInputField(
                      label: fromCurrency?.code ?? 'From',
                      controller: fromAmountController,
                      hint: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _updateToFromFromAmount(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CalculatorInputField(
                      label: toCurrency?.code ?? 'To',
                      controller: toAmountController,
                      hint: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _updateFromFromToAmount(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (isLoadingRates) const LinearProgressIndicator(),
          if (validationMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            MessageBanner(message: validationMessage!),
          ],
          if (directRate != null && inverseRate != null && fromCurrency != null && toCurrency != null) ...[
            const SizedBox(height: AppSpacing.xl),
            CalculatorSection(
              title: 'Exchange Rates',
              children: [
                ResultRow(
                  label: '1 ${fromCurrency!.code}',
                  value: '${_formatRate(directRate)} ${toCurrency!.code}',
                ),
                const SizedBox(height: AppSpacing.sm),
                ResultRow(
                  label: '1 ${toCurrency!.code}',
                  value: '${_formatRate(inverseRate)} ${fromCurrency!.code}',
                ),
              ],
            ),
          ],
          if (lastUpdated != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _relativeTime(),
              textAlign: TextAlign.right,
              style: AppTypography.text(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
