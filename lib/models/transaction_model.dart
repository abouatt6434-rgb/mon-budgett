import '../utils/constants.dart';

class TransactionModel {
  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String? description;
  final DateTime date;
  final String paymentMethod;
  final String? note;
  final String? receiptPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    this.description,
    required this.date,
    required this.paymentMethod,
    this.note,
    this.receiptPath,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type == TransactionType.depense ? 'depense' : 'revenu',
      'amount': amount,
      'categoryId': categoryId,
      'description': description,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'note': note,
      'receiptPath': receiptPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      type: map['type'] == 'depense'
          ? TransactionType.depense
          : TransactionType.revenu,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] as String,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      paymentMethod: map['paymentMethod'] as String,
      note: map['note'] as String?,
      receiptPath: map['receiptPath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  TransactionModel copyWith({
    double? amount,
    String? categoryId,
    String? description,
    DateTime? date,
    String? paymentMethod,
    String? note,
    String? receiptPath,
  }) {
    return TransactionModel(
      id: id,
      type: type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      receiptPath: receiptPath ?? this.receiptPath,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
