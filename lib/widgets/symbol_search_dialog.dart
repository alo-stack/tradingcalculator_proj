import 'package:flutter/material.dart';
import '../data/symbols_data.dart';

class SymbolSearchDialog extends StatefulWidget {
  const SymbolSearchDialog({super.key, this.selectedSymbol});

  final TradingSymbol? selectedSymbol;

  @override
  State<SymbolSearchDialog> createState() => _SymbolSearchDialogState();
}

class _SymbolSearchDialogState extends State<SymbolSearchDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<TradingSymbol> _filteredSymbols = SymbolsData.allSymbols;
  SymbolCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
          _selectedCategory = null;
          break;
        case 1:
          _selectedCategory = SymbolCategory.forex;
          break;
        case 2:
          _selectedCategory = SymbolCategory.cryptocurrency;
          break;
        case 3:
          _selectedCategory = SymbolCategory.stock;
          break;
        case 4:
          _selectedCategory = SymbolCategory.indices;
          break;
        case 5:
          _selectedCategory = SymbolCategory.commodity;
          break;
      }
      _filterSymbols();
    });
  }

  void _filterSymbols() {
    final String query = _searchController.text;
    setState(() {
      if (query.isEmpty && _selectedCategory == null) {
        _filteredSymbols = SymbolsData.allSymbols;
      } else if (query.isEmpty) {
        _filteredSymbols = SymbolsData.getByCategory(_selectedCategory!);
      } else {
        _filteredSymbols = SymbolsData.search(query);
        if (_selectedCategory != null) {
          _filteredSymbols = _filteredSymbols.where((s) => s.category == _selectedCategory).toList();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            AppBar(
              title: const Text('Symbol Search'),
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
                  hintText: 'Search symbols...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterSymbols();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => _filterSymbols(),
              ),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Forex'),
                Tab(text: 'Crypto'),
                Tab(text: 'Stock'),
                Tab(text: 'Indices'),
                Tab(text: 'Commodity'),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: _filteredSymbols.isEmpty
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
                            'No symbols found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredSymbols.length,
                      itemBuilder: (context, index) {
                        final TradingSymbol symbol = _filteredSymbols[index];
                        final bool isSelected = widget.selectedSymbol?.symbol == symbol.symbol;

                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(symbol.category).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getCategoryIcon(symbol.category),
                              color: _getCategoryColor(symbol.category),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            symbol.symbol,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          subtitle: Text(symbol.description),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(symbol.category).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  symbol.category.displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getCategoryColor(symbol.category),
                                  ),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                          onTap: () => Navigator.pop(context, symbol),
                        );
                      },
                    ),
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
