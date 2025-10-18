import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../models/transaction.dart';
import '../models/budget.dart';

class AnalysisData {
  final String recommendation;
  final String recommendationIcon;
  final Color recommendationColor;
  final double currentBalance;
  final double balanceAfterPurchase;
  final double purchaseAmount;
  final double dailyAverage;
  final double projectedMonthly;
  final double afterPurchaseProjected;
  final double categorySpending;
  final double categoryPercentage;
  final double averageCategorySpending;
  final double projectedCategoryMonthly;
  final List<String> riskFactors;
  final bool hasBudget;
  final double? budgetUsed;
  final double? budgetAfterPurchase;
  final double? budgetAmount;

  AnalysisData({
    required this.recommendation,
    required this.recommendationIcon,
    required this.recommendationColor,
    required this.currentBalance,
    required this.balanceAfterPurchase,
    required this.purchaseAmount,
    required this.dailyAverage,
    required this.projectedMonthly,
    required this.afterPurchaseProjected,
    required this.categorySpending,
    required this.categoryPercentage,
    required this.averageCategorySpending,
    required this.projectedCategoryMonthly,
    required this.riskFactors,
    required this.hasBudget,
    this.budgetUsed,
    this.budgetAfterPurchase,
    this.budgetAmount,
  });
}

class ShouldIBuyScreen extends StatefulWidget {
  const ShouldIBuyScreen({super.key});

  @override
  State<ShouldIBuyScreen> createState() => _ShouldIBuyScreenState();
}

class _ShouldIBuyScreenState extends State<ShouldIBuyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Food & Dining';
  String? _analysisResult;
  bool _isAnalyzing = false;
  AnalysisData? _analysisData;

  final List<String> _categories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Travel',
    'Groceries',
    'Gas',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _analyzePurchase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      _analysisData = null;
    });

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    // Get current month's data
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Get transactions for current month
    final monthlyTransactions = transactionProvider.transactions
        .where((t) => t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                     t.date.isBefore(endOfMonth.add(const Duration(days: 1))) &&
                     t.type == TransactionType.expense)
        .toList();

    // Get budget for selected category
    final budgets = budgetProvider.budgets
        .where((b) => b.category == _selectedCategory &&
                     b.month == now.month &&
                     b.year == now.year)
        .toList();

    // Calculate spending in this category
    final categorySpending = monthlyTransactions
        .where((t) => t.category == _selectedCategory)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Calculate total spending
    final totalSpending = monthlyTransactions.fold(0.0, (sum, t) => sum + t.amount);

    // Get available balance (total across all time)
    final totalIncome = transactionProvider.totalIncome;
    final totalExpenses = transactionProvider.totalExpenses;
    final availableBalance = totalIncome - totalExpenses;

    // Perform analysis
    final analysis = _performAnalysis(
      amount: amount,
      category: _selectedCategory,
      categorySpending: categorySpending,
      totalSpending: totalSpending,
      availableBalance: availableBalance,
      budgets: budgets,
      monthlyTransactions: monthlyTransactions,
    );

    // Create structured analysis data
    final analysisData = _createAnalysisData(
      amount: amount,
      category: _selectedCategory,
      categorySpending: categorySpending,
      totalSpending: totalSpending,
      availableBalance: availableBalance,
      budgets: budgets,
      monthlyTransactions: monthlyTransactions,
    );

    setState(() {
      _analysisResult = analysis;
      _analysisData = analysisData;
      _isAnalyzing = false;
    });
  }

  String _performAnalysis({
    required double amount,
    required String category,
    required double categorySpending,
    required double totalSpending,
    required double availableBalance,
    required List<Budget> budgets,
    required List<Transaction> monthlyTransactions,
  }) {
    final buffer = StringBuffer();
    
    // Check available balance
    if (availableBalance < amount) {
      buffer.writeln('❌ **INSUFFICIENT FUNDS**');
      buffer.writeln('You need \$${NumberFormat('#,##0.00').format(amount - availableBalance)} more to make this purchase.');
      buffer.writeln('Current available balance: \$${NumberFormat('#,##0.00').format(availableBalance)}');
      return buffer.toString();
    }

    // Check category budget
    if (budgets.isNotEmpty) {
      final budget = budgets.first;
      final budgetUsed = categorySpending / budget.effectiveAmount;
      final afterPurchase = (categorySpending + amount) / budget.effectiveAmount;

      if (afterPurchase > 1.0) {
        buffer.writeln('⚠️ **OVER BUDGET WARNING**');
        buffer.writeln('This purchase would exceed your \$${_selectedCategory} budget.');
        buffer.writeln('Budget: \$${NumberFormat('#,##0.00').format(budget.effectiveAmount)}');
        buffer.writeln('Already spent: \$${NumberFormat('#,##0.00').format(categorySpending)} (${(budgetUsed * 100).toStringAsFixed(1)}%)');
        buffer.writeln('After purchase: \$${NumberFormat('#,##0.00').format(categorySpending + amount)} (${(afterPurchase * 100).toStringAsFixed(1)}%)');
        
        if (afterPurchase > 1.2) {
          buffer.writeln('\n❌ **NOT RECOMMENDED** - Would exceed budget by ${((afterPurchase - 1) * 100).toStringAsFixed(1)}%');
        } else {
          buffer.writeln('\n⚠️ **PROCEED WITH CAUTION** - Close to budget limit');
        }
      } else if (budgetUsed > 0.8) {
        buffer.writeln('⚠️ **BUDGET ALERT**');
        buffer.writeln('You\'ve already used ${(budgetUsed * 100).toStringAsFixed(1)}% of your \$${_selectedCategory} budget.');
        buffer.writeln('After this purchase: ${(afterPurchase * 100).toStringAsFixed(1)}%');
        buffer.writeln('\n✅ **ACCEPTABLE** - Within budget limits');
      } else {
        buffer.writeln('✅ **WITHIN BUDGET**');
        buffer.writeln('You\'ve used ${(budgetUsed * 100).toStringAsFixed(1)}% of your \$${_selectedCategory} budget.');
        buffer.writeln('After this purchase: ${(afterPurchase * 100).toStringAsFixed(1)}%');
        buffer.writeln('\n✅ **GOOD TO GO** - Plenty of budget remaining');
      }
    } else {
      buffer.writeln('ℹ️ **NO BUDGET SET**');
      buffer.writeln('You haven\'t set a budget for \$${_selectedCategory}.');
      buffer.writeln('Analysis based on your spending history and patterns.');
    }

    // Spending pattern analysis
    final currentDay = DateTime.now().day;
    final dailyAverage = totalSpending / currentDay;
    final projectedMonthly = dailyAverage * 30;
    final afterPurchaseProjected = (totalSpending + amount) / currentDay * 30;

    buffer.writeln('\n💰 **BALANCE IMPACT**');
    buffer.writeln('Current balance: \$${NumberFormat('#,##0.00').format(availableBalance)}');
    buffer.writeln('Balance after purchase: \$${NumberFormat('#,##0.00').format(availableBalance - amount)}');
    buffer.writeln('Purchase amount: \$${NumberFormat('#,##0.00').format(amount)}');

    buffer.writeln('\n📊 **SPENDING ANALYSIS**');
    buffer.writeln('Daily average spending: \$${NumberFormat('#,##0.00').format(dailyAverage)}');
    buffer.writeln('Projected monthly spending: \$${NumberFormat('#,##0.00').format(projectedMonthly)}');
    buffer.writeln('After this purchase: \$${NumberFormat('#,##0.00').format(afterPurchaseProjected)}');

    // Show historical insights if no budget is set
    if (budgets.isEmpty) {
      final categoryPercentage = totalSpending > 0 ? (categorySpending / totalSpending * 100) : 0;
      final averageCategorySpending = categorySpending / currentDay;
      final projectedCategoryMonthly = averageCategorySpending * 30;
      
      buffer.writeln('\n📈 **HISTORICAL INSIGHTS**');
      buffer.writeln('Category spending this month: \$${NumberFormat('#,##0.00').format(categorySpending)}');
      buffer.writeln('Category % of total spending: ${categoryPercentage.toStringAsFixed(1)}%');
      buffer.writeln('Daily average in this category: \$${NumberFormat('#,##0.00').format(averageCategorySpending)}');
      buffer.writeln('Projected monthly in this category: \$${NumberFormat('#,##0.00').format(projectedCategoryMonthly)}');
    }

    // Category spending comparison (only show if budget is set)
    if (budgets.isNotEmpty) {
      final categoryPercentage = (categorySpending / totalSpending * 100);
      buffer.writeln('\n📈 **CATEGORY BREAKDOWN**');
      buffer.writeln('\$${_selectedCategory} spending: \$${NumberFormat('#,##0.00').format(categorySpending)} (${categoryPercentage.toStringAsFixed(1)}% of total)');
    }

    // Final recommendation
    buffer.writeln('\n🎯 **RECOMMENDATION**');
    if (availableBalance < amount) {
      buffer.writeln('❌ **DON\'T BUY** - Insufficient funds');
    } else if (budgets.isNotEmpty) {
      // Budget-based recommendation
      final budgetRatio = (categorySpending + amount) / budgets.first.effectiveAmount;
      if (budgetRatio > 1.2) {
        buffer.writeln('❌ **DON\'T BUY** - Would significantly exceed budget');
      } else if (budgetRatio > 1.0) {
        buffer.writeln('⚠️ **THINK TWICE** - Would exceed budget');
      } else if (budgetRatio > 0.8) {
        buffer.writeln('⚠️ **BE CAREFUL** - Getting close to budget limit');
      } else {
        buffer.writeln('✅ **GO AHEAD** - Good financial decision');
      }
    } else {
      // No budget - use historical analysis
      final recommendation = _getHistoricalRecommendation(
        amount: amount,
        availableBalance: availableBalance,
        categorySpending: categorySpending,
        totalSpending: totalSpending,
        dailyAverage: dailyAverage,
        projectedMonthly: projectedMonthly,
        afterPurchaseProjected: afterPurchaseProjected,
      );
      buffer.writeln(recommendation);
    }

    return buffer.toString();
  }

  String _getHistoricalRecommendation({
    required double amount,
    required double availableBalance,
    required double categorySpending,
    required double totalSpending,
    required double dailyAverage,
    required double projectedMonthly,
    required double afterPurchaseProjected,
  }) {
    // Calculate spending velocity and balance sustainability
    final balanceAfterPurchase = availableBalance - amount;
    final balanceRatio = balanceAfterPurchase / availableBalance;
    final spendingVelocity = dailyAverage * 30; // Monthly spending rate
    final monthsOfBalance = balanceAfterPurchase / spendingVelocity;
    
    // Category spending analysis
    final categoryRatio = categorySpending / totalSpending;
    final categoryAfterPurchase = (categorySpending + amount) / (totalSpending + amount);
    
    // Historical spending trend analysis
    final spendingIncrease = (afterPurchaseProjected - projectedMonthly) / projectedMonthly;
    
    // Decision matrix based on multiple factors
    int riskScore = 0;
    String riskFactors = '';
    
    // Balance impact analysis
    if (balanceRatio < 0.1) {
      riskScore += 3;
      riskFactors += '• Very low remaining balance\n';
    } else if (balanceRatio < 0.2) {
      riskScore += 2;
      riskFactors += '• Low remaining balance\n';
    } else if (balanceRatio < 0.5) {
      riskScore += 1;
      riskFactors += '• Moderate balance impact\n';
    }
    
    // Spending velocity analysis
    if (monthsOfBalance < 1) {
      riskScore += 3;
      riskFactors += '• Less than 1 month of spending left\n';
    } else if (monthsOfBalance < 2) {
      riskScore += 2;
      riskFactors += '• Less than 2 months of spending left\n';
    } else if (monthsOfBalance < 3) {
      riskScore += 1;
      riskFactors += '• Less than 3 months of spending left\n';
    }
    
    // Category concentration analysis
    if (categoryAfterPurchase > 0.4) {
      riskScore += 2;
      riskFactors += '• High category concentration\n';
    } else if (categoryAfterPurchase > 0.3) {
      riskScore += 1;
      riskFactors += '• Moderate category concentration\n';
    }
    
    // Spending trend analysis
    if (spendingIncrease > 0.3) {
      riskScore += 2;
      riskFactors += '• Significant spending increase\n';
    } else if (spendingIncrease > 0.15) {
      riskScore += 1;
      riskFactors += '• Moderate spending increase\n';
    }
    
    // Generate recommendation based on risk score
    if (riskScore >= 6) {
      return '❌ **DON\'T BUY** - High financial risk\n$riskFactors';
    } else if (riskScore >= 4) {
      return '⚠️ **THINK TWICE** - Moderate financial risk\n$riskFactors';
    } else if (riskScore >= 2) {
      return '⚠️ **BE CAREFUL** - Some financial concerns\n$riskFactors';
    } else {
      return '✅ **GO AHEAD** - Good financial decision based on your spending patterns';
    }
  }

  AnalysisData _createAnalysisData({
    required double amount,
    required String category,
    required double categorySpending,
    required double totalSpending,
    required double availableBalance,
    required List<Budget> budgets,
    required List<Transaction> monthlyTransactions,
  }) {
    final currentDay = DateTime.now().day;
    final dailyAverage = totalSpending / currentDay;
    final projectedMonthly = dailyAverage * 30;
    final afterPurchaseProjected = (totalSpending + amount) / currentDay * 30;
    final categoryPercentage = totalSpending > 0 ? (categorySpending / totalSpending * 100) : 0;
    final averageCategorySpending = categorySpending / currentDay;
    final projectedCategoryMonthly = averageCategorySpending * 30;

    // Determine recommendation
    String recommendation;
    String recommendationIcon;
    Color recommendationColor;
    List<String> riskFactors = [];

    if (availableBalance < amount) {
      recommendation = "DON'T BUY";
      recommendationIcon = "❌";
      recommendationColor = Colors.red;
      riskFactors.add("Insufficient funds");
    } else if (budgets.isNotEmpty) {
      final budget = budgets.first;
      final budgetRatio = (categorySpending + amount) / budget.effectiveAmount;
      
      if (budgetRatio > 1.2) {
        recommendation = "DON'T BUY";
        recommendationIcon = "❌";
        recommendationColor = Colors.red;
        riskFactors.add("Would significantly exceed budget");
      } else if (budgetRatio > 1.0) {
        recommendation = "THINK TWICE";
        recommendationIcon = "⚠️";
        recommendationColor = Colors.orange;
        riskFactors.add("Would exceed budget");
      } else if (budgetRatio > 0.8) {
        recommendation = "BE CAREFUL";
        recommendationIcon = "⚠️";
        recommendationColor = Colors.orange;
        riskFactors.add("Getting close to budget limit");
      } else {
        recommendation = "GO AHEAD";
        recommendationIcon = "✅";
        recommendationColor = const Color(0xFF4CAF50);
      }
    } else {
      // Historical analysis
      final balanceAfterPurchase = availableBalance - amount;
      final balanceRatio = balanceAfterPurchase / availableBalance;
      final spendingVelocity = dailyAverage * 30;
      final monthsOfBalance = balanceAfterPurchase / spendingVelocity;
      final categoryAfterPurchase = (categorySpending + amount) / (totalSpending + amount);
      final spendingIncrease = (afterPurchaseProjected - projectedMonthly) / projectedMonthly;
      
      int riskScore = 0;
      
      // For very small purchases (under $5), be more lenient
      if (amount < 5) {
        // Only check for insufficient funds for small purchases
        if (availableBalance < amount) {
          riskScore = 10; // Force DON'T BUY
        } else {
          riskScore = 0; // Force GO AHEAD
        }
      } else {
      
      if (balanceRatio < 0.1) {
        riskScore += 3;
        riskFactors.add("Very low remaining balance");
      } else if (balanceRatio < 0.2) {
        riskScore += 2;
        riskFactors.add("Low remaining balance");
      } else if (balanceRatio < 0.5) {
        riskScore += 1;
        riskFactors.add("Moderate balance impact");
      }
      
      if (monthsOfBalance < 1) {
        riskScore += 3;
        riskFactors.add("Less than 1 month of spending left");
      } else if (monthsOfBalance < 2) {
        riskScore += 2;
        riskFactors.add("Less than 2 months of spending left");
      } else if (monthsOfBalance < 3) {
        riskScore += 1;
        riskFactors.add("Less than 3 months of spending left");
      }
      
      // Only consider category concentration risk for purchases over $5
      if (amount > 5) {
        if (categoryAfterPurchase > 0.4) {
          riskScore += 2;
          riskFactors.add("High category concentration");
        } else if (categoryAfterPurchase > 0.3) {
          riskScore += 1;
          riskFactors.add("Moderate category concentration");
        }
      }
      
      // Only consider spending increase risk for purchases over $10
      if (amount > 10) {
        if (spendingIncrease > 0.3) {
          riskScore += 2;
          riskFactors.add("Significant spending increase");
        } else if (spendingIncrease > 0.15) {
          riskScore += 1;
          riskFactors.add("Moderate spending increase");
        }
      }
      }
      
      if (riskScore >= 6) {
        recommendation = "DON'T BUY";
        recommendationIcon = "❌";
        recommendationColor = Colors.red;
      } else if (riskScore >= 4) {
        recommendation = "THINK TWICE";
        recommendationIcon = "⚠️";
        recommendationColor = Colors.orange;
      } else if (riskScore >= 2) {
        recommendation = "BE CAREFUL";
        recommendationIcon = "⚠️";
        recommendationColor = Colors.orange;
      } else {
        recommendation = "GO AHEAD";
        recommendationIcon = "✅";
        recommendationColor = const Color(0xFF4CAF50);
      }
    }

    return AnalysisData(
      recommendation: recommendation,
      recommendationIcon: recommendationIcon,
      recommendationColor: recommendationColor,
      currentBalance: availableBalance,
      balanceAfterPurchase: availableBalance - amount,
      purchaseAmount: amount,
      dailyAverage: dailyAverage,
      projectedMonthly: projectedMonthly,
      afterPurchaseProjected: afterPurchaseProjected,
      categorySpending: categorySpending,
      categoryPercentage: categoryPercentage.toDouble(),
      averageCategorySpending: averageCategorySpending,
      projectedCategoryMonthly: projectedCategoryMonthly,
      riskFactors: riskFactors,
      hasBudget: budgets.isNotEmpty,
      budgetUsed: budgets.isNotEmpty ? categorySpending / budgets.first.effectiveAmount : null,
      budgetAfterPurchase: budgets.isNotEmpty ? (categorySpending + amount) / budgets.first.effectiveAmount : null,
      budgetAmount: budgets.isNotEmpty ? budgets.first.effectiveAmount : null,
    );
  }

  Widget _buildAnalysisResult(BuildContext context) {
    if (_analysisData == null) return const SizedBox.shrink();
    
    final data = _analysisData!;
    
    return Column(
      children: [
        // Recommendation Card
        Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  data.recommendationColor.withOpacity(0.1),
                  data.recommendationColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Recommendation Icon and Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        data.recommendationIcon,
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.recommendation,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: data.recommendationColor,
                              ),
                            ),
                            Text(
                              _getRecommendationSubtitle(data.recommendation),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (data.riskFactors.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Risk Factors',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...data.riskFactors.map((factor) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const SizedBox(width: 20),
                                const Text('• '),
                                Expanded(child: Text(factor)),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Balance Impact Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Balance Impact',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildBalanceCard(
                        'Current Balance',
                        data.currentBalance,
                        Icons.account_balance,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBalanceCard(
                        'After Purchase',
                        data.balanceAfterPurchase,
                        Icons.shopping_cart,
                        data.balanceAfterPurchase < 0 ? Colors.red : const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100]!,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Purchase Amount:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700]!,
                        ),
                      ),
                      Text(
                        '\$${NumberFormat('#,##0.00').format(data.purchaseAmount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Spending Analysis Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Spending Analysis',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSpendingChart(data),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Daily Average',
                        data.dailyAverage,
                        Icons.today,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Monthly Projection',
                        data.projectedMonthly,
                        Icons.calendar_month,
                        Theme.of(context).brightness == Brightness.dark ? Colors.orange : Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Category Analysis Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.category, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Category Analysis',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'This Month',
                        data.categorySpending,
                        Icons.calendar_month,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Daily Average',
                        data.averageCategorySpending,
                        Icons.today,
                        Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100]!,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Category % of Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700]!,
                        ),
                      ),
                      Text(
                        '${data.categoryPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        if (data.hasBudget) ...[
          const SizedBox(height: 16),
          
          // Budget Analysis Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pie_chart, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Budget Analysis',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildBudgetProgress(data),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getRecommendationSubtitle(String recommendation) {
    switch (recommendation) {
      case "DON'T BUY":
        return "High financial risk";
      case "THINK TWICE":
        return "Moderate financial risk";
      case "BE CAREFUL":
        return "Some financial concerns";
      case "GO AHEAD":
        return "Good financial decision";
      default:
        return "Analysis complete";
    }
  }

  Widget _buildBalanceCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${NumberFormat('#,##0.00').format(amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '\$${NumberFormat('#,##0.00').format(value)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingChart(AnalysisData data) {
    // Create a more meaningful chart showing spending trends
    final currentSpending = data.dailyAverage * 30; // Current monthly projection
    final afterPurchaseSpending = data.afterPurchaseProjected;
    
    // Create spots for the last 7 days and projected next 7 days
    List<FlSpot> spots = [];
    List<String> xLabels = [];
    
    // Add historical data (simulated based on daily average)
    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), data.dailyAverage));
      xLabels.add('Day ${i + 1}');
    }
    
    // Add projected data after purchase
    for (int i = 7; i < 14; i++) {
      final projectedDaily = afterPurchaseSpending / 30;
      spots.add(FlSpot(i.toDouble(), projectedDaily));
      xLabels.add('Day ${i + 1}');
    }
    
    final gridColor = Colors.grey[300]!;
    final textColor = Colors.grey[600]!;
    final backgroundColor = Colors.grey[50]!;
    final borderColor = Colors.grey[300]!;
    
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Chart title
          Text(
            'Daily Spending Trend (Before vs After Purchase)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          // Chart
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: gridColor,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: gridColor,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final style = TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        );
                        Widget text;
                        if (value.toInt() == 0) {
                          text = Text('Day 1', style: style);
                        } else if (value.toInt() == 6) {
                          text = Text('Day 7', style: style);
                        } else if (value.toInt() == 7) {
                          text = Text('Day 8', style: style);
                        } else if (value.toInt() == 13) {
                          text = Text('Day 14', style: style);
                        } else {
                          text = Text('', style: style);
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: text,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final style = TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        );
                        return Text('\$${value.toStringAsFixed(0)}', style: style);
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: borderColor),
                ),
                lineBarsData: [
                  // Historical spending line
                  LineChartBarData(
                    spots: spots.take(7).toList(),
                    isCurved: true,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.orange : Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Projected spending line
                  LineChartBarData(
                    spots: spots.skip(7).toList(),
                    isCurved: true,
                    color: data.recommendationColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Vertical line to separate historical from projected
                  LineChartBarData(
                    spots: [
                      FlSpot(6.5, 0),
                      FlSpot(6.5, (data.dailyAverage * 1.5)),
                    ],
                    isCurved: false,
                    color: Colors.grey[400]!,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                minY: 0,
                maxY: data.dailyAverage * 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Historical', Theme.of(context).brightness == Brightness.dark ? Colors.orange : Colors.blue),
              const SizedBox(width: 20),
              _buildLegendItem('Projected', data.recommendationColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600]!,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetProgress(AnalysisData data) {
    if (data.budgetUsed == null || data.budgetAfterPurchase == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget Usage',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700]!,
              ),
            ),
            Text(
              '${(data.budgetUsed! * 100).toStringAsFixed(1)}% → ${(data.budgetAfterPurchase! * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: data.budgetUsed!,
          backgroundColor: Colors.grey[300]!,
          valueColor: AlwaysStoppedAnimation<Color>(
            data.budgetUsed! > 1.0 ? Colors.red : 
            data.budgetUsed! > 0.8 ? Colors.orange : const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget: \$${NumberFormat('#,##0.00').format(data.budgetAmount!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600]!,
              ),
            ),
            Text(
              'After: \$${NumberFormat('#,##0.00').format(data.categorySpending + data.purchaseAmount)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600]!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Should I Buy It?'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchase Analysis',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: '\$',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isAnalyzing ? null : _analyzePurchase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isAnalyzing
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Analyzing...'),
                                  ],
                                )
                              : const Text(
                                  'Analyze Purchase',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_analysisResult != null) ...[
                const SizedBox(height: 16),
                _buildAnalysisResult(context),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
