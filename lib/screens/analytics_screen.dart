import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../widgets/monthly_spending_chart.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/spending_insights.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'This Month';
  DateTime _selectedDate = DateTime.now();
  DateTime _customStartDate = DateTime.now();
  DateTime _customEndDate = DateTime.now();

  final List<String> _periods = [
    'This Week',
    'This Month',
    'Last Month',
    'Last 30 Days',
    'Last 90 Days',
    'This Year',
    'Last Year',
    'Custom Range',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
                _updateSelectedDate(period);
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
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          if (transactionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final dateRange = _getDateRange();
          final transactionsInRange = transactionProvider.getTransactionsByDateRange(
            dateRange.start,
            dateRange.end,
          );

          if (transactionsInRange.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No data available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add some transactions to see analytics',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => transactionProvider.loadTransactions(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(transactionProvider, dateRange),
                  const SizedBox(height: 20),
                  MonthlySpendingChart(
                    transactions: transactionsInRange,
                    period: _selectedPeriod,
                  ),
                  const SizedBox(height: 20),
                  CategoryBreakdownChart(
                    expensesByCategory: transactionProvider.getExpensesByCategoryInDateRange(
                      dateRange.start,
                      dateRange.end,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SpendingInsights(
                    transactions: transactionsInRange,
                    period: _selectedPeriod,
                  ),
                  const SizedBox(height: 20),
                  _buildTopCategories(transactionProvider, dateRange),
                  const SizedBox(height: 20),
                  _buildRecentTrends(transactionProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(TransactionProvider provider, DateRange dateRange) {
    final totalIncome = provider.getTotalByDateRange(
      dateRange.start,
      dateRange.end,
      TransactionType.income,
    );
    final totalExpenses = provider.getTotalByDateRange(
      dateRange.start,
      dateRange.end,
      TransactionType.expense,
    );
    final netBalance = totalIncome - totalExpenses;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Income',
            totalIncome,
            Theme.of(context).brightness == Brightness.dark ? Colors.orange : Colors.green,
            Icons.arrow_upward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Expenses',
            totalExpenses,
            Colors.red,
            Icons.arrow_downward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Balance',
            netBalance,
            netBalance >= 0 ? (Colors.green) : Colors.red,
            netBalance >= 0 ? Icons.trending_up : Icons.trending_down,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              NumberFormat.currency(symbol: '\$').format(amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategories(TransactionProvider provider, DateRange dateRange) {
    final expensesByCategory = provider.getExpensesByCategoryInDateRange(
      dateRange.start,
      dateRange.end,
    );

    if (expensesByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Spending Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...sortedCategories.take(5).map((entry) {
              final percentage = (entry.value / expensesByCategory.values.fold(0.0, (a, b) => a + b)) * 100;
              return _buildCategoryItem(entry.key, entry.value, percentage);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, double amount, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            TransactionCategory.getCategoryIcon(category),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat.currency(symbol: '\$').format(amount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTrends(TransactionProvider provider) {
    final recentTransactions = provider.recentTransactions.take(5).toList();

    if (recentTransactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...recentTransactions.map((transaction) {
              final isIncome = transaction.type == TransactionType.income;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: (isIncome ? (Theme.of(context).brightness == Brightness.dark ? Colors.orange : Colors.green) : Colors.red).withOpacity(0.1),
                  child: Icon(
                    isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isIncome ? (Colors.green) : Colors.red,
                    size: 20,
                  ),
                ),
                title: Text(transaction.title),
                subtitle: Text(
                  '${transaction.category} • ${DateFormat('MMM dd').format(transaction.date)}',
                ),
                trailing: Text(
                  '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isIncome ? (Colors.green) : Colors.red,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  DateRange _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return DateRange(startOfWeek, now);
      case 'This Month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return DateRange(startOfMonth, now);
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 0);
        return DateRange(lastMonth, endOfLastMonth);
      case 'Last 30 Days':
        return DateRange(now.subtract(const Duration(days: 30)), now);
      case 'Last 90 Days':
        return DateRange(now.subtract(const Duration(days: 90)), now);
      case 'This Year':
        final startOfYear = DateTime(now.year, 1, 1);
        return DateRange(startOfYear, now);
      case 'Last Year':
        final startOfLastYear = DateTime(now.year - 1, 1, 1);
        final endOfLastYear = DateTime(now.year - 1, 12, 31);
        return DateRange(startOfLastYear, endOfLastYear);
      case 'Custom Range':
        return DateRange(_customStartDate, _customEndDate);
      default:
        return DateRange(now.subtract(const Duration(days: 30)), now);
    }
  }

  void _updateSelectedDate(String period) {
    if (period == 'Custom Range') {
      _showCustomDateRangeDialog();
    }
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

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);
}


