import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/calculators/index.dart';
import '../screens/home_screen.dart';
import '../screens/calculators_screen.dart';
import '../screens/news_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/calculators',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return HomeScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/calculators',
            name: 'calculators',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const CalculatorsScreen(),
            ),
          ),
          GoRoute(
            path: '/news',
            name: 'news',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const NewsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/calculator/pip',
        name: 'pip-calculator',
        builder: (context, state) => const PipCalculatorScreen(),
      ),
      GoRoute(
        path: '/calculator/position-size',
        name: 'position-size-calculator',
        builder: (context, state) => const PositionSizeCalculatorScreen(),
      ),
      GoRoute(
        path: '/calculator/forex-rebate',
        name: 'forex-rebate-calculator',
        builder: (context, state) => const ForexRebateCalculatorScreen(),
      ),
      GoRoute(
        path: '/calculator/profit',
        name: 'profit-calculator',
        builder: (context, state) => const ProfitCalculatorScreen(),
      ),
      GoRoute(
        path: '/calculator/compound-profit',
        name: 'compound-profit-calculator',
        builder: (context, state) => const CompoundProfitCalculatorScreen(),
      ),
      GoRoute(
        path: '/calculator/drawdown',
        name: 'drawdown-calculator',
        builder: (context, state) => const DrawdownCalculatorScreen(),
      ),
      GoRoute(
        path: '/calculator/risk-of-ruin',
        name: 'risk-of-ruin-calculator',
        builder: (context, state) => const RiskOfRuinCalculatorScreen(),
      ),
      GoRoute(
        path: '/calculator/pivot-points',
        name: 'pivot-points-calculator',
        builder: (context, state) => const PivotPointsCalculatorScreen(),
      ),
      GoRoute(
        path: '/calculator/fibonacci',
        name: 'fibonacci-calculator',
        builder: (context, state) => const FibonacciCalculatorScreen(),
      ),
      GoRoute(
        path: '/calculator/forex-margin',
        name: 'forex-margin-calculator',
        builder: (context, state) => const ForexMarginCalculatorScreen(),
      ),
      GoRoute(
        path: '/calculator/crypto-fees',
        name: 'crypto-fees-calculator',
        builder: (context, state) => const CryptoExchangeFeesCalculatorScreen(),
      ),
      GoRoute(
        path: '/calculator/currency-converter',
        name: 'currency-converter',
        builder: (context, state) => const CryptoFxConverterScreen(),
      ),
    ],
  );
}
