import 'package:flutter/material.dart';
import '../widgets/number_input_field.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Fibonacci Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Trend direction dropdown
          Text('Trend direction', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: selectedTrend,
            isExpanded: true,
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
          const SizedBox(height: 16),

          // Retracement / Projection radio buttons
          Text('Type', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
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
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedType == 'Retracement'
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        width: selectedType == 'Retracement' ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
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
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: selectedType == 'Retracement'
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        const Text('Retracement'),
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
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedType == 'Projection'
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        width: selectedType == 'Projection' ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
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
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: selectedType == 'Projection'
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        const Text('Projection'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Low and High price inputs
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Low price', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    NumberInputField(controller: lowController, label: '', hint: 'e.g. 900'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('High price', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    NumberInputField(controller: highController, label: '', hint: 'e.g. 1000'),
                  ],
                ),
              ),
            ],
          ),
          
          // End price (only for Projection)
          if (selectedType == 'Projection') ...[
            const SizedBox(height: 16),
            Text('End price', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            NumberInputField(controller: endController, label: '', hint: 'e.g. 2000'),
          ],
          
          const SizedBox(height: 24),

          // Calculate button
          FilledButton(onPressed: calculate, child: const Text('Calculate')),

          // Error message
          if (validationMessage != null) ...[
            const SizedBox(height: 14),
            Text(validationMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],

          // Results table
          if (fibonacciLevels != null && fibonacciLevels!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  // Table header
                  Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Level',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Price',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // Table rows
                  ...fibonacciLevels!.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            entry.value.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
        ],
      ),
    );
  }
}
