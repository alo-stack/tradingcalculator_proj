import 'package:flutter/material.dart';
import '../data/currencies_data.dart';

class CurrencySearchDialog extends StatefulWidget {
  const CurrencySearchDialog({super.key, this.selectedCurrency});

  final Currency? selectedCurrency;

  @override
  State<CurrencySearchDialog> createState() => _CurrencySearchDialogState();
}

class _CurrencySearchDialogState extends State<CurrencySearchDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Currency> _filteredCurrencies = CurrenciesData.allCurrencies;
  CurrencyCategory _selectedCategory = CurrencyCategory.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _selectedCategory = CurrencyCategory.all;
          break;
        case 1:
          _selectedCategory = CurrencyCategory.forex;
          break;
        case 2:
          _selectedCategory = CurrencyCategory.crypto;
          break;
      }
      _filterCurrencies();
    });
  }

  void _filterCurrencies() {
    final String query = _searchController.text;
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = CurrenciesData.getByCategory(_selectedCategory);
      } else {
        _filteredCurrencies = CurrenciesData.search(query);
        if (_selectedCategory == CurrencyCategory.forex) {
          _filteredCurrencies = _filteredCurrencies
              .where((c) => CurrenciesData.majorCurrencies.contains(c))
              .toList();
        } else if (_selectedCategory == CurrencyCategory.crypto) {
          _filteredCurrencies = _filteredCurrencies
              .where((c) => CurrenciesData.cryptocurrencies.contains(c))
              .toList();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            AppBar(
              title: const Text('Deposit Currency'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search currencies...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterCurrencies();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => _filterCurrencies(),
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Forex'),
                Tab(text: 'Crypto'),
              ],
            ),
            const Divider(height: 1),
            if (_selectedCategory == CurrencyCategory.forex || _selectedCategory == CurrencyCategory.all) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Major Currencies',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ],
            Expanded(
              child: _filteredCurrencies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No currencies found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _filteredCurrencies.length,
                      itemBuilder: (context, index) {
                        final Currency currency = _filteredCurrencies[index];
                        final bool isSelected = widget.selectedCurrency?.code == currency.code;
                        final bool isCrypto = CurrenciesData.cryptocurrencies.contains(currency);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCrypto
                                ? Colors.orange.withValues(alpha: 0.2)
                                : Colors.blue.withValues(alpha: 0.2),
                            child: Text(
                              currency.symbol,
                              style: TextStyle(
                                color: isCrypto ? Colors.orange : Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                currency.code,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currency.name,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, currency),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
