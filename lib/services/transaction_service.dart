import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';
import 'database_service.dart';

class TransactionService {
  final _uuid = const Uuid();

  Future<String> addTransaction({
    required TransactionType type,
    required double amount,
    required String categoryId,
    String? description,
    required DateTime date,
    required String paymentMethod,
    String? note,
    String? receiptPath,
  }) async {
    final db = await DatabaseService.instance.database;
    final now = DateTime.now();
    final id = _uuid.v4();

    final transaction = TransactionModel(
      id: id,
      type: type,
      amount: amount,
      categoryId: categoryId,
      description: description,
      date: date,
      paymentMethod: paymentMethod,
      note: note,
      receiptPath: receiptPath,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('transactions', transaction.toMap());
    return id;
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> getRecent({int limit = 5}) async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query(
      'transactions',
      orderBy: 'date DESC, createdAt DESC',
      limit: limit,
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> search({
    String? query,
    TransactionType? type,
    String? categoryId,
    String? paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
    String orderBy = 'date DESC',
  }) async {
    final db = await DatabaseService.instance.database;
    final where = <String>[];
    final args = <dynamic>[];

    if (query != null && query.trim().isNotEmpty) {
      where.add('(description LIKE ? OR note LIKE ? OR paymentMethod LIKE ?)');
      args.addAll(['%$query%', '%$query%', '%$query%']);
    }
    if (type != null) {
      where.add('type = ?');
      args.add(type == TransactionType.depense ? 'depense' : 'revenu');
    }
    if (categoryId != null) {
      where.add('categoryId = ?');
      args.add(categoryId);
    }
    if (paymentMethod != null) {
      where.add('paymentMethod = ?');
      args.add(paymentMethod);
    }
    if (startDate != null) {
      where.add('date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      where.add('date <= ?');
      args.add(endDate.toIso8601String());
    }

    final maps = await db.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: orderBy,
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  // ---- Calculs de solde ----

  Future<double> getTotalIncome({DateTime? start, DateTime? end}) async {
    final txs = await search(
      type: TransactionType.revenu,
      startDate: start,
      endDate: end,
    );
    return txs.fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<double> getTotalExpense({DateTime? start, DateTime? end}) async {
    final txs = await search(
      type: TransactionType.depense,
      startDate: start,
      endDate: end,
    );
    return txs.fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<double> getBalance() async {
    final income = await getTotalIncome();
    final expense = await getTotalExpense();
    return income - expense;
  }

  // ---- Catégories ----

  Future<List<CategoryModel>> getCategories(TransactionType type) async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type == TransactionType.depense ? 'depense' : 'revenu'],
      orderBy: 'isDefault DESC, name ASC',
    );
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return CategoryModel.fromMap(maps.first);
  }

  Future<String> addCustomCategory({
    required String name,
    required TransactionType type,
  }) async {
    final db = await DatabaseService.instance.database;
    final id = _uuid.v4();
    final model = CategoryModel(
      id: id,
      name: name,
      icon: Icons.category,
      type: type,
      isDefault: false,
    );
    await db.insert('categories', model.toMap());
    return id;
  }

  // ---- Statistiques par catégorie ----

  Future<Map<String, double>> getExpensesByCategory({
    DateTime? start,
    DateTime? end,
  }) async {
    final txs = await search(
      type: TransactionType.depense,
      startDate: start,
      endDate: end,
    );
    final Map<String, double> result = {};
    for (final t in txs) {
      result[t.categoryId] = (result[t.categoryId] ?? 0) + t.amount;
    }
    return result;
  }
}
