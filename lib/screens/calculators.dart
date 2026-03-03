import 'package:flutter/material.dart';
import '../core/calculator_engine.dart';
import '../data/symbols_data.dart';
import '../data/currencies_data.dart';
import '../widgets/symbol_search_dialog.dart';
import '../widgets/currency_search_dialog.dart';

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
        // Reset result when symbol changes
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
        // Reset result when currency changes
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
        quoteToAccountRate: 1.0, // Assuming 1:1 for account currency
      );

      // Calculate total value for X pips
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
          Text(
            'Instrument',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          InkWell(
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
                          Text(
                            selectedSymbol!.symbol,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            selectedSymbol!.description,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Expanded(
                      child: Text('Select an instrument'),
                    ),
                  ],
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _NumberInputField(
            controller: pipsController,
            label: 'Pips',
            hint: 'e.g. 2',
          ),
          const SizedBox(height: 10),
          _NumberInputField(
            controller: lotsController,
            label: 'Lots (Trade Size)',
            hint: 'e.g. 1',
          ),
          const SizedBox(height: 16),
          Text(
            'Deposit Currency',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          InkWell(
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
                          Text(
                            selectedCurrency!.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            selectedCurrency!.code,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Expanded(
                      child: Text('Select a currency'),
                    ),
                  ],
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _NumberInputField(
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
                    Text(
                      'Result',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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

class PositionSizeCalculatorScreen extends StatefulWidget {
  const PositionSizeCalculatorScreen({super.key});

  @override
  State<PositionSizeCalculatorScreen> createState() => _PositionSizeCalculatorScreenState();
}

class _PositionSizeCalculatorScreenState extends State<PositionSizeCalculatorScreen> {
  final TextEditingController accountSizeController = TextEditingController(text: '10000');
  final TextEditingController riskPercentController = TextEditingController(text: '1');
  final TextEditingController entryPriceController = TextEditingController(text: '1.2500');
  final TextEditingController stopLossController = TextEditingController(text: '1.2450');
  final TextEditingController takeProfitController = TextEditingController(text: '1.2600');

  String? validationMessage;
  PositionSizeResult? result;

  @override
  void dispose() {
    accountSizeController.dispose();
    riskPercentController.dispose();
    entryPriceController.dispose();
    stopLossController.dispose();
    takeProfitController.dispose();
    super.dispose();
  }

  void calculate() {
    final double? accountSize = double.tryParse(accountSizeController.text);
    final double? riskPercent = double.tryParse(riskPercentController.text);
    final double? entryPrice = double.tryParse(entryPriceController.text);
    final double? stopLoss = double.tryParse(stopLossController.text);
    final double? takeProfit = double.tryParse(takeProfitController.text);

    if (accountSize == null || riskPercent == null || entryPrice == null || stopLoss == null || takeProfit == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        result = null;
      });
      return;
    }

    try {
      final PositionSizeResult calculatedResult = CalculatorEngine.positionSizeCalculator(
        accountSize: accountSize,
        riskPercent: riskPercent,
        entryPrice: entryPrice,
        stopLoss: stopLoss,
        takeProfit: takeProfit,
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
      appBar: AppBar(title: const Text('Position Size Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NumberInputField(controller: accountSizeController, label: 'Account Size', hint: 'e.g. 10000'),
          const SizedBox(height: 10),
          _NumberInputField(controller: riskPercentController, label: 'Risk % Per Trade', hint: 'e.g. 1'),
          const SizedBox(height: 10),
          _NumberInputField(controller: entryPriceController, label: 'Entry Price', hint: 'e.g. 1.2500'),
          const SizedBox(height: 10),
          _NumberInputField(controller: stopLossController, label: 'Stop Loss Price', hint: 'e.g. 1.2450'),
          const SizedBox(height: 10),
          _NumberInputField(controller: takeProfitController, label: 'Take Profit Price', hint: 'e.g. 1.2600'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResultRow(label: 'Risk Amount', value: result!.riskAmount.toStringAsFixed(2)),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Position Size (Units)', value: result!.positionUnits.toStringAsFixed(2)),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Risk:Reward', value: '1:${result!.riskRewardRatio.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Potential Profit', value: result!.potentialProfit.toStringAsFixed(2)),
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

class ForexRebateCalculatorScreen extends StatefulWidget {
  const ForexRebateCalculatorScreen({super.key});

  @override
  State<ForexRebateCalculatorScreen> createState() => _ForexRebateCalculatorScreenState();
}

class _ForexRebateCalculatorScreenState extends State<ForexRebateCalculatorScreen> {
  final TextEditingController tradedLotsController = TextEditingController(text: '10');
  final TextEditingController rebatePerLotController = TextEditingController(text: '2.5');

  String? validationMessage;
  double? result;

  @override
  void dispose() {
    tradedLotsController.dispose();
    rebatePerLotController.dispose();
    super.dispose();
  }

  void calculate() {
    final double? tradedLots = double.tryParse(tradedLotsController.text);
    final double? rebatePerLot = double.tryParse(rebatePerLotController.text);

    if (tradedLots == null || rebatePerLot == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        result = null;
      });
      return;
    }

    try {
      final double calculatedResult = CalculatorEngine.forexRebateCalculator(
        tradedLots: tradedLots,
        rebatePerLot: rebatePerLot,
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
      appBar: AppBar(title: const Text('Forex Rebate Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NumberInputField(controller: tradedLotsController, label: 'Traded Lots', hint: 'e.g. 10'),
          const SizedBox(height: 10),
          _NumberInputField(controller: rebatePerLotController, label: 'Rebate Per Lot', hint: 'e.g. 2.5'),
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
                child: _ResultRow(label: 'Total Rebate', value: result!.toStringAsFixed(2)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProfitCalculatorScreen extends StatefulWidget {
  const ProfitCalculatorScreen({super.key});

  @override
  State<ProfitCalculatorScreen> createState() => _ProfitCalculatorScreenState();
}

class _ProfitCalculatorScreenState extends State<ProfitCalculatorScreen> {
  final TextEditingController entryPriceController = TextEditingController(text: '1.2000');
  final TextEditingController exitPriceController = TextEditingController(text: '1.2200');
  final TextEditingController unitsController = TextEditingController(text: '10000');
  bool isLong = true;

  String? validationMessage;
  ProfitResult? result;

  @override
  void dispose() {
    entryPriceController.dispose();
    exitPriceController.dispose();
    unitsController.dispose();
    super.dispose();
  }

  void calculate() {
    final double? entryPrice = double.tryParse(entryPriceController.text);
    final double? exitPrice = double.tryParse(exitPriceController.text);
    final double? units = double.tryParse(unitsController.text);

    if (entryPrice == null || exitPrice == null || units == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        result = null;
      });
      return;
    }

    try {
      final ProfitResult calculatedResult = CalculatorEngine.profitCalculator(
        entryPrice: entryPrice,
        exitPrice: exitPrice,
        units: units,
        isLong: isLong,
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
      appBar: AppBar(title: const Text('Profit Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Long')),
              ButtonSegment(value: false, label: Text('Short')),
            ],
            selected: {isLong},
            onSelectionChanged: (Set<bool> selection) {
              setState(() {
                isLong = selection.first;
              });
            },
          ),
          const SizedBox(height: 12),
          _NumberInputField(controller: entryPriceController, label: 'Entry Price', hint: 'e.g. 1.2000'),
          const SizedBox(height: 10),
          _NumberInputField(controller: exitPriceController, label: 'Exit Price', hint: 'e.g. 1.2200'),
          const SizedBox(height: 10),
          _NumberInputField(controller: unitsController, label: 'Units/Lots', hint: 'e.g. 10000'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResultRow(label: 'Price Difference', value: result!.priceDifference.toStringAsFixed(4)),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Gross Profit/Loss', value: result!.grossProfit.toStringAsFixed(2)),
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

class CompoundProfitCalculatorScreen extends StatefulWidget {
  const CompoundProfitCalculatorScreen({super.key});

  @override
  State<CompoundProfitCalculatorScreen> createState() => _CompoundProfitCalculatorScreenState();
}

class _CompoundProfitCalculatorScreenState extends State<CompoundProfitCalculatorScreen> {
  final TextEditingController principalController = TextEditingController(text: '10000');
  final TextEditingController returnRateController = TextEditingController(text: '5');
  final TextEditingController periodsController = TextEditingController(text: '12');
  final TextEditingController contributionController = TextEditingController(text: '0');

  String? validationMessage;
  CompoundProfitResult? result;

  @override
  void dispose() {
    principalController.dispose();
    returnRateController.dispose();
    periodsController.dispose();
    contributionController.dispose();
    super.dispose();
  }

  void calculate() {
    final double? principal = double.tryParse(principalController.text);
    final double? returnRate = double.tryParse(returnRateController.text);
    final int? periods = int.tryParse(periodsController.text);
    final double? contribution = double.tryParse(contributionController.text);

    if (principal == null || returnRate == null || periods == null || contribution == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        result = null;
      });
      return;
    }

    try {
      final CompoundProfitResult calculatedResult = CalculatorEngine.compoundProfitCalculator(
        principal: principal,
        returnRatePercent: returnRate,
        periods: periods,
        contributionPerPeriod: contribution,
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
      appBar: AppBar(title: const Text('Compound Profit Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NumberInputField(controller: principalController, label: 'Initial Principal', hint: 'e.g. 10000'),
          const SizedBox(height: 10),
          _NumberInputField(controller: returnRateController, label: 'Return Rate % Per Period', hint: 'e.g. 5'),
          const SizedBox(height: 10),
          _NumberInputField(controller: periodsController, label: 'Number of Periods', hint: 'e.g. 12'),
          const SizedBox(height: 10),
          _NumberInputField(controller: contributionController, label: 'Contribution Per Period', hint: 'e.g. 0'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResultRow(label: 'Final Balance', value: result!.finalBalance.toStringAsFixed(2)),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Total Contributions', value: result!.totalContributions.toStringAsFixed(2)),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Total Profit', value: result!.totalProfit.toStringAsFixed(2)),
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

class DrawdownCalculatorScreen extends StatefulWidget {
  const DrawdownCalculatorScreen({super.key});

  @override
  State<DrawdownCalculatorScreen> createState() => _DrawdownCalculatorScreenState();
}

class _DrawdownCalculatorScreenState extends State<DrawdownCalculatorScreen> {
  final TextEditingController peakBalanceController = TextEditingController(text: '10000');
  final TextEditingController troughBalanceController = TextEditingController(text: '7500');

  String? validationMessage;
  DrawdownResult? result;

  @override
  void dispose() {
    peakBalanceController.dispose();
    troughBalanceController.dispose();
    super.dispose();
  }

  void calculate() {
    final double? peakBalance = double.tryParse(peakBalanceController.text);
    final double? troughBalance = double.tryParse(troughBalanceController.text);

    if (peakBalance == null || troughBalance == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        result = null;
      });
      return;
    }

    try {
      final DrawdownResult calculatedResult = CalculatorEngine.drawdownCalculator(
        peakBalance: peakBalance,
        troughBalance: troughBalance,
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
      appBar: AppBar(title: const Text('Drawdown Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NumberInputField(controller: peakBalanceController, label: 'Peak Balance', hint: 'e.g. 10000'),
          const SizedBox(height: 10),
          _NumberInputField(controller: troughBalanceController, label: 'Current Balance (Trough)', hint: 'e.g. 7500'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResultRow(label: 'Drawdown Amount', value: result!.drawdownAmount.toStringAsFixed(2)),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Drawdown %', value: '${result!.drawdownPercent.toStringAsFixed(2)}%'),
                    const SizedBox(height: 8),
                    _ResultRow(
                      label: 'Recovery % Needed',
                      value: result!.recoveryPercent.isInfinite
                          ? 'N/A (100% loss)'
                          : '${result!.recoveryPercent.toStringAsFixed(2)}%',
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

class RiskOfRuinCalculatorScreen extends StatefulWidget {
  const RiskOfRuinCalculatorScreen({super.key});

  @override
  State<RiskOfRuinCalculatorScreen> createState() => _RiskOfRuinCalculatorScreenState();
}

class _RiskOfRuinCalculatorScreenState extends State<RiskOfRuinCalculatorScreen> {
  final TextEditingController winRateController = TextEditingController(text: '55');
  final TextEditingController winLossRatioController = TextEditingController(text: '1.5');
  final TextEditingController riskPerTradeController = TextEditingController(text: '1');
  final TextEditingController ruinThresholdController = TextEditingController(text: '50');

  String? validationMessage;
  double? result;

  @override
  void dispose() {
    winRateController.dispose();
    winLossRatioController.dispose();
    riskPerTradeController.dispose();
    ruinThresholdController.dispose();
    super.dispose();
  }

  void calculate() {
    final double? winRate = double.tryParse(winRateController.text);
    final double? winLossRatio = double.tryParse(winLossRatioController.text);
    final double? riskPerTrade = double.tryParse(riskPerTradeController.text);
    final double? ruinThreshold = double.tryParse(ruinThresholdController.text);

    if (winRate == null || winLossRatio == null || riskPerTrade == null || ruinThreshold == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        result = null;
      });
      return;
    }

    try {
      final double calculatedResult = CalculatorEngine.riskOfRuinCalculator(
        winRatePercent: winRate,
        winLossRatio: winLossRatio,
        riskPerTradePercent: riskPerTrade,
        ruinThresholdPercent: ruinThreshold,
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
      appBar: AppBar(title: const Text('Risk of Ruin Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NumberInputField(controller: winRateController, label: 'Win Rate %', hint: 'e.g. 55'),
          const SizedBox(height: 10),
          _NumberInputField(controller: winLossRatioController, label: 'Win/Loss Ratio', hint: 'e.g. 1.5'),
          const SizedBox(height: 10),
          _NumberInputField(controller: riskPerTradeController, label: 'Risk % Per Trade', hint: 'e.g. 1'),
          const SizedBox(height: 10),
          _NumberInputField(controller: ruinThresholdController, label: 'Ruin Threshold %', hint: 'e.g. 50'),
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
                child: _ResultRow(
                  label: 'Probability of Ruin',
                  value: '${(result! * 100).toStringAsFixed(2)}%',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PivotPointsCalculatorScreen extends StatefulWidget {
  const PivotPointsCalculatorScreen({super.key});

  @override
  State<PivotPointsCalculatorScreen> createState() => _PivotPointsCalculatorScreenState();
}

class _PivotPointsCalculatorScreenState extends State<PivotPointsCalculatorScreen> {
  final TextEditingController highController = TextEditingController(text: '1.2600');
  final TextEditingController lowController = TextEditingController(text: '1.2400');
  final TextEditingController closeController = TextEditingController(text: '1.2500');

  String? validationMessage;
  PivotPointsResult? result;

  @override
  void dispose() {
    highController.dispose();
    lowController.dispose();
    closeController.dispose();
    super.dispose();
  }

  void calculate() {
    final double? high = double.tryParse(highController.text);
    final double? low = double.tryParse(lowController.text);
    final double? close = double.tryParse(closeController.text);

    if (high == null || low == null || close == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        result = null;
      });
      return;
    }

    try {
      final PivotPointsResult calculatedResult = CalculatorEngine.pivotPointsCalculator(
        high: high,
        low: low,
        close: close,
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
      appBar: AppBar(title: const Text('Pivot Points Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NumberInputField(controller: highController, label: 'Previous High', hint: 'e.g. 1.2600'),
          const SizedBox(height: 10),
          _NumberInputField(controller: lowController, label: 'Previous Low', hint: 'e.g. 1.2400'),
          const SizedBox(height: 10),
          _NumberInputField(controller: closeController, label: 'Previous Close', hint: 'e.g. 1.2500'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResultRow(label: 'Pivot Point (PP)', value: result!.pp.toStringAsFixed(4)),
                    const Divider(height: 16),
                    _ResultRow(label: 'Resistance 1 (R1)', value: result!.r1.toStringAsFixed(4)),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Resistance 2 (R2)', value: result!.r2.toStringAsFixed(4)),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Resistance 3 (R3)', value: result!.r3.toStringAsFixed(4)),
                    const Divider(height: 16),
                    _ResultRow(label: 'Support 1 (S1)', value: result!.s1.toStringAsFixed(4)),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Support 2 (S2)', value: result!.s2.toStringAsFixed(4)),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Support 3 (S3)', value: result!.s3.toStringAsFixed(4)),
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

class FibonacciCalculatorScreen extends StatefulWidget {
  const FibonacciCalculatorScreen({super.key});

  @override
  State<FibonacciCalculatorScreen> createState() => _FibonacciCalculatorScreenState();
}

class _FibonacciCalculatorScreenState extends State<FibonacciCalculatorScreen> {
  final TextEditingController highController = TextEditingController(text: '1.3000');
  final TextEditingController lowController = TextEditingController(text: '1.2000');
  bool fromHighToLow = true;

  String? validationMessage;
  Map<double, double>? result;

  @override
  void dispose() {
    highController.dispose();
    lowController.dispose();
    super.dispose();
  }

  void calculate() {
    final double? high = double.tryParse(highController.text);
    final double? low = double.tryParse(lowController.text);

    if (high == null || low == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        result = null;
      });
      return;
    }

    try {
      final Map<double, double> calculatedResult = CalculatorEngine.fibonacciRetracementCalculator(
        high: high,
        low: low,
        fromHighToLow: fromHighToLow,
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
      appBar: AppBar(title: const Text('Fibonacci Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('High to Low')),
              ButtonSegment(value: false, label: Text('Low to High')),
            ],
            selected: {fromHighToLow},
            onSelectionChanged: (Set<bool> selection) {
              setState(() {
                fromHighToLow = selection.first;
              });
            },
          ),
          const SizedBox(height: 12),
          _NumberInputField(controller: highController, label: 'High Price', hint: 'e.g. 1.3000'),
          const SizedBox(height: 10),
          _NumberInputField(controller: lowController, label: 'Low Price', hint: 'e.g. 1.2000'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final MapEntry<double, double> entry in result!.entries) ...[
                      _ResultRow(
                        label: '${(entry.key * 100).toStringAsFixed(1)}%',
                        value: entry.value.toStringAsFixed(4),
                      ),
                      if (entry.key != 1.0) const SizedBox(height: 8),
                    ],
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

class ForexMarginCalculatorScreen extends StatefulWidget {
  const ForexMarginCalculatorScreen({super.key});

  @override
  State<ForexMarginCalculatorScreen> createState() => _ForexMarginCalculatorScreenState();
}

class _ForexMarginCalculatorScreenState extends State<ForexMarginCalculatorScreen> {
  final TextEditingController lotsController = TextEditingController(text: '1');
  final TextEditingController contractSizeController = TextEditingController(text: '100000');
  final TextEditingController leverageController = TextEditingController(text: '100');
  final TextEditingController marketPriceController = TextEditingController(text: '1.2000');

  String? validationMessage;
  MarginResult? result;

  @override
  void dispose() {
    lotsController.dispose();
    contractSizeController.dispose();
    leverageController.dispose();
    marketPriceController.dispose();
    super.dispose();
  }

  void calculate() {
    final double? lots = double.tryParse(lotsController.text);
    final double? contractSize = double.tryParse(contractSizeController.text);
    final double? leverage = double.tryParse(leverageController.text);
    final double? marketPrice = double.tryParse(marketPriceController.text);

    if (lots == null || contractSize == null || leverage == null || marketPrice == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        result = null;
      });
      return;
    }

    try {
      final MarginResult calculatedResult = CalculatorEngine.forexMarginCalculator(
        lots: lots,
        contractSize: contractSize,
        leverage: leverage,
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
          _NumberInputField(controller: lotsController, label: 'Lots', hint: 'e.g. 1'),
          const SizedBox(height: 10),
          _NumberInputField(controller: contractSizeController, label: 'Contract Size', hint: 'e.g. 100000'),
          const SizedBox(height: 10),
          _NumberInputField(controller: leverageController, label: 'Leverage', hint: 'e.g. 100'),
          const SizedBox(height: 10),
          _NumberInputField(controller: marketPriceController, label: 'Market Price', hint: 'e.g. 1.2000'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResultRow(label: 'Notional Value', value: result!.notionalValue.toStringAsFixed(2)),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Required Margin', value: result!.requiredMargin.toStringAsFixed(2)),
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

class CryptoExchangeFeesCalculatorScreen extends StatefulWidget {
  const CryptoExchangeFeesCalculatorScreen({super.key});

  @override
  State<CryptoExchangeFeesCalculatorScreen> createState() => _CryptoExchangeFeesCalculatorScreenState();
}

class _CryptoExchangeFeesCalculatorScreenState extends State<CryptoExchangeFeesCalculatorScreen> {
  final TextEditingController tradeValueController = TextEditingController(text: '1000');
  final TextEditingController feePercentController = TextEditingController(text: '0.1');
  final TextEditingController networkFeeController = TextEditingController(text: '2');

  String? validationMessage;
  FeeResult? result;

  @override
  void dispose() {
    tradeValueController.dispose();
    feePercentController.dispose();
    networkFeeController.dispose();
    super.dispose();
  }

  void calculate() {
    final double? tradeValue = double.tryParse(tradeValueController.text);
    final double? feePercent = double.tryParse(feePercentController.text);
    final double? networkFee = double.tryParse(networkFeeController.text);

    if (tradeValue == null || feePercent == null || networkFee == null) {
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
        networkFee: networkFee,
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
          _NumberInputField(controller: tradeValueController, label: 'Trade Value', hint: 'e.g. 1000'),
          const SizedBox(height: 10),
          _NumberInputField(controller: feePercentController, label: 'Fee Percent', hint: 'e.g. 0.1'),
          const SizedBox(height: 10),
          _NumberInputField(controller: networkFeeController, label: 'Network Fee', hint: 'e.g. 2'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResultRow(label: 'Trading Fee', value: result!.tradingFee.toStringAsFixed(2)),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Network Fee', value: result!.networkFee.toStringAsFixed(2)),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Total Fees', value: result!.totalFees.toStringAsFixed(2)),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Net Amount', value: result!.netAmount.toStringAsFixed(2)),
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

class CryptoFxConverterScreen extends StatefulWidget {
  const CryptoFxConverterScreen({super.key});

  @override
  State<CryptoFxConverterScreen> createState() => _CryptoFxConverterScreenState();
}

class _CryptoFxConverterScreenState extends State<CryptoFxConverterScreen> {
  final TextEditingController amountController = TextEditingController(text: '100');
  final TextEditingController rateController = TextEditingController(text: '1.2');
  final TextEditingController feePercentController = TextEditingController(text: '0');

  String? validationMessage;
  ConversionResult? result;

  @override
  void dispose() {
    amountController.dispose();
    rateController.dispose();
    feePercentController.dispose();
    super.dispose();
  }

  void calculate() {
    final double? amount = double.tryParse(amountController.text);
    final double? rate = double.tryParse(rateController.text);
    final double? feePercent = double.tryParse(feePercentController.text);

    if (amount == null || rate == null || feePercent == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        result = null;
      });
      return;
    }

    try {
      final ConversionResult calculatedResult = CalculatorEngine.converterCalculator(
        amount: amount,
        rate: rate,
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
      appBar: AppBar(title: const Text('Crypto & FX Converter')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NumberInputField(controller: amountController, label: 'Amount', hint: 'e.g. 100'),
          const SizedBox(height: 10),
          _NumberInputField(controller: rateController, label: 'Conversion Rate', hint: 'e.g. 1.2'),
          const SizedBox(height: 10),
          _NumberInputField(controller: feePercentController, label: 'Fee Percent (Optional)', hint: 'e.g. 0'),
          const SizedBox(height: 14),
          FilledButton(onPressed: calculate, child: const Text('Convert')),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResultRow(label: 'Gross Converted', value: result!.grossConverted.toStringAsFixed(2)),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Fee Amount', value: result!.feeAmount.toStringAsFixed(2)),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Net Converted', value: result!.netConverted.toStringAsFixed(2)),
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

class _NumberInputField extends StatelessWidget {
  const _NumberInputField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
