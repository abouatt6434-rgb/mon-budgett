import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/budget_service.dart';
import '../services/settings_service.dart';
import '../services/transaction_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../widgets/amount_card.dart';
import '../widgets/budget_progress.dart';
import '../widgets/empty_state.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;
  const DashboardScreen({super.key, this.onDataChanged});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final _txService = TransactionService();
  final _budgetService = BudgetService();
  final _settings = SettingsService();

  double _balance = 0;
  double _income = 0;
  double _expense = 0;
  bool _hideBalances = false;
  List<TransactionModel> _recent = [];
  Map<String, CategoryModel> _categoriesById = {};
  BudgetProgress? _mainBudget;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final income = await _txService.getTotalIncome(start: monthStart, end: monthEnd);
    final expense = await _txService.getTotalExpense(start: monthStart, end: monthEnd);
    final balance = await _txService.getBalance();
    final recent = await _txService.getRecent(limit: 6);
    final hideBalances = await _settings.getHideBalances();
    final budgets = await _budgetService.getActiveBudgetsProgress();

    final cats = <String, CategoryModel>{};
    for (final t in recent) {
      if (!cats.containsKey(t.categoryId)) {
        final c = await _txService.getCategoryById(t.categoryId);
        if (c != null) cats[t.categoryId] = c;
      }
    }

    BudgetProgress? global;
    for (final b in budgets) {
      if (b.budget.categoryId == kGlobalBudgetCategoryId) {
        global = b;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _income = income;
      _expense = expense;
      _balance = balance;
      _recent = recent;
      _categoriesById = cats;
      _hideBalances = hideBalances;
      _mainBudget = global;
      _loading = false;
    });
  }

  Future<void> _goToAdd(TransactionType type) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddTransactionScreen(type: type)),
    );
    if (changed == true) {
      reload();
      widget.onDataChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MON BUDGET'),
        actions: [
          IconButton(
            icon: Icon(_hideBalances ? Icons.visibility_off : Icons.visibility),
            onPressed: () async {
              await _settings.setHideBalances(!_hideBalances);
              reload();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Solde', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    _hideBalances ? '•••••• FCFA' : CurrencyFormatter.format(_balance),
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AmountCard(
                    label: 'Revenus (mois)',
                    amount: _income,
                    color: AppColors.income,
                    icon: Icons.arrow_downward,
                    hidden: _hideBalances,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AmountCard(
                    label: 'Dépenses (mois)',
                    amount: _expense,
                    color: AppColors.expense,
                    icon: Icons.arrow_upward,
                    hidden: _hideBalances,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_mainBudget != null) ...[
              BudgetProgressCard(title: 'Budget du mois', progress: _mainBudget!),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dernières opérations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            if (_recent.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: EmptyState(
                  title: 'Aucune opération enregistrée',
                  subtitle: 'Commencez par ajouter votre première dépense ou revenu.',
                  icon: Icons.receipt_long_outlined,
                ),
              )
            else
              ..._recent.map((t) => TransactionTile(
                    transaction: t,
                    category: _categoriesById[t.categoryId],
                    onTap: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: t)),
                      );
                      if (changed == true) {
                        reload();
                        widget.onDataChanged?.call();
                      }
                    },
                  )),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: _AddMenuButton(onSelect: _goToAdd),
    );
  }
}

class _AddMenuButton extends StatelessWidget {
  final ValueChanged<TransactionType> onSelect;
  const _AddMenuButton({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.remove_circle_outline, color: AppColors.expense),
                    title: const Text('Ajouter une dépense'),
                    onTap: () {
                      Navigator.pop(ctx);
                      onSelect(TransactionType.depense);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline, color: AppColors.income),
                    title: const Text('Ajouter un revenu'),
                    onTap: () {
                      Navigator.pop(ctx);
                      onSelect(TransactionType.revenu);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Ajouter'),
    );
  }
}
