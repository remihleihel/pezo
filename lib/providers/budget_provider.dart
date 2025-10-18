import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../providers/database_provider.dart';

class BudgetProvider with ChangeNotifier {
  final DatabaseProvider _databaseProvider;
  List<Budget> _budgets = [];
  List<SpendingGoal> _spendingGoals = [];
  bool _isLoading = false;
  String? _error;

  BudgetProvider(this._databaseProvider) {
    loadBudgets();
    loadSpendingGoals();
  }

  List<Budget> get budgets => _budgets;
  List<SpendingGoal> get spendingGoals => _spendingGoals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBudgets() async {
    print('BudgetProvider: Loading budgets...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _budgets = await _databaseProvider.getAllBudgets();
      print('BudgetProvider: Loaded ${_budgets.length} budgets');
    } catch (e) {
      print('BudgetProvider: Error loading budgets: $e');
      _error = 'Failed to load budgets: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSpendingGoals() async {
    print('BudgetProvider: Loading spending goals...');
    try {
      _spendingGoals = await _databaseProvider.getAllSpendingGoals();
      print('BudgetProvider: Loaded ${_spendingGoals.length} spending goals');
    } catch (e) {
      print('BudgetProvider: Error loading spending goals: $e');
      _error = 'Failed to load spending goals: $e';
    }
    notifyListeners();
  }

  Future<void> addBudget(Budget budget) async {
    try {
      print('BudgetProvider: Adding budget: ${budget.category} - \$${budget.amount}');
      final id = await _databaseProvider.insertBudget(budget);
      final newBudget = budget.copyWith(id: id);
      _budgets.add(newBudget);
      notifyListeners();
    } catch (e) {
      print('BudgetProvider: Error adding budget: $e');
      _error = 'Failed to add budget: $e';
      notifyListeners();
    }
  }

  Future<void> updateBudget(Budget budget) async {
    try {
      await _databaseProvider.updateBudget(budget);
      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index != -1) {
        _budgets[index] = budget;
        notifyListeners();
      }
    } catch (e) {
      print('BudgetProvider: Error updating budget: $e');
      _error = 'Failed to update budget: $e';
      notifyListeners();
    }
  }

  Future<void> deleteBudget(int id) async {
    try {
      await _databaseProvider.deleteBudget(id);
      _budgets.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      print('BudgetProvider: Error deleting budget: $e');
      _error = 'Failed to delete budget: $e';
      notifyListeners();
    }
  }

  Future<void> addSpendingGoal(SpendingGoal goal) async {
    try {
      print('BudgetProvider: Adding spending goal: ${goal.title} - \$${goal.targetAmount}');
      final id = await _databaseProvider.insertSpendingGoal(goal);
      final newGoal = goal.copyWith(id: id);
      _spendingGoals.add(newGoal);
      notifyListeners();
    } catch (e) {
      print('BudgetProvider: Error adding spending goal: $e');
      _error = 'Failed to add spending goal: $e';
      notifyListeners();
    }
  }

  Future<void> updateSpendingGoal(SpendingGoal goal) async {
    try {
      await _databaseProvider.updateSpendingGoal(goal);
      final index = _spendingGoals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _spendingGoals[index] = goal;
        notifyListeners();
      }
    } catch (e) {
      print('BudgetProvider: Error updating spending goal: $e');
      _error = 'Failed to update spending goal: $e';
      notifyListeners();
    }
  }

  Future<void> deleteSpendingGoal(int id) async {
    try {
      await _databaseProvider.deleteSpendingGoal(id);
      _spendingGoals.removeWhere((g) => g.id == id);
      notifyListeners();
    } catch (e) {
      print('BudgetProvider: Error deleting spending goal: $e');
      _error = 'Failed to delete spending goal: $e';
      notifyListeners();
    }
  }

  List<Budget> getBudgetsForMonth(String month, int year) {
    return _budgets.where((b) => b.month == month && b.year == year).toList();
  }

  List<Budget> getBudgetsForDateRange(DateTime startDate, DateTime endDate) {
    return _budgets.where((b) {
      final budgetDate = DateTime(b.year, _getMonthNumber(b.month), 1);
      return budgetDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             budgetDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  int _getMonthNumber(String month) {
    const months = {
      'January': 1, 'February': 2, 'March': 3, 'April': 4,
      'May': 5, 'June': 6, 'July': 7, 'August': 8,
      'September': 9, 'October': 10, 'November': 11, 'December': 12
    };
    return months[month] ?? 1;
  }

  double getTotalBudgetForMonth(String month, int year) {
    return getBudgetsForMonth(month, year)
        .fold(0.0, (sum, budget) => sum + budget.amount);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
