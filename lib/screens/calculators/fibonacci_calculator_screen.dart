import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../widgets/calculator_components.dart';

class FibonacciCalculatorScreen extends StatefulWidget {
  const FibonacciCalculatorScreen({super.key});

  @override
  State<FibonacciCalculatorScreen> createState() => _FibonacciCalculatorScreenState();
}

class _FibonacciCalculatorScreenState extends State<FibonacciCalculatorScreen> {
  final TextEditingController lowController = TextEditingController(text: '900');
  final TextEditingController highController = TextEditingController(text: '1000');
  final TextEditingController endController = TextEditingController(text: '2000');

  String selectedTrend = 'Down'; // Up or Down
  String selectedType = 'Retracement'; // Retracement or Projection

  String? validationMessage;
  Map<String, double>? fibonacciLevels;

  @override
  void dispose() {
    lowController.dispose();
    highController.dispose();
    endController.dispose();
    super.dispose();
  }

  Map<String, double> _calculateFibonacci(
    double low,
    double high,
    String trend,
    String type,
    double? endPrice,
  ) {
    final double range = high - low;
    final Map<String, double> levels = {};

    if (trend == 'Down') {
      if (type == 'Retracement') {
        // Price went down from high to low, retracement means bounce up from low
        levels['161.8%'] = low + (range * 1.618);
        levels['138.2%'] = low + (range * 1.382);
        levels['78.6%'] = low + (range * 0.786);
        levels['61.8%'] = low + (range * 0.618);
        levels['50%'] = low + (range * 0.500);
        levels['38.2%'] = low + (range * 0.382);
        levels['23.6%'] = low + (range * 0.236);
      } else {
        // Projection - price continues down from the end price
        if (endPrice != null) {
          levels['261.8%'] = endPrice - (range * 2.618);
          levels['200%'] = endPrice - (range * 2.000);
          levels['161.8%'] = endPrice - (range * 1.618);
          levels['138.2%'] = endPrice - (range * 1.382);
          levels['100%'] = endPrice - range;
          levels['61.8%'] = endPrice - (range * 0.618);
        }
      }
    } else {
      // Trend Up
      if (type == 'Retracement') {
        // Price went up from low to high, retracement means pullback from high
        levels['161.8%'] = high - (range * 1.618);
        levels['138.2%'] = high - (range * 1.382);
        levels['78.6%'] = high - (range * 0.786);
        levels['61.8%'] = high - (range * 0.618);
        levels['50%'] = high - (range * 0.500);
        levels['38.2%'] = high - (range * 0.382);
        levels['23.6%'] = high - (range * 0.236);
      } else {
        // Projection - price continues up from the end price
        if (endPrice != null) {
          levels['261.8%'] = endPrice + (range * 2.618);
          levels['200%'] = endPrice + (range * 2.000);
          levels['161.8%'] = endPrice + (range * 1.618);
          levels['138.2%'] = endPrice + (range * 1.382);
          levels['100%'] = endPrice + range;
          levels['61.8%'] = endPrice + (range * 0.618);
        }
      }
    }

    return levels;
  }

  void calculate() {
    final double? low = double.tryParse(lowController.text);
    final double? high = double.tryParse(highController.text);
    final double? endPrice = selectedType == 'Projection' ? double.tryParse(endController.text) : null;

    if (low == null || high == null) {
      setState(() {
        validationMessage = 'Please enter valid numbers in all fields.';
        fibonacciLevels = null;
      });
      return;
    }

    if (selectedType == 'Projection' && endPrice == null) {
      setState(() {
        validationMessage = 'Please enter a valid end price for projection.';
        fibonacciLevels = null;
      });
      return;
    }

    if (low >= high) {
      setState(() {
        validationMessage = 'Low price must be less than high price.';
        fibonacciLevels = null;
      });
      return;
    }

    try {
      final Map<String, double> levels = _calculateFibonacci(
        low,
        high,
        selectedTrend,
        selectedType,
        endPrice,
      );

      setState(() {
        validationMessage = null;
        fibonacciLevels = levels;
      });
    } catch (error) {
      setState(() {
        validationMessage = error.toString();
        fibonacciLevels = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorScaffold(
      title: 'Fibonacci Calculator',
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
                    'Trend direction',
                    style: AppTypography.text(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: selectedTrend,
                    items: ['Up', 'Down'].map((String trend) {
                      return DropdownMenuItem<String>(
                        value: trend,
                        child: Text(trend),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedTrend = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type',
                    style: AppTypography.text(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedType = 'Retracement';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: selectedType == 'Retracement'
                                  ? AppColors.surfaceElevated
                                  : Colors.transparent,
                              borderRadius: AppRadius.sm,
                              border: Border.all(
                                color: selectedType == 'Retracement'
                                    ? AppColors.accent
                                    : AppColors.border,
                                width: selectedType == 'Retracement' ? 1.5 : 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedType == 'Retracement'
                                          ? AppColors.accent
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: selectedType == 'Retracement'
                                      ? Center(
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Retracement',
                                  style: AppTypography.text(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedType = 'Projection';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: selectedType == 'Projection'
                                  ? AppColors.surfaceElevated
                                  : Colors.transparent,
                              borderRadius: AppRadius.sm,
                              border: Border.all(
                                color: selectedType == 'Projection'
                                    ? AppColors.accent
                                    : AppColors.border,
                                width: selectedType == 'Projection' ? 1.5 : 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedType == 'Projection'
                                          ? AppColors.accent
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: selectedType == 'Projection'
                                      ? Center(
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Projection',
                                  style: AppTypography.text(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: CalculatorInputField(
                      label: 'Low price',
                      controller: lowController,
                      hint: 'e.g. 900',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CalculatorInputField(
                      label: 'High price',
                      controller: highController,
                      hint: 'e.g. 1000',
                    ),
                  ),
                ],
              ),
              if (selectedType == 'Projection') ...[
                const SizedBox(height: AppSpacing.md),
                CalculatorInputField(
                  label: 'End price',
                  controller: endController,
                  hint: 'e.g. 2000',
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          CalculateButton(onPressed: calculate),
          if (validationMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            MessageBanner(message: validationMessage!),
          ],
          if (fibonacciLevels != null && fibonacciLevels!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            CalculatorSection(
              title: 'Fibonacci Levels',
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.sm,
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        color: AppColors.surfaceElevated,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                          horizontal: AppSpacing.md,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Level',
                              style: AppTypography.text(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'Price',
                              style: AppTypography.text(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...fibonacciLevels!.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                            horizontal: AppSpacing.md,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: AppTypography.text(
                                  fontSize: 15,
                                  color: AppColors.accent,
                                ),
                              ),
                              Text(
                                entry.value.toStringAsFixed(1),
                                style: AppTypography.text(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
