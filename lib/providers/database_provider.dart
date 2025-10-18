import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as models;
import '../models/budget.dart';

class DatabaseProvider extends ChangeNotifier {
  static Database? _database;
  static const String _databaseName = 'wis.db';
  static const int _databaseVersion = 2;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    print('DatabaseProvider: Initializing database...');
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    print('DatabaseProvider: Database path: $path');
    print('DatabaseProvider: Database name: $_databaseName');
    print('DatabaseProvider: Database version: $_databaseVersion');

    try {
      final database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      print('DatabaseProvider: Database initialized successfully');
      print('DatabaseProvider: Database is open: ${database.isOpen}');
      return database;
    } catch (e) {
      print('DatabaseProvider: Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    print('DatabaseProvider: Creating database tables...');
    
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        receipt_image_path TEXT,
        is_from_receipt INTEGER NOT NULL DEFAULT 0,
        merchant_name TEXT
      )
    ''');
    print('DatabaseProvider: Created transactions table');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL,
        year INTEGER NOT NULL,
        carryover_enabled INTEGER NOT NULL DEFAULT 0,
        carried_over_amount REAL
      )
    ''');
    print('DatabaseProvider: Created budgets table');

    await db.execute('''
      CREATE TABLE spending_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0,
        target_date TEXT,
        is_achieved INTEGER NOT NULL DEFAULT 0,
        created_date TEXT NOT NULL
      )
    ''');
    print('DatabaseProvider: Created spending_goals table');
    print('DatabaseProvider: All tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('DatabaseProvider: Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      // Add carryover columns to budgets table
      try {
        await db.execute('ALTER TABLE budgets ADD COLUMN carryover_enabled INTEGER NOT NULL DEFAULT 0');
        print('DatabaseProvider: Added carryover_enabled column to budgets table');
      } catch (e) {
        print('DatabaseProvider: Error adding carryover_enabled column: $e');
        // Column might already exist, continue
      }
      
      try {
        await db.execute('ALTER TABLE budgets ADD COLUMN carried_over_amount REAL');
        print('DatabaseProvider: Added carried_over_amount column to budgets table');
      } catch (e) {
        print('DatabaseProvider: Error adding carried_over_amount column: $e');
        // Column might already exist, continue
      }
    }
  }

  Future<void> initDatabase() async {
    print('DatabaseProvider: initDatabase() called');
    await database;
    print('DatabaseProvider: initDatabase() completed');
  }

  // Transaction CRUD operations
  Future<int> insertTransaction(models.Transaction transaction) async {
    try {
      print('DatabaseProvider: Inserting transaction ${transaction.title}');
      print('DatabaseProvider: Transaction data: ${transaction.toJson()}');
      final db = await database;
      print('DatabaseProvider: Database obtained, inserting...');
      final result = await db.insert('transactions', transaction.toJson());
      print('DatabaseProvider: Transaction inserted with ID: $result');
      notifyListeners(); // Notify listeners that data has changed
      return result;
    } catch (e) {
      print('DatabaseProvider: Error inserting transaction: $e');
      print('DatabaseProvider: Error stack trace: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<models.Transaction>> getAllTransactions() async {
    print('DatabaseProvider: Getting all transactions...');
    final db = await database;
    print('DatabaseProvider: Database obtained for query');
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    print('DatabaseProvider: Found ${maps.length} transactions in database');
    if (maps.isNotEmpty) {
      print('DatabaseProvider: First transaction: ${maps.first}');
    }

    final transactions = List.generate(maps.length, (i) {
      try {
        final transaction = models.Transaction.fromJson(maps[i]);
        print('DatabaseProvider: Parsed transaction $i: ${transaction.title}');
        return transaction;
      } catch (e) {
        print('DatabaseProvider: Error parsing transaction $i: $e');
        print('DatabaseProvider: Raw data: ${maps[i]}');
        rethrow;
      }
    });
    print('DatabaseProvider: Successfully parsed ${transactions.length} transactions');
    return transactions;
  }

  Future<List<models.Transaction>> getTransactionsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return models.Transaction.fromJson(maps[i]);
    });
  }

  Future<List<models.Transaction>> getTransactionsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return models.Transaction.fromJson(maps[i]);
    });
  }

  Future<List<models.Transaction>> getTransactionsByType(models.TransactionType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return models.Transaction.fromJson(maps[i]);
    });
  }

  Future<models.Transaction?> getTransactionById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return models.Transaction.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateTransaction(models.Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toJson(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Analytics queries
  Future<double> getTotalIncome() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      [models.TransactionType.income.name],
    );
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<double> getTotalExpenses() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      [models.TransactionType.expense.name],
    );
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<double> getTotalIncomeByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND date BETWEEN ? AND ?',
      [models.TransactionType.income.name, startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<double> getTotalExpensesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND date BETWEEN ? AND ?',
      [models.TransactionType.expense.name, startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<Map<String, double>> getExpensesByCategory() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM transactions WHERE type = ? GROUP BY category',
      [models.TransactionType.expense.name],
    );

    return Map.fromEntries(
      result.map((row) => MapEntry(
        row['category'] as String,
        (row['total'] as double?) ?? 0.0,
      )),
    );
  }

  Future<Map<String, double>> getExpensesByCategoryInDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM transactions WHERE type = ? AND date BETWEEN ? AND ? GROUP BY category',
      [models.TransactionType.expense.name, startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return Map.fromEntries(
      result.map((row) => MapEntry(
        row['category'] as String,
        (row['total'] as double?) ?? 0.0,
      )),
    );
  }

  Future<List<models.Transaction>> getRecentTransactions({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return models.Transaction.fromJson(maps[i]);
    });
  }

  // Budget CRUD operations
  Future<int> insertBudget(Budget budget) async {
    try {
      print('DatabaseProvider: Inserting budget ${budget.category} - \$${budget.amount}');
      final db = await database;
      final result = await db.insert('budgets', budget.toJson());
      print('DatabaseProvider: Budget inserted with ID: $result');
      notifyListeners();
      return result;
    } catch (e) {
      print('DatabaseProvider: Error inserting budget: $e');
      rethrow;
    }
  }

  Future<List<Budget>> getAllBudgets() async {
    print('DatabaseProvider: Getting all budgets...');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      orderBy: 'year DESC, month DESC',
    );
    print('DatabaseProvider: Found ${maps.length} budgets in database');

    return List.generate(maps.length, (i) {
      return Budget.fromJson(maps[i]);
    });
  }

  Future<List<Budget>> getBudgetsForMonth(String month, int year) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );

    return List.generate(maps.length, (i) {
      return Budget.fromJson(maps[i]);
    });
  }

  Future<int> updateBudget(Budget budget) async {
    final db = await database;
    final result = await db.update(
      'budgets',
      budget.toJson(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
    notifyListeners();
    return result;
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;
    final result = await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
    return result;
  }

  // Spending Goals CRUD operations
  Future<int> insertSpendingGoal(SpendingGoal goal) async {
    try {
      print('DatabaseProvider: Inserting spending goal ${goal.title} - \$${goal.targetAmount}');
      final db = await database;
      final result = await db.insert('spending_goals', goal.toJson());
      print('DatabaseProvider: Spending goal inserted with ID: $result');
      notifyListeners();
      return result;
    } catch (e) {
      print('DatabaseProvider: Error inserting spending goal: $e');
      rethrow;
    }
  }

  Future<List<SpendingGoal>> getAllSpendingGoals() async {
    print('DatabaseProvider: Getting all spending goals...');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'spending_goals',
      orderBy: 'created_date DESC',
    );
    print('DatabaseProvider: Found ${maps.length} spending goals in database');

    return List.generate(maps.length, (i) {
      return SpendingGoal.fromJson(maps[i]);
    });
  }

  Future<int> updateSpendingGoal(SpendingGoal goal) async {
    final db = await database;
    final result = await db.update(
      'spending_goals',
      goal.toJson(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
    notifyListeners();
    return result;
  }

  Future<int> deleteSpendingGoal(int id) async {
    final db = await database;
    final result = await db.delete(
      'spending_goals',
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
    return result;
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      print('DatabaseProvider: Clearing all data...');
      final db = await database;
      await db.delete('transactions');
      await db.delete('budgets');
      await db.delete('spending_goals');
      print('DatabaseProvider: All data cleared successfully');
      notifyListeners();
    } catch (e) {
      print('DatabaseProvider: Error clearing data: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
