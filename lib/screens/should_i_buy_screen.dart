import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../services/ai_should_i_buy_service.dart';

// Sophisticated financial analysis classes
class UserFinance {
  final double balance;
  final double monthlyIncome;
  final double avgDailySpending;
  final double recurringExpenses;
  final int daysLeftInMonth;
  final double? savingsGoal;

  UserFinance({
    required this.balance,
    required this.monthlyIncome,
    required this.avgDailySpending,
    required this.recurringExpenses,
    required this.daysLeftInMonth,
    this.savingsGoal,
  });
}

class PurchaseAdvice {
  final double score;
  final String decision;
  final String reasoning;
  final double immediateBalanceAfterPurchase;
  final double expectedBalanceAfterPurchase;
  final double safeThreshold;
  final double categoryWeight;

  PurchaseAdvice({
    required this.score,
    required this.decision,
    required this.reasoning,
    required this.immediateBalanceAfterPurchase,
    required this.expectedBalanceAfterPurchase,
    required this.safeThreshold,
    required this.categoryWeight,
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
  bool _isRecurring = false;
  String _recurringFrequency = 'monthly';
  String? _analysisResult;
  bool _isAnalyzing = false;
  AnalysisData? _analysisData;
  AiDecision? _aiDecision;
  bool _aiUnavailable = false;
  bool _isLoadingAi = false;
  
  // AI analysis mode: 'auto', 'always', 'never'
  String _aiMode = 'auto';
  
  // AI service - configure with your worker URL
  static const String _workerBaseUrl = 'https://pezo-ai-worker.remihleihel.workers.dev';
  late final AiShouldIBuyService _aiService = AiShouldIBuyService(workerBaseUrl: _workerBaseUrl);
  
  // Category weights for financial wisdom analysis
  static const Map<String, double> _categoryWeights = {
    'Food & Dining': 1.0,
    'Bills & Utilities': 1.0,
    'Rent': 1.0,
    'Transportation': 0.8,
    'Gas': 0.8,
    'Healthcare': 1.0,
    'Education': 0.9,
    'Investment': 0.9,
    'Entertainment': 0.6,
    'Shopping': 0.4,
    'Luxury': 0.4,
    'Fashion': 0.4,
    'Technology': 0.4,
    'Gift': 0.7,
    'Charity': 0.7,
    'Other': 0.6,
    'Salary': 1.0,
    'Freelance': 1.0,
    'Refund': 1.0,
  };

  final List<String> _categories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Investment',
    'Luxury',
    'Fashion',
    'Technology',
    'Gift',
    'Charity',
    'Other',
  ];

  final List<String> _recurringFrequencies = [
    'weekly',
    'monthly',
    'yearly',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _analyzePurchase() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    // Show AI mode selection dialog
    final aiModeChoice = await _showAiModeDialog();
    if (aiModeChoice == null) return; // User cancelled
    
    setState(() {
      _aiMode = aiModeChoice;
      _isAnalyzing = true;
      _analysisResult = null;
      _analysisData = null;
    });

    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      
      final transactions = transactionProvider.transactions;
      final budgets = budgetProvider.budgets;
      final savingsGoals = budgetProvider.savingsGoals;
      
      // Get comprehensive financial data
      final financialData = _getFinancialData(transactions, savingsGoals);
      
      // Perform sophisticated financial analysis
      final advice = _performFinancialAnalysis(
        amount: amount,
        category: _selectedCategory,
        financialData: financialData,
        budgets: budgets,
      );

      final analysisData = _createAnalysisData(
        amount: amount,
        category: _selectedCategory,
        financialData: financialData,
        advice: advice,
        budgets: budgets,
      );

      setState(() {
        _analysisResult = advice.decision;
        _analysisData = analysisData;
        _isAnalyzing = false;
        _aiDecision = null;
        _aiUnavailable = false;
      });

      // Call AI service based on user's choice
      final shouldCallAi = _shouldCallAi(advice.score);
      if (shouldCallAi) {
        _fetchAiDecision(
          amount: amount,
          category: _selectedCategory,
          description: _descriptionController.text,
          financialData: financialData,
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _analysisResult = 'Error analyzing purchase: $e';
      });
    }
  }

  /// Show dialog to select AI analysis mode
  Future<String?> _showAiModeDialog() async {
    String selectedMode = _aiMode; // Track selected mode in dialog
    
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Analysis Mode'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('How would you like to analyze this purchase?'),
                    const SizedBox(height: 16),
                    RadioListTile<String>(
                      title: const Text('Auto'),
                      subtitle: const Text('Use AI for borderline cases (recommended)'),
                      value: 'auto',
                      groupValue: selectedMode,
                      onChanged: (value) {
                        setState(() {
                          selectedMode = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Use AI for analysis'),
                      subtitle: const Text('Always get AI insights'),
                      value: 'always',
                      groupValue: selectedMode,
                      onChanged: (value) {
                        setState(() {
                          selectedMode = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Rely on offline calculations'),
                      subtitle: const Text('Use only local app calculations'),
                      value: 'never',
                      groupValue: selectedMode,
                      onChanged: (value) {
                        setState(() {
                          selectedMode = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Note: AI analysis is limited to 3 requests per day. After the limit, the app will use offline calculations only.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cancel - return null
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(selectedMode); // Submit - return selected mode
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Determine if AI should be called based on mode and score
  bool _shouldCallAi(double score) {
    if (_workerBaseUrl.isEmpty) return false;
    
    switch (_aiMode) {
      case 'always':
        return true; // Always call AI
      case 'never':
        return false; // Never call AI
      case 'auto':
      default:
        // Auto: Only for borderline cases (score 40-80)
        return score >= 40 && score <= 80;
    }
  }

  /// Fetch AI decision in background
  Future<void> _fetchAiDecision({
    required double amount,
    required String category,
    required String description,
    required Map<String, dynamic> financialData,
  }) async {
    if (_isLoadingAi) return;

    setState(() {
      _isLoadingAi = true;
      _aiUnavailable = false;
    });

    try {
      // Calculate last 30 day spend
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final last30DayTransactions = transactionProvider.transactions
          .where((t) => t.date.isAfter(thirtyDaysAgo) && t.type == TransactionType.expense)
          .toList();
      final last30DaySpend = last30DayTransactions.fold(0.0, (sum, t) => sum + t.amount);

      // Build financial snapshot
      final snapshot = FinancialSnapshot(
        balance: financialData['currentBalance'] as double,
        monthlyIncome: financialData['avgMonthlyIncome'] as double,
        avgDailySpending: financialData['avgDailySpending'] as double,
        recurringExpenses: financialData['recurringExpenses'] as double,
        daysLeftInMonth: financialData['daysLeftInMonth'] as int,
        savingsGoal: financialData['savingsGoal'] as double?,
        last30DaySpend: last30DaySpend,
        avgMonthlySpend: (financialData['avgDailySpending'] as double) * 30,
        categoryTotals: (financialData['categorySpending'] as Map<String, double>) ?? <String, double>{},
      );

      // Build payload
      final payload = ShouldIBuyPayload(
        item: description.isNotEmpty ? description : 'Purchase',
        price: amount,
        currency: 'USD', // TODO: Make this configurable if needed
        category: category,
        isRecurring: _isRecurring,
        frequency: _isRecurring ? _recurringFrequency : null,
        snapshot: snapshot,
      );

      // Get AI decision
      print('Fetching AI decision...');
      final aiDecision = await _aiService.getAiDecision(payload);
      print('AI decision received: ${aiDecision != null ? "SUCCESS" : "NULL"}');

      if (mounted) {
        setState(() {
          _aiDecision = aiDecision;
          _aiUnavailable = aiDecision == null;
          _isLoadingAi = false;
        });
      }
    } catch (e) {
      print('Error in _fetchAiDecision: $e');
      if (mounted) {
        setState(() {
          _aiDecision = null;
          _aiUnavailable = true;
          _isLoadingAi = false;
        });
      }
    }
  }


  // Sophisticated financial analysis function
  PurchaseAdvice _shouldIBuyIt({
    required UserFinance user,
    required double amount,
    required String category,
    bool isRecurring = false,
    String? frequency,
  }) {
    // Category weights (how important/essential it is)
    final weight = _categoryWeights[category] ?? 0.6;

    // Step 1: Project remaining monthly expenses
    final projectedRemainingExpenses =
        (user.avgDailySpending * user.daysLeftInMonth) + user.recurringExpenses;

    // Step 2: Handle recurring purchase
    double projectedCostThisMonth = amount;
    double recurringMonthlyEquivalent = 0;

    if (isRecurring) {
      switch (frequency?.toLowerCase()) {
        case 'weekly':
          recurringMonthlyEquivalent = amount * 4.3;
          break;
        case 'monthly':
          recurringMonthlyEquivalent = amount;
          break;
        case 'yearly':
          recurringMonthlyEquivalent = amount / 12;
          break;
        default:
          recurringMonthlyEquivalent = amount;
      }
      projectedCostThisMonth = recurringMonthlyEquivalent;
    }

    // Step 3: Calculate immediate and projected balances
    final immediateBalanceAfterPurchase = user.balance - amount;
    final expectedBalanceAfterPurchase =
        user.balance - projectedCostThisMonth - projectedRemainingExpenses;

    // Step 4: Safe spending threshold (30% of income, minimum $100)
    final safeThreshold = (user.monthlyIncome * 0.3).clamp(100.0, double.infinity);
    
    // Step 5: Affordability score (0–100)
    // For very small purchases (< $5), always give high score if balance is positive
    double affordability;
    if (amount < 5.0 && immediateBalanceAfterPurchase > 0) {
      // Small purchases are almost always fine if you have positive balance
      affordability = 80.0 + (weight * 10); // 80-90 for small purchases
    } else if (safeThreshold <= 0 || user.monthlyIncome <= 0) {
      // No income data - base decision on balance only
      if (immediateBalanceAfterPurchase > 0) {
        affordability = 60.0 + (weight * 20); // 60-80 if positive balance
      } else {
        affordability = 20.0; // Low score if negative balance
      }
    } else {
      // Normal calculation
      final balanceRatio = expectedBalanceAfterPurchase / safeThreshold;
      affordability = (balanceRatio * 50) + (weight * 50);
      
      // Boost score if purchase is very small relative to balance
      if (amount < user.balance * 0.01) { // Less than 1% of balance
        affordability += 15;
      }
    }
    
    // Apply savings goal penalty if applicable
    if (user.savingsGoal != null && immediateBalanceAfterPurchase < user.savingsGoal!) {
      affordability -= 20; // Reduce score by 20 points if below savings goal
    }
    
    affordability = affordability.clamp(0, 100);

    // Step 6: Decision based on score
    String message;
    if (affordability >= 80) {
      message = "✅ Go for it — you're in a great financial spot.";
    } else if (affordability >= 60) {
      message = "🟡 You can buy it, but monitor your spending this month.";
    } else if (affordability >= 40) {
      message = "🟠 Think twice — this may tighten your budget.";
    } else {
      message = "🔴 Not recommended — it'll likely hurt your balance.";
    }

    // Step 7: Reasoning message
    String reason =
        "After this ${isRecurring ? 'recurring ' : ''}purchase, your projected end-of-month balance would be \$${expectedBalanceAfterPurchase.toStringAsFixed(2)}, with a safe zone of \$${safeThreshold.toStringAsFixed(2)}.";

    if (isRecurring) {
      reason +=
          " Since this is a recurring ${frequency ?? 'monthly'} expense, your monthly budget will shrink by approximately \$${recurringMonthlyEquivalent.toStringAsFixed(2)}.";
    }

    if (user.savingsGoal != null && immediateBalanceAfterPurchase < user.savingsGoal!) {
      reason += " Note: This purchase would put you below your savings goal of \$${user.savingsGoal!.toStringAsFixed(2)}.";
    }

    return PurchaseAdvice(
      score: double.parse(affordability.toStringAsFixed(1)),
      decision: message,
      reasoning: reason,
      immediateBalanceAfterPurchase: immediateBalanceAfterPurchase,
      expectedBalanceAfterPurchase: expectedBalanceAfterPurchase,
      safeThreshold: safeThreshold,
      categoryWeight: weight,
    );
  }

  // Get comprehensive financial data for analysis
  Map<String, dynamic> _getFinancialData(List<Transaction> transactions, List<SavingsGoal> savingsGoals) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final daysLeftInMonth = endOfMonth.day - now.day + 1;
    
    // Get current month transactions
    final monthlyTransactions = transactions.where((t) => 
      t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
      t.date.isBefore(endOfMonth.add(const Duration(days: 1)))
    ).toList();
    
    // Calculate monthly income and expenses
    final monthlyIncome = monthlyTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final monthlyExpenses = monthlyTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    // Calculate average daily spending
    final daysPassed = now.day;
    final avgDailySpending = daysPassed > 0 ? monthlyExpenses / daysPassed : 0.0;
    
    // Calculate total balance (all time)
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final currentBalance = totalIncome - totalExpenses;
    
    // Calculate average monthly income (from last 3 months)
    final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);
    final recentTransactions = transactions.where((t) => 
      t.date.isAfter(threeMonthsAgo.subtract(const Duration(days: 1)))
    ).toList();
    
    final recentIncome = recentTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final avgMonthlyIncome = recentIncome / 3;
    
    // Calculate recurring expenses (bills, subscriptions, etc.)
    final recurringExpenses = monthlyTransactions
        .where((t) => t.type == TransactionType.expense && 
                     (t.category == 'Bills & Utilities' || 
                      t.category == 'Rent' || 
                      t.category == 'Healthcare'))
        .fold(0.0, (sum, t) => sum + t.amount);
    
    // Calculate category spending
    final categorySpending = monthlyTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold<Map<String, double>>({}, (map, t) {
      map[t.category] = (map[t.category] ?? 0.0) + t.amount;
      return map;
    });
    
    // Use actual savings goals from user's savings goals, or fall back to 20% rule
    double? actualSavingsGoal;
    if (savingsGoals.isNotEmpty) {
      // Use the highest target amount from savings goals as savings goal
      actualSavingsGoal = savingsGoals
          .map((goal) => goal.targetAmount)
          .reduce((a, b) => a > b ? a : b);
    } else {
      // Fall back to 20% of monthly income if no goals set
      actualSavingsGoal = avgMonthlyIncome > 0 ? avgMonthlyIncome * 0.2 : null;
    }
    
    return {
      'currentBalance': currentBalance,
      'monthlyIncome': monthlyIncome,
      'avgMonthlyIncome': avgMonthlyIncome,
      'monthlyExpenses': monthlyExpenses,
      'avgDailySpending': avgDailySpending,
      'daysLeftInMonth': daysLeftInMonth,
      'daysPassed': daysPassed,
      'recurringExpenses': recurringExpenses,
      'categorySpending': categorySpending,
      'monthlyTransactions': monthlyTransactions,
      'savingsGoal': actualSavingsGoal,
    };
  }

  // Perform sophisticated financial analysis using the new system
  PurchaseAdvice _performFinancialAnalysis({
    required double amount,
    required String category,
    required Map<String, dynamic> financialData,
    required List<Budget> budgets,
  }) {
    final currentBalance = financialData['currentBalance'] as double;
    final avgMonthlyIncome = financialData['avgMonthlyIncome'] as double;
    final avgDailySpending = financialData['avgDailySpending'] as double;
    final daysLeftInMonth = financialData['daysLeftInMonth'] as int;
    final recurringExpenses = financialData['recurringExpenses'] as double;
    final savingsGoal = financialData['savingsGoal'] as double?;
    
    // Create UserFinance object
    final userFinance = UserFinance(
      balance: currentBalance,
      monthlyIncome: avgMonthlyIncome,
      avgDailySpending: avgDailySpending,
      recurringExpenses: recurringExpenses,
      daysLeftInMonth: daysLeftInMonth,
      savingsGoal: savingsGoal,
    );
    
    // Use the sophisticated analysis function
    return _shouldIBuyIt(
      user: userFinance,
      amount: amount,
      category: category,
      isRecurring: _isRecurring,
      frequency: _isRecurring ? _recurringFrequency : null,
    );
  }

  AnalysisData _createAnalysisData({
    required double amount,
    required String category,
    required Map<String, dynamic> financialData,
    required PurchaseAdvice advice,
    required List<Budget> budgets,
  }) {
    final currentBalance = financialData['currentBalance'] as double;
    final avgDailySpending = financialData['avgDailySpending'] as double;
    final monthlyExpenses = financialData['monthlyExpenses'] as double;
    final categorySpending = (financialData['categorySpending'] as Map<String, double>)[category] ?? 0.0;
    final daysLeftInMonth = financialData['daysLeftInMonth'] as int;
    final recurringExpenses = financialData['recurringExpenses'] as double;
    
    // Calculate correct metrics using the sophisticated analysis
    final currentDay = DateTime.now().day;
    final dailyAverage = avgDailySpending;
    
    // Project remaining expenses for the month
    final projectedRemainingExpenses = (avgDailySpending * daysLeftInMonth) + recurringExpenses;
    
    // Calculate projected monthly spending (based on current daily average)
    final projectedMonthly = avgDailySpending * 30;
    
    // Calculate projected spending after this purchase
    double monthlyEquivalent = amount;
    if (_isRecurring) {
      switch (_recurringFrequency.toLowerCase()) {
        case 'weekly':
          monthlyEquivalent = amount * 4.3; // 4.3 weeks per month
          break;
        case 'monthly':
          monthlyEquivalent = amount;
          break;
        case 'yearly':
          monthlyEquivalent = amount / 12;
          break;
      }
    } else {
      // For one-time purchases, don't add to monthly projection
      monthlyEquivalent = 0;
    }
    
    // Projected monthly spending after this purchase (only if recurring)
    final afterPurchaseProjected = _isRecurring ? projectedMonthly + monthlyEquivalent : projectedMonthly;
    
    // Calculate category metrics
    final categoryPercentage = monthlyExpenses > 0 ? (categorySpending / monthlyExpenses * 100).toDouble() : 0.0;
    final averageCategorySpending = categorySpending / currentDay;
    final projectedCategoryMonthly = averageCategorySpending * 30;
    
    // Convert PurchaseAdvice to AnalysisData format
    String recommendation;
    String recommendationIcon;
    Color recommendationColor;
    
    if (advice.score >= 80) {
      recommendation = "GO FOR IT";
      recommendationIcon = "✅";
      recommendationColor = Colors.green;
    } else if (advice.score >= 60) {
      recommendation = "PROCEED WITH CAUTION";
      recommendationIcon = "🟡";
      recommendationColor = Colors.orange;
    } else if (advice.score >= 40) {
      recommendation = "THINK TWICE";
      recommendationIcon = "🟠";
      recommendationColor = Colors.deepOrange;
    } else {
      recommendation = "NOT RECOMMENDED";
      recommendationIcon = "🔴";
      recommendationColor = Colors.red;
    }
    
    // Create comprehensive risk factors based on the sophisticated analysis
    final riskFactors = <String>[];
    
    // Add the main reasoning from PurchaseAdvice
    riskFactors.add(advice.reasoning);
    
    // Add specific risk factors
    if (advice.expectedBalanceAfterPurchase < 0) {
      riskFactors.add("⚠️ This purchase would put you in deficit by \$${(-advice.expectedBalanceAfterPurchase).toStringAsFixed(2)}");
    }
    
    if (advice.expectedBalanceAfterPurchase < advice.safeThreshold) {
      riskFactors.add("⚠️ End-of-month balance would be below safe threshold (\$${advice.safeThreshold.toStringAsFixed(2)})");
    }
    
    if (_isRecurring) {
      riskFactors.add("📅 This recurring ${_recurringFrequency} expense will cost \$${monthlyEquivalent.toStringAsFixed(2)} per month");
    } else {
      riskFactors.add("💳 This is a one-time purchase - no ongoing monthly cost");
    }
    
    // Add category-specific insights
        if (advice.categoryWeight < 0.5) {
          riskFactors.add("💡 This is a low-priority category (${(advice.categoryWeight * 100).toStringAsFixed(0)}% weight) - consider if it's essential");
        }
        
        // Check for budget warnings
        final categoryBudget = budgets.firstWhere(
          (budget) => budget.category == category,
          orElse: () => Budget(
            category: category,
            amount: 0,
            month: DateTime.now().month.toString(),
            year: DateTime.now().year,
          ),
        );
        
        if (categoryBudget.amount > 0) {
          final currentCategorySpending = categorySpending;
          final budgetAfterPurchase = currentCategorySpending + amount;
          final budgetUsed = (currentCategorySpending / categoryBudget.effectiveAmount * 100).toDouble();
          final budgetAfterPurchasePercent = (budgetAfterPurchase / categoryBudget.effectiveAmount * 100).toDouble();
          
          if (budgetAfterPurchase > categoryBudget.effectiveAmount) {
            riskFactors.add("⚠️ This purchase will put you OVER your \$${categoryBudget.effectiveAmount.toStringAsFixed(2)} budget for $category by \$${(budgetAfterPurchase - categoryBudget.effectiveAmount).toStringAsFixed(2)}");
          } else if (budgetAfterPurchasePercent > 80) {
            riskFactors.add("⚠️ This purchase will use ${budgetAfterPurchasePercent.toStringAsFixed(0)}% of your $category budget - you're approaching the limit");
          }
        }
    
    return AnalysisData(
      recommendation: recommendation,
      recommendationIcon: recommendationIcon,
      recommendationColor: recommendationColor,
      currentBalance: currentBalance,
      balanceAfterPurchase: advice.immediateBalanceAfterPurchase,
      purchaseAmount: amount,
      dailyAverage: dailyAverage,
      projectedMonthly: projectedMonthly,
      afterPurchaseProjected: afterPurchaseProjected,
      categorySpending: categorySpending,
      categoryPercentage: categoryPercentage,
      averageCategorySpending: averageCategorySpending,
      projectedCategoryMonthly: projectedCategoryMonthly,
      riskFactors: riskFactors,
      hasBudget: false, // Simplified for new system
      budgetUsed: null,
      budgetAfterPurchase: null,
      budgetAmount: null,
    );
  }

  Widget _buildAnalysisResult(BuildContext context) {
    if (_analysisData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main recommendation card
        Card(
          color: _analysisData!.recommendationColor.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _analysisData!.recommendationIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _analysisData!.recommendation,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _analysisData!.recommendationColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getRecommendationSubtitle(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                // AI decision badge
                if (_aiDecision != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'AI Insight',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[700],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${_aiDecision!.confidence}%',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_aiDecision!.suggestion.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _aiDecision!.suggestion,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_aiDecision!.reasoning.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._aiDecision!.reasoning.map((reason) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          Expanded(
                            child: Text(
                              reason,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ] else if (_aiUnavailable && !_isLoadingAi) ...[
                  const SizedBox(height: 8),
                  Text(
                    'AI unavailable',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Financial metrics
        Row(
          children: [
            Expanded(
              child: _buildBalanceCard(
                'Current Balance',
                _analysisData!.currentBalance,
                Icons.account_balance_wallet,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBalanceCard(
                'After Purchase',
                _analysisData!.balanceAfterPurchase,
                Icons.shopping_cart,
                _analysisData!.balanceAfterPurchase < 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Spending analysis
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Spending Analysis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMetricCard(
                  'Daily Average',
                  '\$${_analysisData!.dailyAverage.toStringAsFixed(2)}',
                  Icons.trending_up,
                ),
                _buildMetricCard(
                  'Projected Monthly',
                  '\$${_analysisData!.projectedMonthly.toStringAsFixed(2)}',
                  Icons.calendar_month,
                ),
                _buildMetricCard(
                  'Category Spending',
                  '\$${_analysisData!.categorySpending.toStringAsFixed(2)}',
                  Icons.category,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Risk factors
        if (_analysisData!.riskFactors.isNotEmpty)
          Card(
            color: Colors.red.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ Important Considerations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._analysisData!.riskFactors.map((factor) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $factor',
                      style: const TextStyle(fontSize: 14),
                    ),
                  )),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _getRecommendationSubtitle() {
    if (_analysisData == null) return '';
    
    switch (_analysisData!.recommendation) {
      case 'GO FOR IT':
        return 'You\'re in a great financial position for this purchase.';
      case 'PROCEED WITH CAUTION':
        return 'You can afford it, but monitor your spending this month.';
      case 'THINK TWICE':
        return 'This purchase could strain your budget.';
      case 'NOT RECOMMENDED':
        return 'This purchase would significantly impact your finances.';
      default:
        return 'Analysis complete';
    }
  }

  Widget _buildBalanceCard(String title, double amount, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Purchase Details',
                        style: TextStyle(
                          fontSize: 18,
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
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
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
                      
                      // Recurring payment section
                      Card(
                        color: Colors.grey[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Type',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SwitchListTile(
                                title: const Text('Recurring Payment'),
                                subtitle: const Text('This is a subscription or recurring expense'),
                                value: _isRecurring,
                                onChanged: (value) {
                                  setState(() {
                                    _isRecurring = value;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                              if (_isRecurring) ...[
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _recurringFrequency,
                                  decoration: const InputDecoration(
                                    labelText: 'Frequency',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _recurringFrequencies.map((frequency) {
                                    return DropdownMenuItem(
                                      value: frequency,
                                      child: Text(frequency.toUpperCase()),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _recurringFrequency = value!;
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isAnalyzing ? null : _analyzePurchase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
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
                              : const Text('Analyze Purchase'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Analysis result
            if (_analysisResult != null) _buildAnalysisResult(context),
          ],
        ),
      ),
    );
  }
}

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