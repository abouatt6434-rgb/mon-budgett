import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/main_navigation.dart';
import 'screens/onboarding_screen.dart';
import 'services/settings_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const MonBudgetApp());
}

class MonBudgetApp extends StatefulWidget {
  const MonBudgetApp({super.key});

  @override
  State<MonBudgetApp> createState() => _MonBudgetAppState();
}

class _MonBudgetAppState extends State<MonBudgetApp> {
  final _settings = SettingsService();
  ThemeMode _themeMode = ThemeMode.system;
  bool _loading = true;
  bool _onboardingDone = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadTheme();
    final done = await _settings.getOnboardingDone();
    setState(() {
      _onboardingDone = done;
      _loading = false;
    });
  }

  Future<void> _loadTheme() async {
    final mode = await _settings.getThemeMode();
    setState(() {
      _themeMode = switch (mode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MON BUDGET',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _onboardingDone
              ? MainNavigation(onThemeChanged: _loadTheme)
              : OnboardingScreen(onThemeChanged: _loadTheme),
    );
  }
}
