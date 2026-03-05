import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/calculator_engine.dart';
import '../../core/app_theme.dart';
import '../../widgets/calculator_components.dart';

class CryptoExchangeFeesCalculatorScreen extends StatefulWidget {
  const CryptoExchangeFeesCalculatorScreen({super.key});

  @override
  State<CryptoExchangeFeesCalculatorScreen> createState() => _CryptoExchangeFeesCalculatorScreenState();
}

class _CryptoExchangeFeesCalculatorScreenState extends State<CryptoExchangeFeesCalculatorScreen> {
  final List<String> exchanges = <String>['Bitstamp', 'Binance', 'Coinbase'];
  final List<String> denominations = <String>['US Dollar', 'Euro', 'USDT'];
  final List<String> assets = <String>['Bitcoin', 'Ethereum', 'Tether'];

  String selectedExchange = 'Bitstamp';
  String selectedFeesDenomination = 'US Dollar';
  String selectedBuyingAsset = 'Bitcoin';
  String selectedPayingAsset = 'US Dollar';

  final TextEditingController btcAmountController = TextEditingController(text: '1');
  final TextEditingController usdAmountController = TextEditingController(text: '66813.472');
  final TextEditingController feePercentController = TextEditingController(text: '2');

  String? validationMessage;
  FeeResult? result;

  @override
  void dispose() {
    btcAmountController.dispose();
    usdAmountController.dispose();
    feePercentController.dispose();
    super.dispose();
  }

  String get _currencySymbol {
    switch (selectedFeesDenomination) {
      case 'Euro':
        return '€';
      default:
        return 'US\$';
    }
  }

  void calculate() {
    final double? tradeValue = double.tryParse(usdAmountController.text);
    final double? feePercent = double.tryParse(feePercentController.text);
    final double? assetAmount = double.tryParse(btcAmountController.text);

    if (tradeValue == null || feePercent == null || assetAmount == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        result = null;
      });
      return;
    }

    try {
      final FeeResult calculatedResult = CalculatorEngine.cryptoExchangeFeesCalculator(
        tradeValue: tradeValue,
        feePercent: feePercent,
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
      title: 'Crypto Exchange Fees',
      body: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 0,
            ),
        children: [
          CalculatorSection(
            title: 'Exchange Settings',
            children: [
              Text(
                'Exchange/Provider',
                style: AppTypography.text(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: selectedExchange,
                items: exchanges
                    .map((String exchange) => DropdownMenuItem<String>(
                          value: exchange,
                          child: Text(exchange),
                        ))
                    .toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      selectedExchange = value;
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Fees Denomination',
                style: AppTypography.text(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: selectedFeesDenomination,
                items: denominations
                    .map((String denomination) => DropdownMenuItem<String>(
                          value: denomination,
                          child: Text(denomination),
                        ))
                    .toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      selectedFeesDenomination = value;
                      if (value == 'Euro') {
                        selectedPayingAsset = 'Euro';
                      } else {
                        selectedPayingAsset = 'US Dollar';
                      }
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CalculatorSection(
            title: 'Trade Details',
            children: [
              CalculatorInputField(
                label: '${selectedBuyingAsset.split(' ').first} Amount',
                controller: btcAmountController,
                hint: 'e.g. 1',
              ),
              const SizedBox(height: AppSpacing.md),
              CalculatorInputField(
                label: '${selectedPayingAsset.split(' ').first} Amount',
                controller: usdAmountController,
                hint: 'e.g. 66813.472',
              ),
              const SizedBox(height: AppSpacing.md),
              CalculatorInputField(
                label: 'Custom Fees Rate (%)',
                controller: feePercentController,
                hint: 'e.g. 2',
                suffix: '%',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          CalculateButton(onPressed: calculate),
          if (validationMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            MessageBanner(message: validationMessage!),
          ],
          if (result != null) ...[
            const SizedBox(height: AppSpacing.xl),
            CalculatorSection(
              title: 'Result',
              children: [
                ResultRow(
                  label: 'Trading Fees',
                  value: '$_currencySymbol${formatter.format(result!.tradingFee)}',
                  isLarge: true,
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
