import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../services/budget_service.dart';
import '../services/transaction_service.dart';
import '../utils/constants.dart';
import '../widgets/budget_progress.dart';
import '../widgets/empty_state.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetService = BudgetService();
  final _txService = TransactionService();
  List<BudgetProgress> _progress = [];
  Map<String, CategoryModel> _categoriesById = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final progress = await _budgetService.getActiveBudgetsProgress();
    final cats = <String, CategoryModel>{};
    for (final p in progress) {
      if (p.budget.categoryId != kGlobalBudgetCategoryId &&
          !cats.containsKey(p.budget.categoryId)) {
        final c = await _txService.getCategoryById(p.budget.categoryId);
        if (c != null) cats[p.budget.categoryId] = c;
      }
    }
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _categoriesById = cats;
      _loading = false;
    });
  }

  Future<void> _openAddBudget() async {
    final expenseCats = await _txService.getCategories(TransactionType.depense);
    if (!mounted) return;

    String? selectedCategoryId; // null = budget global
    BudgetPeriod period = BudgetPeriod.mensuel;
    final amountController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nouveau budget', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Budget global (toutes catégories)')),
                    ...expenseCats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (v) => setModalState(() => selectedCategoryId = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Montant du budget (FCFA)'),
                ),
                const SizedBox(height: 16),
                const Text('Période'),
                Wrap(spacing: 8, children: [
                  ChoiceChip(
                    label: const Text('Mensuel'),
                    selected: period == BudgetPeriod.mensuel,
                    onSelected: (_) => setModalState(() => period = BudgetPeriod.mensuel),
                  ),
                  ChoiceChip(
                    label: const Text('Hebdomadaire'),
                    selected: period == BudgetPeriod.hebdomadaire,
                    onSelected: (_) => setModalState(() => period = BudgetPeriod.hebdomadaire),
                  ),
                ]),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Veuillez saisir un montant valide.')),
                      );
                      return;
                    }
                    await _budgetService.setBudget(
                      categoryId: selectedCategoryId ?? kGlobalBudgetCategoryId,
                      amount: amount,
                      period: period,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  },
                  child: const Text('ENREGISTRER LE BUDGET'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _progress.isEmpty
              ? EmptyState(
                  title: 'Aucun budget défini',
                  subtitle: 'Définissez un budget mensuel ou par catégorie pour suivre vos dépenses.',
                  icon: Icons.account_balance_wallet_outlined,
                  actionLabel: 'Définir un budget',
                  onAction: _openAddBudget,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _progress.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final p = _progress[i];
                      final title = p.budget.categoryId == kGlobalBudgetCategoryId
                          ? 'Budget global (${p.budget.period == BudgetPeriod.mensuel ? "mensuel" : "hebdomadaire"})'
                          : (_categoriesById[p.budget.categoryId]?.name ?? 'Catégorie');
                      return BudgetProgressCard(title: title, progress: p);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddBudget,
        icon: const Icon(Icons.add),
        label: const Text('Budget'),
      ),
    );
  }
}
