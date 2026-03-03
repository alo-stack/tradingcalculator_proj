import 'package:flutter/material.dart';
import '../../core/calculator_engine.dart';
import '../widgets/number_input_field.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Crypto Exchange Fees')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exchange/Provider', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String>(selectedExchange),
                      initialValue: selectedExchange,
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
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fees Denomination', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String>(selectedFeesDenomination),
                      initialValue: selectedFeesDenomination,
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
                    Text('Buying/Receiving', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String>(selectedBuyingAsset),
                      initialValue: selectedBuyingAsset,
                      items: assets
                          .map((String asset) => DropdownMenuItem<String>(
                                value: asset,
                                child: Text(asset),
                              ))
                          .toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            selectedBuyingAsset = value;
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
                    Text('Paying with/Selling', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String>(selectedPayingAsset),
                      initialValue: selectedPayingAsset,
                      items: <String>['US Dollar', 'Euro', 'USDT']
                          .map((String asset) => DropdownMenuItem<String>(
                                value: asset,
                                child: Text(asset),
                              ))
                          .toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            selectedPayingAsset = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: NumberInputField(
                  controller: btcAmountController,
                  label: '${selectedBuyingAsset.split(' ').first} amount',
                  hint: 'e.g. 1',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NumberInputField(
                  controller: usdAmountController,
                  label: '${selectedPayingAsset.split(' ').first} amount',
                  hint: 'e.g. 66813.472',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NumberInputField(controller: feePercentController, label: 'Custom fees rate (%)', hint: 'e.g. 2'),
          const SizedBox(height: 14),
          FilledButton(onPressed: calculate, child: const Text('Calculate')),
          if (validationMessage != null) ...[
            const SizedBox(height: 14),
            Text(validationMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (result != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Fees',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_currencySymbol${result!.tradingFee.toStringAsFixed(2)}',
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
}
