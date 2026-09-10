import 'package:uuid/uuid.dart';
import '../models/budget_model.dart';
import 'database_service.dart';
import 'transaction_service.dart';

const String kGlobalBudgetCategoryId = 'GLOBAL';

class BudgetProgress {
  final BudgetModel budget;
  final double spent;
  double get remaining => budget.amount - spent;
  double get percent => budget.amount == 0 ? 0 : (spent / budget.amount).clamp(0, 999);

  BudgetProgress({required this.budget, required this.spent});
}

class BudgetService {
  final _uuid = const Uuid();
  final _txService = TransactionService();

  Future<String> setBudget({
    required String categoryId,
    required double amount,
    required BudgetPeriod period,
  }) async {
    final db = await DatabaseService.instance.database;
    final now = DateTime.now();
    DateTime start;
    DateTime end;
    if (period == BudgetPeriod.mensuel) {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    } else {
      final weekday = now.weekday; // 1 = lundi
      start = now.subtract(Duration(days: weekday - 1));
      end = start.add(const Duration(days: 6));
    }

    // Remplace un éventuel budget existant pour la même catégorie/période active
    final existing = await db.query(
      'budgets',
      where: 'categoryId = ? AND period = ?',
      whereArgs: [categoryId, period == BudgetPeriod.mensuel ? 'mensuel' : 'hebdomadaire'],
    );
    for (final row in existing) {
      await db.delete('budgets', where: 'id = ?', whereArgs: [row['id']]);
    }

    final id = _uuid.v4();
    final budget = BudgetModel(
      id: id,
      categoryId: categoryId,
      amount: amount,
      period: period,
      startDate: start,
      endDate: end,
    );
    await db.insert('budgets', budget.toMap());
    return id;
  }

  Future<void> deleteBudget(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BudgetModel>> getAllBudgets() async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query('budgets', orderBy: 'startDate DESC');
    return maps.map((m) => BudgetModel.fromMap(m)).toList();
  }

  Future<List<BudgetProgress>> getActiveBudgetsProgress() async {
    final budgets = await getAllBudgets();
    final now = DateTime.now();
    final active = budgets.where(
      (b) => !now.isBefore(b.startDate) && !now.isAfter(b.endDate),
    );

    final result = <BudgetProgress>[];
    for (final b in active) {
      double spent;
      if (b.categoryId == kGlobalBudgetCategoryId) {
        spent = await _txService.getTotalExpense(
          start: b.startDate,
          end: b.endDate,
        );
      } else {
        final byCategory = await _txService.getExpensesByCategory(
          start: b.startDate,
          end: b.endDate,
        );
        spent = byCategory[b.categoryId] ?? 0;
      }
      result.add(BudgetProgress(budget: b, spent: spent));
    }
    return result;
  }

  /// Retourne le niveau d'alerte à afficher, ou null si aucune alerte n'est
  /// franchie (seuils : 50%, 75%, 90%, 100%).
  static String? alertLabelForPercent(double percent) {
    if (percent >= 1.0) return 'Budget atteint (100%)';
    if (percent >= 0.9) return 'Budget presque atteint (90%)';
    if (percent >= 0.75) return 'Attention : 75% du budget utilisé';
    if (percent >= 0.5) return 'La moitié du budget est utilisée';
    return null;
  }
}
