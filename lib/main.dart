import 'package:flutter/material.dart';
import 'screens/calculators/index.dart';
import 'services/news_service.dart';

void main() {
  runApp(const TradingCalculatorApp());
}

class TradingCalculatorApp extends StatelessWidget {
  const TradingCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trading Toolkit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const AppHomeScreen(),
    );
  }
}

class AppHomeScreen extends StatefulWidget {
  const AppHomeScreen({super.key});

  @override
  State<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends State<AppHomeScreen> {
  int currentIndex = 0;

  static const List<Widget> sections = [
    CalculatorListSection(),
    MarketNewsSection(),
  ];

  @override
  Widget build(BuildContext context) {
    final List<String> titles = ['Forex Calculators', 'Market News'];

    return Scaffold(
      appBar: AppBar(title: Text(titles[currentIndex])),
      body: SafeArea(child: sections[currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Calculator',
          ),
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper),
            label: 'News',
          ),
        ],
        onDestinationSelected: (value) {
          setState(() {
            currentIndex = value;
          });
        },
      ),
    );
  }
}

class CalculatorListSection extends StatelessWidget {
  const CalculatorListSection({super.key});

  @override
  Widget build(BuildContext context) {
    final List<CalculatorItem> calculators = [
      CalculatorItem(
        title: 'Pip Calculator',
        description: 'Calculate pip value for forex pairs',
        icon: Icons.monetization_on,
        screen: const PipCalculatorScreen(),
      ),
      CalculatorItem(
        title: 'Position Size Calculator',
        description: 'Calculate position size and risk',
        icon: Icons.calculate,
        screen: const PositionSizeCalculatorScreen(),
      ),
      CalculatorItem(
        title: 'Forex Rebate Calculator',
        description: 'Calculate trading rebates',
        icon: Icons.card_giftcard,
        screen: const ForexRebateCalculatorScreen(),
      ),
      CalculatorItem(
        title: 'Profit Calculator',
        description: 'Calculate profit/loss on trades',
        icon: Icons.trending_up,
        screen: const ProfitCalculatorScreen(),
      ),
      CalculatorItem(
        title: 'Compound Profit Calculator',
        description: 'Calculate compounding returns',
        icon: Icons.auto_graph,
        screen: const CompoundProfitCalculatorScreen(),
      ),
      CalculatorItem(
        title: 'Drawdown Calculator',
        description: 'Calculate drawdown and recovery',
        icon: Icons.trending_down,
        screen: const DrawdownCalculatorScreen(),
      ),
      CalculatorItem(
        title: 'Risk of Ruin Calculator',
        description: 'Calculate probability of account ruin',
        icon: Icons.warning_amber,
        screen: const RiskOfRuinCalculatorScreen(),
      ),
      CalculatorItem(
        title: 'Pivot Points Calculator',
        description: 'Calculate pivot points and S/R levels',
        icon: Icons.show_chart,
        screen: const PivotPointsCalculatorScreen(),
      ),
      CalculatorItem(
        title: 'Fibonacci Calculator',
        description: 'Calculate Fibonacci retracement levels',
        icon: Icons.timeline,
        screen: const FibonacciCalculatorScreen(),
      ),
      CalculatorItem(
        title: 'Forex Margin Calculator',
        description: 'Calculate required margin',
        icon: Icons.account_balance,
        screen: const ForexMarginCalculatorScreen(),
      ),
      CalculatorItem(
        title: 'Crypto Exchange Fees Calculator',
        description: 'Calculate crypto trading fees',
        icon: Icons.currency_bitcoin,
        screen: const CryptoExchangeFeesCalculatorScreen(),
      ),
      CalculatorItem(
        title: 'Crypto & FX Converter',
        description: 'Convert between currencies',
        icon: Icons.swap_horiz,
        screen: const CryptoFxConverterScreen(),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: calculators.length,
      itemBuilder: (context, index) {
        final CalculatorItem item = calculators[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: Icon(item.icon, size: 32),
            title: Text(item.title),
            subtitle: Text(item.description),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (context) => item.screen),
              );
            },
          ),
        );
      },
    );
  }
}

class CalculatorItem {
  const CalculatorItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.screen,
  });

  final String title;
  final String description;
  final IconData icon;
  final Widget screen;
}

class MarketNewsSection extends StatefulWidget {
  const MarketNewsSection({super.key});

  @override
  State<MarketNewsSection> createState() => _MarketNewsSectionState();
}

class _MarketNewsSectionState extends State<MarketNewsSection> {
  List<NewsArticle> newsArticles = <NewsArticle>[];
  bool isLoading = false;
  String? errorMessage;
  DateTime? lastUpdated;

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final List<NewsArticle> articles = await NewsService.fetchBusinessNews();
      setState(() {
        newsArticles = articles;
        isLoading = false;
        lastUpdated = DateTime.now();
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Business & Trading News',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (lastUpdated != null)
                      Text(
                        'Updated: ${lastUpdated!.hour.toString().padLeft(2, '0')}:${lastUpdated!.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: isLoading ? null : fetchNews,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Builder(
            builder: (context) {
              if (isLoading && newsArticles.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (errorMessage != null && newsArticles.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load news',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: fetchNews,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (newsArticles.isEmpty) {
                return const Center(
                  child: Text('No news articles available'),
                );
              }

              return RefreshIndicator(
                onRefresh: fetchNews,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                  itemCount: newsArticles.length,
                  itemBuilder: (context, index) {
                    final NewsArticle article = newsArticles[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: InkWell(
                        onTap: () {
                          // Could open article URL in browser here
                          showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(article.title),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      article.description,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Source: ${article.source}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Text(
                                      'Published: ${article.timeAgo}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.title,
                                style: Theme.of(context).textTheme.titleSmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              if (article.description.isNotEmpty)
                                Text(
                                  article.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.article_outlined,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${article.source} • ${article.timeAgo}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.secondary,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
