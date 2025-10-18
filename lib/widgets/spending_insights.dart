import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class SpendingInsights extends StatelessWidget {
  final List<Transaction> transactions;
  final String period;

  const SpendingInsights({
    super.key,
    required this.transactions,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final insights = _generateInsights();

    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Spending Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => _buildInsightItem(insight)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(SpendingInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: insight.type.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: insight.type.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            insight.type.icon,
            color: insight.type.color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<SpendingInsight> _generateInsights() {
    final List<SpendingInsight> insights = [];

    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    final income = transactions.where((t) => t.type == TransactionType.income).toList();

    if (expenses.isEmpty) {
      return insights;
    }

    // Calculate totals
    final totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = income.fold(0.0, (sum, t) => sum + t.amount);
    final averageExpense = totalExpenses / expenses.length;

    // Top spending category
    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }

    if (categoryTotals.isNotEmpty) {
      final topCategory = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      final topCategoryPercentage = (topCategory.value / totalExpenses) * 100;

      insights.add(SpendingInsight(
        title: 'Top Spending Category',
        description: '${topCategory.key} accounts for ${topCategoryPercentage.toStringAsFixed(1)}% of your spending (\$${topCategory.value.toStringAsFixed(2)})',
        type: InsightType.info,
      ));
    }

    // Spending vs Income ratio
    if (totalIncome > 0) {
      final spendingRatio = (totalExpenses / totalIncome) * 100;
      if (spendingRatio > 90) {
        insights.add(SpendingInsight(
          title: 'High Spending Alert',
          description: 'You\'re spending ${spendingRatio.toStringAsFixed(1)}% of your income. Consider reducing expenses.',
          type: InsightType.warning,
        ));
      } else if (spendingRatio < 50) {
        insights.add(SpendingInsight(
          title: 'Great Savings Rate',
          description: 'You\'re only spending ${spendingRatio.toStringAsFixed(1)}% of your income. Excellent job!',
          type: InsightType.success,
        ));
      }
    }

    // Average transaction size
    if (averageExpense > 100) {
      insights.add(SpendingInsight(
        title: 'High Average Transaction',
        description: 'Your average transaction is \$${averageExpense.toStringAsFixed(2)}. Consider if all purchases are necessary.',
        type: InsightType.warning,
      ));
    }

    // Receipt scanning usage
    final receiptTransactions = expenses.where((t) => t.isFromReceipt).length;
    if (receiptTransactions > 0) {
      final receiptPercentage = (receiptTransactions / expenses.length) * 100;
      insights.add(SpendingInsight(
        title: 'Receipt Scanning Usage',
        description: 'You\'ve scanned ${receiptTransactions} receipts (${receiptPercentage.toStringAsFixed(1)}% of transactions). Great job tracking!',
        type: InsightType.success,
      ));
    }

    // Daily spending pattern
    final dailyTotals = <int, double>{};
    for (final expense in expenses) {
      final weekday = expense.date.weekday;
      dailyTotals[weekday] = (dailyTotals[weekday] ?? 0.0) + expense.amount;
    }

    if (dailyTotals.isNotEmpty) {
      final highestDay = dailyTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      final dayName = DateFormat('EEEE').format(DateTime(2023, 1, highestDay.key));
      insights.add(SpendingInsight(
        title: 'Spending Pattern',
        description: 'You spend most on $dayName (\$${highestDay.value.toStringAsFixed(2)}).',
        type: InsightType.info,
      ));
    }

    return insights;
  }
}

class SpendingInsight {
  final String title;
  final String description;
  final InsightType type;

  SpendingInsight({
    required this.title,
    required this.description,
    required this.type,
  });
}

enum InsightType {
  info(Colors.blue, Icons.info),
  warning(Colors.orange, Icons.warning),
  success(Colors.green, Icons.check_circle),
  error(Colors.red, Icons.error);

  const InsightType(this.color, this.icon);
  final Color color;
  final IconData icon;
}




