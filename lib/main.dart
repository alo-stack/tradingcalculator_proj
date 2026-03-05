import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'core/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppTheme.configureSystemUI();
  runApp(const QuickPipsApp());
}

class QuickPipsApp extends StatelessWidget {
  const QuickPipsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'QuickPips',
      theme: AppTheme.darkTheme(),
      routerConfig: AppRouter.router,
    );
  }
}
