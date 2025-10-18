import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import 'database_provider.dart';

class TransactionProvider with ChangeNotifier {
  final DatabaseProvider _databaseProvider;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  TransactionProvider(this._databaseProvider) {
    print('TransactionProvider: Constructor called');
    // Don't load transactions here - let AccountProvider control when to load
  }

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalIncome {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpenses {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get netBalance => totalIncome - totalExpenses;

  List<Transaction> get recentTransactions {
    final sorted = List<Transaction>.from(_transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  }

  Map<String, double> get expensesByCategory {
    final Map<String, double> categoryTotals = {};
    for (final transaction in _transactions) {
      if (transaction.type == TransactionType.expense) {
        categoryTotals[transaction.category] = 
            (categoryTotals[transaction.category] ?? 0.0) + transaction.amount;
      }
    }
    return categoryTotals;
  }

  Map<String, double> get incomeByCategory {
    final Map<String, double> categoryTotals = {};
    for (final transaction in _transactions) {
      if (transaction.type == TransactionType.income) {
        categoryTotals[transaction.category] = 
            (categoryTotals[transaction.category] ?? 0.0) + transaction.amount;
      }
    }
    return categoryTotals;
  }

  Future<void> loadTransactions() async {
    print('TransactionProvider: Loading transactions...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _databaseProvider.getAllTransactions();
      print('TransactionProvider: Loaded ${_transactions.length} transactions');
    } catch (e) {
      print('TransactionProvider: Error loading transactions: $e');
      _error = 'Failed to load transactions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      print('TransactionProvider: Adding transaction: ${transaction.title} - \$${transaction.amount}');
      print('TransactionProvider: Transaction type: ${transaction.type}');
      print('TransactionProvider: Transaction category: ${transaction.category}');
      print('TransactionProvider: Transaction date: ${transaction.date}');
      print('TransactionProvider: Transaction isFromReceipt: ${transaction.isFromReceipt}');
      
      final id = await _databaseProvider.insertTransaction(transaction);
      print('TransactionProvider: Database returned ID: $id');
      
      final newTransaction = transaction.copyWith(id: id);
      print('TransactionProvider: Created new transaction with ID: ${newTransaction.id}');
      
      _transactions.insert(0, newTransaction);
      print('TransactionProvider: Transaction added to local list. Total transactions: ${_transactions.length}');
      
      print('TransactionProvider: Notifying listeners...');
      notifyListeners();
      print('TransactionProvider: Listeners notified successfully');
    } catch (e) {
      print('TransactionProvider: Error adding transaction: $e');
      print('TransactionProvider: Error stack trace: ${e.toString()}');
      _error = 'Failed to add transaction: $e';
      notifyListeners();
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _databaseProvider.updateTransaction(transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update transaction: $e';
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await _databaseProvider.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete transaction: $e';
      notifyListeners();
    }
  }

  List<Transaction> getTransactionsByDateRange(DateTime startDate, DateTime endDate) {
    return _transactions.where((t) => 
        t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.date.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  List<Transaction> getTransactionsByCategory(String category) {
    return _transactions.where((t) => t.category == category).toList();
  }

  List<Transaction> getTransactionsByType(TransactionType type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  double getTotalByDateRange(DateTime startDate, DateTime endDate, TransactionType type) {
    return getTransactionsByDateRange(startDate, endDate)
        .where((t) => t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getExpensesByCategoryInDateRange(DateTime startDate, DateTime endDate) {
    final Map<String, double> categoryTotals = {};
    final transactionsInRange = getTransactionsByDateRange(startDate, endDate);
    
    for (final transaction in transactionsInRange) {
      if (transaction.type == TransactionType.expense) {
        categoryTotals[transaction.category] = 
            (categoryTotals[transaction.category] ?? 0.0) + transaction.amount;
      }
    }
    return categoryTotals;
  }

  List<Transaction> getTransactionsFromReceipts() {
    return _transactions.where((t) => t.isFromReceipt).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

