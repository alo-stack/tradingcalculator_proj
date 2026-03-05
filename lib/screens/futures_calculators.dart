import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class FuturesCalculatorsScreen extends StatefulWidget {
  const FuturesCalculatorsScreen({super.key});

  @override
  State<FuturesCalculatorsScreen> createState() => _FuturesCalculatorsScreenState();
}

class _FuturesCalculatorsScreenState extends State<FuturesCalculatorsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final Map<String, dynamic> _futuresContracts = {
    'ES': {'name': 'E-mini S&P 500', 'multiplier': 50, 'tickSize': 0.25},
    'NQ': {'name': 'E-mini Nasdaq-100', 'multiplier': 20, 'tickSize': 0.25},
    'GC': {'name': 'Gold Futures', 'multiplier': 100, 'tickSize': 0.10},
    'CL': {'name': 'Crude Oil Futures', 'multiplier': 1000, 'tickSize': 0.01},
    'ZB': {'name': 'US Treasury Bond Futures', 'multiplier': 1000, 'tickSize': 0.015625},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Futures Calculators'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Risk Calculator'),
            Tab(text: 'Margin Calculator'),
            Tab(text: 'Contract Size'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RiskCalculator(futuresContracts: _futuresContracts),
          _MarginCalculator(futuresContracts: _futuresContracts),
          _ContractSizeCalculator(futuresContracts: _futuresContracts),
        ],
      ),
    );
  }
}

class _RiskCalculator extends StatefulWidget {
  final Map<String, dynamic> futuresContracts;

  const _RiskCalculator({required this.futuresContracts});

  @override
  State<_RiskCalculator> createState() => _RiskCalculatorState();
}

class _RiskCalculatorState extends State<_RiskCalculator> {
  String _selectedContract = 'ES';
  final _entryPriceCtrl = TextEditingController();
  final _stopLossPriceCtrl = TextEditingController();
  final _contractsCtrl = TextEditingController(text: '1');
  
  double _riskAmount = 0;
  double _riskPercentage = 0;

  void _calculateRisk() {
    final entry = double.tryParse(_entryPriceCtrl.text) ?? 0;
    final stopLoss = double.tryParse(_stopLossPriceCtrl.text) ?? 0;
    final contracts = double.tryParse(_contractsCtrl.text) ?? 1;
    
    if (entry > 0 && stopLoss > 0) {
      final tickDiff = (entry - stopLoss).abs();
      final contract = widget.futuresContracts[_selectedContract];
      final multiplier = contract['multiplier'] as int;
      
      final riskPerTick = multiplier * tickDiff;
      final totalRisk = riskPerTick * contracts;
      
      setState(() {
        _riskAmount = totalRisk;
        _riskPercentage = (_riskAmount / 10000) * 100; // Assuming 10k account
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContractSelector(),
          const SizedBox(height: 24),
          _buildInputField(
            label: 'Entry Price',
            controller: _entryPriceCtrl,
            hint: 'e.g., 4500.50',
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Stop Loss Price',
            controller: _stopLossPriceCtrl,
            hint: 'e.g., 4480.00',
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Number of Contracts',
            controller: _contractsCtrl,
            hint: '1',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _calculateRisk,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: const Text('Calculate Risk'),
            ),
          ),
          const SizedBox(height: 32),
          if (_riskAmount > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.accent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Risk Results',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.accent,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Risk Amount:'),
                      Text(
                        '\$${_riskAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Risk % (of 10k account):'),
                      Text(
                        '${_riskPercentage.toStringAsFixed(2)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContractSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Futures Contract',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.futuresContracts.entries.map((entry) {
            final isSelected = _selectedContract == entry.key;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedContract = entry.key);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  borderRadius: AppRadius.sm,
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      entry.value['name'],
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white70 : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: AppRadius.md),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ],
    );
  }
}

class _MarginCalculator extends StatefulWidget {
  final Map<String, dynamic> futuresContracts;

  const _MarginCalculator({required this.futuresContracts});

  @override
  State<_MarginCalculator> createState() => _MarginCalculatorState();
}

class _MarginCalculatorState extends State<_MarginCalculator> {
  String _selectedContract = 'ES';
  final _contractsCtrl = TextEditingController(text: '1');
  
  // Typical initial margins (you can update these)
  final Map<String, double> _marginRequirements = {
    'ES': 12100,  // E-mini S&P 500
    'NQ': 9350,   // E-mini Nasdaq-100
    'GC': 6000,   // Gold
    'CL': 5500,   // Crude Oil
    'ZB': 3500,   // Treasury Bond
  };
  
  double _marginRequired = 0;

  void _calculateMargin() {
    final contracts = double.tryParse(_contractsCtrl.text) ?? 1;
    final baseMargin = _marginRequirements[_selectedContract] ?? 5000;
    
    setState(() {
      _marginRequired = baseMargin * contracts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContractSelector(),
          const SizedBox(height: 24),
          _buildInputField(
            label: 'Number of Contracts',
            controller: _contractsCtrl,
            hint: '1',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _calculateMargin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: const Text('Calculate Margin'),
            ),
          ),
          const SizedBox(height: 32),
          if (_marginRequired > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.accent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Margin Requirements',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.accent,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Initial Margin Required:'),
                      Text(
                        '\$${_marginRequired.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Maintenance Margin: ${(_marginRequired * 0.75).toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContractSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Futures Contract',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _marginRequirements.keys.map((contract) {
            final isSelected = _selectedContract == contract;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedContract = contract);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  borderRadius: AppRadius.sm,
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.border,
                  ),
                ),
                child: Text(
                  contract,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: AppRadius.md),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ],
    );
  }
}

class _ContractSizeCalculator extends StatefulWidget {
  final Map<String, dynamic> futuresContracts;

  const _ContractSizeCalculator({required this.futuresContracts});

  @override
  State<_ContractSizeCalculator> createState() => _ContractSizCalculatorState();
}

class _ContractSizCalculatorState extends State<_ContractSizeCalculator> {
  String _selectedContract = 'ES';
  final _accountSizeCtrl = TextEditingController(text: '25000');
  final _riskPercentCtrl = TextEditingController(text: '1');
  final _entryCtrl = TextEditingController();
  final _stopLossCtrl = TextEditingController();
  
  double _contractSize = 0;

  void _calculateContractSize() {
    final accountSize = double.tryParse(_accountSizeCtrl.text) ?? 25000;
    final riskPercent = double.tryParse(_riskPercentCtrl.text) ?? 1;
    final entry = double.tryParse(_entryCtrl.text) ?? 0;
    final stopLoss = double.tryParse(_stopLossCtrl.text) ?? 0;
    
    if (entry > 0 && stopLoss > 0) {
      final contract = widget.futuresContracts[_selectedContract];
      final multiplier = contract['multiplier'] as int;
      
      final riskAmount = (accountSize * riskPercent) / 100;
      final priceDiff = (entry - stopLoss).abs();
      final riskPerContract = priceDiff * multiplier;
      
      setState(() {
        _contractSize = riskAmount / riskPerContract;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContractSelector(),
          const SizedBox(height: 24),
          _buildInputField(
            label: 'Account Size (\$)',
            controller: _accountSizeCtrl,
            hint: '25000',
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Risk % per Trade',
            controller: _riskPercentCtrl,
            hint: '1',
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Entry Price',
            controller: _entryCtrl,
            hint: 'e.g., 4500.50',
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Stop Loss Price',
            controller: _stopLossCtrl,
            hint: 'e.g., 4480.00',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _calculateContractSize,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: const Text('Calculate Contract Size'),
            ),
          ),
          const SizedBox(height: 32),
          if (_contractSize > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.accent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Optimal Contract Size',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.accent,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Contracts to Trade:'),
                      Text(
                        _contractSize.toStringAsFixed(2),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rounded: ${_contractSize.round()} contracts',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContractSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Futures Contract',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.futuresContracts.entries.map((entry) {
            final isSelected = _selectedContract == entry.key;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedContract = entry.key);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  borderRadius: AppRadius.sm,
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      entry.value['name'],
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white70 : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: AppRadius.md),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ],
    );
  }
}
