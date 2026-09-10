enum BudgetPeriod { hebdomadaire, mensuel }

class BudgetModel {
  final String id;
  final String categoryId; // 'GLOBAL' pour un budget global mensuel
  final double amount;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;

  BudgetModel({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'amount': amount,
      'period': period == BudgetPeriod.hebdomadaire ? 'hebdomadaire' : 'mensuel',
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      categoryId: map['categoryId'] as String,
      amount: (map['amount'] as num).toDouble(),
      period: map['period'] == 'hebdomadaire'
          ? BudgetPeriod.hebdomadaire
          : BudgetPeriod.mensuel,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
    );
  }
}
