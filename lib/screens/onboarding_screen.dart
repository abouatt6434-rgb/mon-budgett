import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../services/budget_service.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';
import 'main_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  const OnboardingScreen({super.key, required this.onThemeChanged});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _settings = SettingsService();
  final _budgetService = BudgetService();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  int _page = 0;

  final _slides = const [
    _Slide(icon: Icons.receipt_long, title: 'Suivez vos dépenses',
        subtitle: 'Enregistrez facilement toutes vos dépenses et revenus au quotidien.'),
    _Slide(icon: Icons.account_balance_wallet, title: 'Contrôlez votre budget',
        subtitle: 'Définissez un budget mensuel et recevez des alertes avant de le dépasser.'),
    _Slide(icon: Icons.insights, title: 'Analysez vos habitudes',
        subtitle: 'Visualisez vos statistiques avec des graphiques simples et clairs.'),
  ];

  Future<void> _finish() async {
    await _settings.setOnboardingDone(true);
    final name = _nameController.text.trim();
    if (name.isNotEmpty) await _settings.setUserName(name);
    final budget = double.tryParse(_budgetController.text);
    if (budget != null && budget > 0) {
      await _settings.setMonthlyBudget(budget);
      await _budgetService.setBudget(
        categoryId: kGlobalBudgetCategoryId,
        amount: budget,
        period: BudgetPeriod.mensuel,
      );
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainNavigation(onThemeChanged: widget.onThemeChanged)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastSlide = _page == _slides.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  ..._slides,
                  _SetupPage(nameController: _nameController, budgetController: _budgetController),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  TextButton(
                    onPressed: isLastSlide ? null : _finish,
                    child: Text(isLastSlide ? '' : 'Passer', style: TextStyle(color: isLastSlide ? Colors.transparent : AppColors.textLight)),
                  ),
                  const Spacer(),
                  Row(
                    children: List.generate(_slides.length + 1, (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: _page == i ? AppColors.primary : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    )),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      if (isLastSlide) {
                        _finish();
                      } else {
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      }
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(110, 44)),
                    child: Text(isLastSlide ? 'Commencer' : 'Suivant'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Slide({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 15), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SetupPage extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController budgetController;
  const _SetupPage({required this.nameController, required this.budgetController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Un dernier détail (facultatif)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Votre nom', hintText: 'Facultatif'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: budgetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Budget mensuel (FCFA)', hintText: 'Facultatif'),
          ),
        ],
      ),
    );
  }
}
