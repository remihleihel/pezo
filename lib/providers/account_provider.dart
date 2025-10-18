import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/account.dart';
import 'database_provider.dart';
import 'transaction_provider.dart';
import 'budget_provider.dart';

class AccountProvider with ChangeNotifier {
  List<Account> _accounts = [];
  Account? _currentAccount;
  bool _isLoading = false;
  String? _error;
  DatabaseProvider? _databaseProvider;
  TransactionProvider? _transactionProvider;
  BudgetProvider? _budgetProvider;

  List<Account> get accounts => _accounts;
  Account? get currentAccount => _currentAccount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set the provider references
  void setDatabaseProvider(DatabaseProvider databaseProvider) {
    _databaseProvider = databaseProvider;
  }
  
  void setTransactionProvider(TransactionProvider transactionProvider) {
    _transactionProvider = transactionProvider;
  }
  
  void setBudgetProvider(BudgetProvider budgetProvider) {
    _budgetProvider = budgetProvider;
  }

  // Initialize accounts from storage
  Future<void> loadAccounts() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getString('accounts');
      print('AccountProvider: SharedPreferences accountsJson: $accountsJson');
      
      if (accountsJson != null) {
        final List<dynamic> accountsList = json.decode(accountsJson);
        _accounts = accountsList.map((json) => Account.fromJson(json)).toList();
        print('AccountProvider: Loaded ${_accounts.length} accounts from storage');
        for (final account in _accounts) {
          print('AccountProvider: - ${account.name} (${account.id})');
        }
      } else {
        print('AccountProvider: No accounts found in SharedPreferences');
      }
      
      // If no accounts exist, create a default account
      if (_accounts.isEmpty) {
        print('AccountProvider: No accounts found, creating default account');
        final defaultAccount = Account(
          id: 'default',
          name: 'My Account',
          createdAt: DateTime.now(),
          lastAccessed: DateTime.now(),
          isLocal: true,
        );
        _accounts.add(defaultAccount);
        await _saveAccounts();
        print('AccountProvider: Created default account: ${defaultAccount.name} (${defaultAccount.id})');
      } else {
        print('AccountProvider: Found existing accounts, not creating default');
      }
      
      // Load current account
      final currentAccountId = prefs.getString('current_account_id');
      if (currentAccountId != null) {
        _currentAccount = _accounts.firstWhere(
          (account) => account.id == currentAccountId,
          orElse: () => _accounts.isNotEmpty ? _accounts.first : throw Exception('No accounts found'),
        );
      } else if (_accounts.isNotEmpty) {
        _currentAccount = _accounts.first;
        // Save the first account as current if none was set
        await _saveCurrentAccount();
      }
      
      // Switch to the current account's database
      if (_currentAccount != null && _databaseProvider != null) {
        print('AccountProvider: About to switch to account: ${_currentAccount!.name} (${_currentAccount!.id})');
        await _databaseProvider!.switchToAccount(_currentAccount!.id);
        print('AccountProvider: Loaded and switched to account: ${_currentAccount!.name} (${_currentAccount!.id})');
        print('AccountProvider: Database switched to: wis_${_currentAccount!.id}.db');
        
        // Load data from the correct database
        if (_transactionProvider != null) {
          await _transactionProvider!.loadTransactions();
          print('AccountProvider: Loaded transactions for account: ${_currentAccount!.name}');
        }
        if (_budgetProvider != null) {
          await _budgetProvider!.loadBudgets();
          await _budgetProvider!.loadSpendingGoals();
          print('AccountProvider: Loaded budgets and goals for account: ${_currentAccount!.name}');
        }
      }
      
      _setError(null);
    } catch (e) {
      _setError('Failed to load accounts: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new local account
  Future<Account> createLocalAccount(String name) async {
    _setLoading(true);
    try {
      final account = Account(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        createdAt: DateTime.now(),
        lastAccessed: DateTime.now(),
        isLocal: true,
      );

      // Check if this is the first real account (default account still has default name)
      final defaultAccount = _accounts.firstWhere((acc) => acc.id == 'default', orElse: () => throw Exception('Default account not found'));
      final isFirstRealAccount = defaultAccount.name == 'My Account';
      
      if (isFirstRealAccount) {
        // First real account: Rename the default account instead of creating new one
        final defaultAccountIndex = _accounts.indexWhere((acc) => acc.id == 'default');
        final renamedAccount = defaultAccount.copyWith(name: name);
        _accounts[defaultAccountIndex] = renamedAccount;
        await _saveAccounts();
        _currentAccount = renamedAccount;
        await _saveCurrentAccount();
        // Don't switch databases - stay on the default database
        print('AccountProvider: Renamed default account to: ${renamedAccount.name} (${renamedAccount.id})');
        notifyListeners();
        _setError(null);
        return renamedAccount; // Return the renamed account, not the new one
      } else {
        // Additional account: Create new account and database
        _accounts.add(account);
        await _saveAccounts();
        
        if (_databaseProvider != null) {
          await _databaseProvider!.switchToAccount(account.id);
          _currentAccount = account;
          await _saveCurrentAccount();
          print('AccountProvider: Created and switched to new account with separate database: ${account.name} (${account.id})');
        }
      }
      
      _setError(null);
      return account;
    } catch (e) {
      _setError('Failed to create account: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Create account with Google Sign-In
  Future<Account> createGoogleAccount(String name, String email, String googleId) async {
    _setLoading(true);
    try {
      final account = Account(
        id: googleId,
        name: name,
        email: email,
        googleId: googleId,
        createdAt: DateTime.now(),
        lastAccessed: DateTime.now(),
        isLocal: false,
        hasGoogleBackup: true,
      );

      _accounts.add(account);
      await _saveAccounts();
      
      // Switch to the new account's database
      if (_databaseProvider != null) {
        await _databaseProvider!.switchToAccount(account.id);
        print('AccountProvider: Created and switched to new Google account: ${account.name} (${account.id})');
      }
      
      _setError(null);
      return account;
    } catch (e) {
      _setError('Failed to create Google account: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Switch to a different account
  Future<void> switchAccount(Account account) async {
    _setLoading(true);
    try {
      _currentAccount = account;
      
      // Update last accessed time
      final updatedAccount = account.copyWith(lastAccessed: DateTime.now());
      final index = _accounts.indexWhere((a) => a.id == account.id);
      if (index != -1) {
        _accounts[index] = updatedAccount;
        _currentAccount = updatedAccount;
      }
      
      // Switch to the account's database
      if (_databaseProvider != null) {
        // All accounts use their own database (default account uses 'default' database)
        await _databaseProvider!.switchToAccount(account.id);
        print('AccountProvider: Switched to database for account: ${account.name} (${account.id})');
        
        // Reload data from the database
        if (_transactionProvider != null) {
          await _transactionProvider!.loadTransactions();
          print('AccountProvider: Reloaded transactions for account: ${account.name}');
        }
        if (_budgetProvider != null) {
          await _budgetProvider!.loadBudgets();
          print('AccountProvider: Reloaded budgets for account: ${account.name}');
        }
      }
      
      await _saveAccounts();
      await _saveCurrentAccount();
      
      _setError(null);
    } catch (e) {
      _setError('Failed to switch account: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete an account
  Future<void> deleteAccount(Account account) async {
    _setLoading(true);
    try {
      _accounts.removeWhere((a) => a.id == account.id);
      
      // If we're deleting the current account, switch to another one
      if (_currentAccount?.id == account.id) {
        if (_accounts.isNotEmpty) {
          _currentAccount = _accounts.first;
        } else {
          _currentAccount = null;
        }
      }
      
      await _saveAccounts();
      await _saveCurrentAccount();
      
      _setError(null);
    } catch (e) {
      _setError('Failed to delete account: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update account information
  Future<void> updateAccount(Account account) async {
    _setLoading(true);
    try {
      final index = _accounts.indexWhere((a) => a.id == account.id);
      if (index != -1) {
        _accounts[index] = account;
        
        // Update current account if it's the same
        if (_currentAccount?.id == account.id) {
          _currentAccount = account;
        }
        
        await _saveAccounts();
        await _saveCurrentAccount();
      }
      
      _setError(null);
    } catch (e) {
      _setError('Failed to update account: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Enable/disable Google backup for an account
  Future<void> toggleGoogleBackup(Account account, bool enable) async {
    _setLoading(true);
    try {
      final updatedAccount = account.copyWith(hasGoogleBackup: enable);
      await updateAccount(updatedAccount);
      
      _setError(null);
    } catch (e) {
      _setError('Failed to toggle Google backup: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get database path for current account
  String getDatabasePath() {
    if (_currentAccount == null) {
      return 'wis_default.db';
    }
    return 'wis_${_currentAccount!.id}.db';
  }

  // Get backup file name for current account
  String getBackupFileName() {
    if (_currentAccount == null) {
      return 'wis_backup_default.json';
    }
    return 'wis_backup_${_currentAccount!.id}.json';
  }

  // Save accounts to storage
  Future<void> _saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = json.encode(_accounts.map((a) => a.toJson()).toList());
    await prefs.setString('accounts', accountsJson);
  }

  // Save current account ID to storage
  Future<void> _saveCurrentAccount() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentAccount != null) {
      await prefs.setString('current_account_id', _currentAccount!.id);
    } else {
      await prefs.remove('current_account_id');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _setError(null);
  }
}
