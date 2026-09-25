import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_scroll_behavior.dart';
import 'core/theme/app_theme.dart';
import 'screens/budget_screen.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const PocketlyApp());
}

class PocketlyApp extends StatelessWidget {
  const PocketlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Pocketly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        scrollBehavior: const AppScrollBehavior(),
        home: const SplashScreen(),
        routes: {
          '/budget': (_) => const BudgetHost(),
        },
      ),
    );
  }
}

class BudgetHost extends StatelessWidget {
  const BudgetHost({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BudgetScreen(onBack: () => Navigator.of(context).maybePop()),
    );
  }
}
