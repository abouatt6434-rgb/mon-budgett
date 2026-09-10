import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/transaction_service.dart';
import '../utils/constants.dart';
import '../widgets/stat_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _txService = TransactionService();

  double _today = 0, _week = 0, _month = 0, _year = 0, _income = 0;
  Map<String, double> _byCategory = {};
  Map<String, CategoryModel> _categoriesById = {};
  bool _loading = true;

  static const _palette = [
    AppColors.primary, AppColors.warning, AppColors.expense,
    Color(0xFF6C63FF), Color(0xFF00B8D9), Color(0xFFE91E63),
    Color(0xFF8D6E63), Color(0xFF607D8B), Color(0xFFFF7043),
    Color(0xFF26A69A), Color(0xFF9C27B0), Color(0xFF3F51B5),
    Color(0xFFCDDC39),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);

    final today = await _txService.getTotalExpense(start: startOfToday);
    final week = await _txService.getTotalExpense(start: startOfWeek);
    final month = await _txService.getTotalExpense(start: startOfMonth);
    final year = await _txService.getTotalExpense(start: startOfYear);
    final income = await _txService.getTotalIncome(start: startOfMonth);
    final byCategory = await _txService.getExpensesByCategory(start: startOfMonth);

    final cats = <String, CategoryModel>{};
    for (final id in byCategory.keys) {
      final c = await _txService.getCategoryById(id);
      if (c != null) cats[id] = c;
    }

    if (!mounted) return;
    setState(() {
      _today = today;
      _week = week;
      _month = month;
      _year = year;
      _income = income;
      _byCategory = byCategory;
      _categoriesById = cats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalExpense = _byCategory.values.fold(0.0, (a, b) => a + b);
    final entries = _byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                StatCard(label: "Dépenses aujourd'hui", value: _today, icon: Icons.today),
                StatCard(label: 'Dépenses (semaine)', value: _week, icon: Icons.calendar_view_week),
                StatCard(label: 'Dépenses (mois)', value: _month, icon: Icons.calendar_month, color: AppColors.expense),
                StatCard(label: 'Dépenses (année)', value: _year, icon: Icons.event_note),
                StatCard(label: 'Revenus (mois)', value: _income, icon: Icons.arrow_downward, color: AppColors.income),
                StatCard(label: 'Solde (mois)', value: _income - _month, icon: Icons.account_balance),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Répartition des dépenses par catégorie',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text('Aucune dépense ce mois-ci', style: TextStyle(color: AppColors.textLight))),
              )
            else ...[
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: List.generate(entries.length, (i) {
                      final e = entries[i];
                      final percent = totalExpense == 0 ? 0 : (e.value / totalExpense) * 100;
                      return PieChartSectionData(
                        value: e.value,
                        color: _palette[i % _palette.length],
                        title: '${percent.toStringAsFixed(0)}%',
                        radius: 60,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(entries.length, (i) {
                final e = entries[i];
                final cat = _categoriesById[e.key];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: _palette[i % _palette.length], shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(cat?.name ?? 'Autre')),
                      Text(e.value.toStringAsFixed(0)),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
