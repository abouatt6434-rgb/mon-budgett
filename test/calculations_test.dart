import 'package:flutter_test/flutter_test.dart';
import 'package:mon_budget/models/budget_model.dart';
import 'package:mon_budget/services/budget_service.dart';

void main() {
  group('Alertes de budget', () {
    test('Aucune alerte en dessous de 50%', () {
      expect(BudgetService.alertLabelForPercent(0.3), isNull);
    });

    test('Alerte à 50%', () {
      expect(BudgetService.alertLabelForPercent(0.5), isNotNull);
    });

    test('Alerte à 75%', () {
      expect(BudgetService.alertLabelForPercent(0.75), contains('75%'));
    });

    test('Alerte à 90%', () {
      expect(BudgetService.alertLabelForPercent(0.9), contains('90%'));
    });

    test('Alerte à 100%', () {
      expect(BudgetService.alertLabelForPercent(1.0), contains('100%'));
    });
  });

  group('Calcul du solde', () {
    test('Revenus moins dépenses', () {
      const income = 250000.0;
      const expense = 125000.0;
      expect(income - expense, 125000.0);
    });

    test('Pourcentage de budget utilisé', () {
      final budget = BudgetModel(
        id: 'test',
        categoryId: 'GLOBAL',
        amount: 100000,
        period: BudgetPeriod.mensuel,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
      );
      final progress = BudgetProgress(budget: budget, spent: 75000);
      expect(progress.percent, 0.75);
      expect(progress.remaining, 25000);
    });
  });
}
