import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_transactions_list.dart';
import '../widgets/spending_chart.dart';
import '../widgets/pezo_logo.dart';
import 'add_transaction_screen.dart';
import 'edit_transaction_screen.dart';
import 'analytics_screen.dart';
import 'receipt_scanner_screen.dart';
import 'settings_screen.dart';
import 'should_i_buy_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    DashboardTab(onNavigateToTransactions: () => setState(() => _selectedIndex = 1)),
    const TransactionsTab(),
    const AnalyticsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.orange : Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddTransactionBottomSheet(),
    );
  }
}

class DashboardTab extends StatefulWidget {
  final VoidCallback? onNavigateToTransactions;
  
  const DashboardTab({super.key, this.onNavigateToTransactions});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String _selectedPeriod = 'All Time';
  DateTime _customStartDate = DateTime.now();
  DateTime _customEndDate = DateTime.now();

  final List<String> _periods = [
    'All Time',
    'This Week',
    'This Month',
    'Last Month',
    'Last 30 Days',
    'Last 90 Days',
    'This Year',
    'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    _updateDateRange();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('Pezo'),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
                _updateDateRange();
              });
            },
            itemBuilder: (context) => _periods.map((period) {
              return PopupMenuItem(
                value: period,
                child: Row(
                  children: [
                    Text(period),
                    if (period == _selectedPeriod)
                      const Icon(Icons.check, color: Colors.blue),
                  ],
                ),
              );
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedPeriod),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReceiptScannerScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_checkout),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShouldIBuyScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          print('HomeScreen: Building with ${transactionProvider.transactions.length} transactions');
          print('HomeScreen: Is loading: ${transactionProvider.isLoading}');
          print('HomeScreen: Error: ${transactionProvider.error}');
          
          if (transactionProvider.isLoading) {
            print('HomeScreen: Showing loading indicator');
            return const Center(child: CircularProgressIndicator());
          }

          // Filter transactions based on selected period
          final filteredTransactions = _getFilteredTransactions(transactionProvider.transactions);
          final filteredIncome = _calculateFilteredIncome(filteredTransactions);
          final filteredExpenses = _calculateFilteredExpenses(filteredTransactions);
          final filteredBalance = filteredIncome - filteredExpenses;

          print('HomeScreen: Building main content');
          return RefreshIndicator(
            onRefresh: () {
              print('HomeScreen: Refresh triggered');
              return transactionProvider.loadTransactions();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BalanceCard(
                    totalIncome: filteredIncome,
                    totalExpenses: filteredExpenses,
                    netBalance: filteredBalance,
                  ),
                  const SizedBox(height: 20),
                  const QuickActions(),
                  const SizedBox(height: 20),
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  RecentTransactionsList(
                    transactions: filteredTransactions.take(10).toList(),
                    onViewAllTransactions: widget.onNavigateToTransactions,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'This Month\'s Spending',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SpendingChart(
                    expensesByCategory: transactionProvider.expensesByCategory,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'All Time':
        _customStartDate = DateTime(2020);
        _customEndDate = now;
        break;
      case 'This Week':
        _customStartDate = now.subtract(Duration(days: now.weekday - 1));
        _customEndDate = now;
        break;
      case 'This Month':
        _customStartDate = DateTime(now.year, now.month, 1);
        _customEndDate = now;
        break;
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        _customStartDate = lastMonth;
        _customEndDate = DateTime(now.year, now.month, 0);
        break;
      case 'Last 30 Days':
        _customStartDate = now.subtract(const Duration(days: 30));
        _customEndDate = now;
        break;
      case 'Last 90 Days':
        _customStartDate = now.subtract(const Duration(days: 90));
        _customEndDate = now;
        break;
      case 'This Year':
        _customStartDate = DateTime(now.year, 1, 1);
        _customEndDate = now;
        break;
      case 'Custom Range':
        _showCustomDateRangeDialog();
        break;
    }
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    if (_selectedPeriod == 'All Time') {
      return transactions;
    }
    
    return transactions.where((transaction) {
      return transaction.date.isAfter(_customStartDate.subtract(const Duration(days: 1))) &&
             transaction.date.isBefore(_customEndDate.add(const Duration(days: 1)));
    }).toList();
  }

  double _calculateFilteredIncome(List<Transaction> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calculateFilteredExpenses(List<Transaction> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  void _showCustomDateRangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Date Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_customStartDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _customStartDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _customStartDate = date);
                }
              },
            ),
            ListTile(
              title: const Text('End Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_customEndDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _customEndDate,
                  firstDate: _customStartDate,
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _customEndDate = date);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedPeriod = 'Custom Range';
              });
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  String _selectedPeriod = 'All Time';
  DateTime _customStartDate = DateTime.now();
  DateTime _customEndDate = DateTime.now();

  final List<String> _periods = [
    'All Time',
    'This Week',
    'This Month',
    'Last Month',
    'Last 30 Days',
    'Last 90 Days',
    'This Year',
    'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    _updateDateRange();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
                _updateDateRange();
              });
            },
            itemBuilder: (context) => _periods.map((period) {
              return PopupMenuItem(
                value: period,
                child: Row(
                  children: [
                    Text(period),
                    if (period == _selectedPeriod)
                      const Icon(Icons.check, color: Colors.blue),
                  ],
                ),
              );
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedPeriod),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReceiptScannerScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          if (transactionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter transactions based on selected period
          final filteredTransactions = _getFilteredTransactions(transactionProvider.transactions);

          if (filteredTransactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _selectedPeriod == 'All Time' 
                        ? 'No transactions yet'
                        : 'No transactions for $_selectedPeriod',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedPeriod == 'All Time'
                        ? 'Add your first transaction or scan a receipt'
                        : 'Try selecting a different time period',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => transactionProvider.loadTransactions(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final transaction = filteredTransactions[index];
                return TransactionCard(transaction: transaction);
              },
            ),
          );
        },
      ),
    );
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'All Time':
        _customStartDate = DateTime(2020);
        _customEndDate = now;
        break;
      case 'This Week':
        _customStartDate = now.subtract(Duration(days: now.weekday - 1));
        _customEndDate = now;
        break;
      case 'This Month':
        _customStartDate = DateTime(now.year, now.month, 1);
        _customEndDate = now;
        break;
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        _customStartDate = lastMonth;
        _customEndDate = DateTime(now.year, now.month, 0);
        break;
      case 'Last 30 Days':
        _customStartDate = now.subtract(const Duration(days: 30));
        _customEndDate = now;
        break;
      case 'Last 90 Days':
        _customStartDate = now.subtract(const Duration(days: 90));
        _customEndDate = now;
        break;
      case 'This Year':
        _customStartDate = DateTime(now.year, 1, 1);
        _customEndDate = now;
        break;
      case 'Custom Range':
        _showCustomDateRangeDialog();
        break;
    }
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    if (_selectedPeriod == 'All Time') {
      return transactions;
    }
    
    return transactions.where((transaction) {
      return transaction.date.isAfter(_customStartDate.subtract(const Duration(days: 1))) &&
             transaction.date.isBefore(_customEndDate.add(const Duration(days: 1)));
    }).toList();
  }

  void _showCustomDateRangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Date Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_customStartDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _customStartDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _customStartDate = date);
                }
              },
            ),
            ListTile(
              title: const Text('End Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_customEndDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _customEndDate,
                  firstDate: _customStartDate,
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _customEndDate = date);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedPeriod = 'Custom Range';
              });
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnalyticsScreen();
  }
}

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome ? Colors.green : Colors.red;
    final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: amountColor.withOpacity(0.1),
          child: Icon(icon, color: amountColor),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transaction.category),
            if (transaction.merchantName != null)
              Text(
                transaction.merchantName!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            Text(
              DateFormat('MMM dd, yyyy').format(transaction.date),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: amountColor,
                fontSize: 16,
              ),
            ),
            if (transaction.isFromReceipt)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Receipt',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        onTap: () => _showTransactionDetails(context),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(transaction.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: \$${transaction.amount.toStringAsFixed(2)}'),
            Text('Category: ${transaction.category}'),
            Text('Date: ${DateFormat('MMM dd, yyyy').format(transaction.date)}'),
            if (transaction.description != null)
              Text('Description: ${transaction.description}'),
            if (transaction.merchantName != null)
              Text('Merchant: ${transaction.merchantName}'),
            if (transaction.isFromReceipt)
              const Text('Source: Receipt Scan'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editTransaction(context);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTransaction(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editTransaction(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(transaction: transaction),
      ),
    );
  }

  void _deleteTransaction(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<TransactionProvider>(context, listen: false)
                  .deleteTransaction(transaction.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction deleted successfully!')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
