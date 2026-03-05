import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../widgets/calculator_components.dart';

class PivotPointsCalculatorScreen extends StatefulWidget {
  const PivotPointsCalculatorScreen({super.key});

  @override
  State<PivotPointsCalculatorScreen> createState() => _PivotPointsCalculatorScreenState();
}

class _PivotPointsCalculatorScreenState extends State<PivotPointsCalculatorScreen> {
  final TextEditingController highController = TextEditingController(text: '1000');
  final TextEditingController lowController = TextEditingController(text: '900');
  final TextEditingController closeController = TextEditingController(text: '950');

  String selectedType = 'Standard';
  final List<String> pivotTypes = ['Standard', 'Woodie', 'Camarilla', 'DeMark', 'Fibonacci'];

  String? validationMessage;
  Map<String, double>? pivotResults;

  @override
  void dispose() {
    highController.dispose();
    lowController.dispose();
    closeController.dispose();
    super.dispose();
  }

  Map<String, double> _calculatePivots(double high, double low, double close, String type) {
    final Map<String, double> results = {};

    switch (type) {
      case 'Standard':
        final double pp = (high + low + close) / 3;
        results['R3'] = pp + (high - low) * 1.0;
        results['R2'] = pp + (high - low) * 0.66;
        results['R1'] = pp * 2 - low;
        results['PP'] = pp;
        results['S1'] = pp * 2 - high;
        results['S2'] = pp - (high - low) * 0.66;
        results['S3'] = pp - (high - low) * 1.0;
        break;

      case 'Woodie':
        final double pp = (high + low + (close * 2)) / 4;
        results['R3'] = high + (pp - low) * 2;
        results['R2'] = pp + (high - low);
        results['R1'] = pp * 2 - low;
        results['PP'] = pp;
        results['S1'] = pp * 2 - high;
        results['S2'] = pp - (high - low);
        results['S3'] = low - (high - pp) * 2;
        break;

      case 'Camarilla':
        final double h = high;
        final double l = low;
        final double range = h - l;
        results['R3'] = close + (range * 1.1);
        results['R2'] = close + (range * 0.55);
        results['R1'] = close + (range * 0.275);
        results['PP'] = (h + l + close) / 3;
        results['S1'] = close - (range * 0.275);
        results['S2'] = close - (range * 0.55);
        results['S3'] = close - (range * 1.1);
        break;

      case 'DeMark':
        final double x = (close == high) ? low + (2 * (high - close)) : (close == low) ? high + (2 * (close - low)) : high + low;
        results['R1'] = (x / 2) - low;
        results['PP'] = x / 2;
        results['S1'] = (x / 2) - high;
        results['R2'] = x - low;
        results['S2'] = x - high;
        results['R3'] = x - (low * 2);
        results['S3'] = x - (high * 2);
        break;

      case 'Fibonacci':
        final double pp = (high + low + close) / 3;
        final double range = high - low;
        results['R3'] = pp + (range * 1.618);
        results['R2'] = pp + (range * 1.0);
        results['R1'] = pp + (range * 0.618);
        results['PP'] = pp;
        results['S1'] = pp - (range * 0.618);
        results['S2'] = pp - (range * 1.0);
        results['S3'] = pp - (range * 1.618);
        break;

      default:
        results['PP'] = 0;
    }

    return results;
  }

  void calculate() {
    final double? high = double.tryParse(highController.text);
    final double? low = double.tryParse(lowController.text);
    final double? close = double.tryParse(closeController.text);

    if (high == null || low == null || close == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        pivotResults = null;
      });
      return;
    }

    if (low > high) {
      setState(() {
        validationMessage = 'Low price must be less than or equal to high price.';
        pivotResults = null;
      });
      return;
    }

    try {
      final Map<String, double> results = _calculatePivots(high, low, close, selectedType);

      setState(() {
        validationMessage = null;
        pivotResults = results;
      });
    } catch (error) {
      setState(() {
        validationMessage = error.toString();
        pivotResults = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorScaffold(
      title: 'Pivot Points Calculator',
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 0,
        ),
        children: [
          CalculatorSection(
            title: 'Input Parameters',
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pivot Type',
                    style: AppTypography.text(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    items: pivotTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedType = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: CalculatorInputField(
                      label: 'High price',
                      controller: highController,
                      hint: 'e.g. 1000',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CalculatorInputField(
                      label: 'Low price',
                      controller: lowController,
                      hint: 'e.g. 900',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              CalculatorInputField(
                label: 'Close price',
                controller: closeController,
                hint: 'e.g. 950',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          CalculateButton(onPressed: calculate),
          if (validationMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            MessageBanner(message: validationMessage!),
          ],
          if (pivotResults != null) ...[
            const SizedBox(height: AppSpacing.xl),
            CalculatorSection(
              title: 'Resistance Levels',
              children: [
                _buildResultRow(context, 'R3', pivotResults!['R3']!, isResistance: true),
                const SizedBox(height: AppSpacing.sm),
                _buildResultRow(context, 'R2', pivotResults!['R2']!, isResistance: true),
                const SizedBox(height: AppSpacing.sm),
                _buildResultRow(context, 'R1', pivotResults!['R1']!, isResistance: true),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            CalculatorSection(
              title: 'Pivot Point',
              children: [
                ResultRow(
                  label: 'PP',
                  value: pivotResults!['PP']!.toStringAsFixed(4),
                  isLarge: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            CalculatorSection(
              title: 'Support Levels',
              children: [
                _buildResultRow(context, 'S1', pivotResults!['S1']!, isSupport: true),
                const SizedBox(height: AppSpacing.sm),
                _buildResultRow(context, 'S2', pivotResults!['S2']!, isSupport: true),
                const SizedBox(height: AppSpacing.sm),
                _buildResultRow(context, 'S3', pivotResults!['S3']!, isSupport: true),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(
    BuildContext context,
    String label,
    double value, {
    bool isResistance = false,
    bool isSupport = false,
  }) {
    return ResultRow(
      label: label,
      value: value.toStringAsFixed(4),
      isNegative: isResistance,
      isPositive: isSupport,
    );
  }
}
