import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/category_model.dart';
import '../utils/constants.dart';

/// Gère la base de données locale SQLite.
/// L'application fonctionne entièrement hors ligne : toutes les données
/// (transactions, catégories, budgets) sont stockées sur l'appareil.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mon_budget.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        categoryId TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        note TEXT,
        receiptPath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon INTEGER NOT NULL,
        type TEXT NOT NULL,
        isDefault INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        categoryId TEXT NOT NULL,
        amount REAL NOT NULL,
        period TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL
      )
    ''');

    await _seedDefaultCategories(db);
  }

  Future<void> _seedDefaultCategories(Database db) async {
    const uuid = Uuid();
    final batch = db.batch();

    for (final cat in DefaultCategories.expense) {
      final model = CategoryModel(
        id: uuid.v4(),
        name: cat['name'] as String,
        icon: cat['icon'],
        type: TransactionType.depense,
        isDefault: true,
      );
      batch.insert('categories', model.toMap());
    }

    for (final cat in DefaultCategories.income) {
      final model = CategoryModel(
        id: uuid.v4(),
        name: cat['name'] as String,
        icon: cat['icon'],
        type: TransactionType.revenu,
        isDefault: true,
      );
      batch.insert('categories', model.toMap());
    }

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  /// Supprime toutes les données (utilisé par "Supprimer toutes les données")
  Future<void> wipeAll() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('budgets');
    // Les catégories par défaut sont conservées, on ne supprime que les
    // catégories personnalisées.
    await db.delete('categories', where: 'isDefault = 0');
  }
}
