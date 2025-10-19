import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/budget_card.dart';
import '../widgets/spending_goal_card.dart';
import '../widgets/savings_goal_card.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';
  DateTime _customStartDate = DateTime.now();
  DateTime _customEndDate = DateTime.now();

  final List<String> _periods = [
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
    _tabController = TabController(length: 3, vsync: this);
    _updateDateRange();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget & Goals'),
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
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Budgets'),
            Tab(text: 'Savings Goals'),
            Tab(text: 'Spending Goals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MonthlyBudgetsTab(
            startDate: _customStartDate,
            endDate: _customEndDate,
            period: _selectedPeriod,
          ),
          const SavingsGoalsTab(),
          const SpendingGoalsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog() {
    if (_tabController.index == 0) {
      _showAddMonthlyBudgetDialog();
    } else if (_tabController.index == 1) {
      _showAddSavingsGoalDialog();
    } else {
      _showAddSpendingGoalDialog();
    }
  }

  void _showAddMonthlyBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => AddMonthlyBudgetDialog(
        onBudgetAdded: () {
          // Refresh budgets after adding
          Provider.of<BudgetProvider>(context, listen: false).loadBudgets();
          // Switch to This Month to show the newly created budget
          setState(() {
            _selectedPeriod = 'This Month';
            _updateDateRange();
          });
        },
      ),
    );
  }

  void _showAddSavingsGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AddSavingsGoalDialog(
        onGoalAdded: () {
          // Refresh goals after adding
          Provider.of<BudgetProvider>(context, listen: false).loadSavingsGoals();
        },
      ),
    );
  }

  void _showAddSpendingGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AddSpendingGoalDialog(
        onGoalAdded: () {
          // Refresh goals after adding
          Provider.of<BudgetProvider>(context, listen: false).loadSpendingGoals();
        },
      ),
    );
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
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

class MonthlyBudgetsTab extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String period;

  const MonthlyBudgetsTab({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<BudgetProvider, TransactionProvider>(
      builder: (context, budgetProvider, transactionProvider, child) {
        // Get budgets for the selected period
        final budgets = budgetProvider.getBudgetsForDateRange(startDate, endDate);

        if (budgets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No budgets set for $period',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap + to add a budget',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text(
                  'Viewing: ${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: budgets.length,
          itemBuilder: (context, index) {
            final budget = budgets[index];
            final spent = transactionProvider.getTransactionsByCategory(budget.category)
                .where((t) => t.type == TransactionType.expense)
                .fold(0.0, (sum, t) => sum + t.amount);
            
            return BudgetCard(
              budget: budget,
              spent: spent,
              onEdit: () => _editBudget(context, budget),
              onDelete: () => _deleteBudget(context, budget),
            );
          },
        );
      },
    );
  }

  void _editBudget(BuildContext context, Budget budget) {
    showDialog(
      context: context,
      builder: (context) => EditBudgetDialog(budget: budget),
    );
  }

  void _deleteBudget(BuildContext context, Budget budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<BudgetProvider>(context, listen: false)
                  .deleteBudget(budget.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Budget deleted successfully!')),
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

class SpendingGoalsTab extends StatelessWidget {
  const SpendingGoalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        // Get spending goals from database
        final goals = budgetProvider.spendingGoals;

        if (goals.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flag, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No spending goals set',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap + to add a goal',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: goals.length,
          itemBuilder: (context, index) {
            final goal = goals[index];
            return SpendingGoalCard(
              goal: goal,
              onEdit: () => _editGoal(context, goal),
              onDelete: () => _deleteGoal(context, goal),
            );
          },
        );
      },
    );
  }

  void _editGoal(BuildContext context, SpendingGoal goal) {
    showDialog(
      context: context,
      builder: (context) => EditSpendingGoalDialog(goal: goal),
    );
  }

  void _deleteGoal(BuildContext context, SpendingGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<BudgetProvider>(context, listen: false)
                  .deleteSpendingGoal(goal.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Goal deleted successfully!')),
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

class SavingsGoalsTab extends StatelessWidget {
  const SavingsGoalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        // Get savings goals from database
        final goals = budgetProvider.savingsGoals;

        if (goals.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.savings, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No savings goals set',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap + to add a savings goal',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: goals.length,
          itemBuilder: (context, index) {
            final goal = goals[index];
            return SavingsGoalCard(
              goal: goal,
              onEdit: () => _editSavingsGoal(context, goal),
              onDelete: () => _deleteSavingsGoal(context, goal),
            );
          },
        );
      },
    );
  }

  void _editSavingsGoal(BuildContext context, SavingsGoal goal) {
    showDialog(
      context: context,
      builder: (context) => EditSavingsGoalDialog(goal: goal),
    );
  }

  void _deleteSavingsGoal(BuildContext context, SavingsGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Savings Goal'),
        content: const Text('Are you sure you want to delete this savings goal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<BudgetProvider>(context, listen: false)
                  .deleteSavingsGoal(goal.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Savings goal deleted successfully!')),
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

class AddMonthlyBudgetDialog extends StatefulWidget {
  final VoidCallback? onBudgetAdded;
  
  const AddMonthlyBudgetDialog({super.key, this.onBudgetAdded});

  @override
  State<AddMonthlyBudgetDialog> createState() => _AddMonthlyBudgetDialogState();
}

class _AddMonthlyBudgetDialogState extends State<AddMonthlyBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food & Dining';
  bool _carryoverEnabled = false;
  
  final List<String> _categories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Healthcare',
    'Utilities',
    'Groceries',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Monthly Budget'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveBudget,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveBudget() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final currentMonth = DateFormat('MMMM').format(DateTime.now());
      final currentYear = DateTime.now().year;
      
      final budget = Budget(
        category: _selectedCategory,
        amount: amount,
        month: currentMonth,
        year: currentYear,
        carryoverEnabled: _carryoverEnabled,
      );
      
      Provider.of<BudgetProvider>(context, listen: false).addBudget(budget);
      
      Navigator.pop(context);
      widget.onBudgetAdded?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget added successfully!')),
      );
    }
  }
}

class AddSpendingGoalDialog extends StatefulWidget {
  final VoidCallback? onGoalAdded;
  
  const AddSpendingGoalDialog({super.key, this.onGoalAdded});

  @override
  State<AddSpendingGoalDialog> createState() => _AddSpendingGoalDialogState();
}

class _AddSpendingGoalDialogState extends State<AddSpendingGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _targetDate;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Spending Goal'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Goal Title'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Target Amount',
                prefixText: '\$',
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
            ListTile(
              title: Text(_targetDate == null 
                  ? 'Select Target Date (Optional)'
                  : 'Target Date: ${DateFormat('MMM dd, yyyy').format(_targetDate!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _targetDate = date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveGoal,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text;
      final amount = double.parse(_amountController.text);
      
      final goal = SpendingGoal(
        title: title,
        targetAmount: amount,
        targetDate: _targetDate,
        createdDate: DateTime.now(),
      );
      
      Provider.of<BudgetProvider>(context, listen: false).addSpendingGoal(goal);
      
      Navigator.pop(context);
      widget.onGoalAdded?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Spending goal added successfully!')),
      );
    }
  }
}

class EditBudgetDialog extends StatefulWidget {
  final Budget budget;

  const EditBudgetDialog({super.key, required this.budget});

  @override
  State<EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends State<EditBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _selectedCategory = '';

  final List<String> _categories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Healthcare',
    'Utilities',
    'Groceries',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.budget.category;
    _amountController.text = widget.budget.amount.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Budget'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveBudget,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveBudget() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      
      final updatedBudget = widget.budget.copyWith(
        category: _selectedCategory,
        amount: amount,
      );
      
      Provider.of<BudgetProvider>(context, listen: false).updateBudget(updatedBudget);
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget updated successfully!')),
      );
    }
  }
}

class EditSpendingGoalDialog extends StatefulWidget {
  final SpendingGoal goal;

  const EditSpendingGoalDialog({super.key, required this.goal});

  @override
  State<EditSpendingGoalDialog> createState() => _EditSpendingGoalDialogState();
}

class _EditSpendingGoalDialogState extends State<EditSpendingGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.goal.title;
    _amountController.text = widget.goal.targetAmount.toString();
    _targetDate = widget.goal.targetDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Spending Goal'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Goal Title'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Target Amount',
                prefixText: '\$',
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
            ListTile(
              title: Text(_targetDate == null 
                  ? 'Select Target Date (Optional)'
                  : 'Target Date: ${DateFormat('MMM dd, yyyy').format(_targetDate!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _targetDate = date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveGoal,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text;
      final amount = double.parse(_amountController.text);
      
      final updatedGoal = widget.goal.copyWith(
        title: title,
        targetAmount: amount,
        targetDate: _targetDate,
      );
      
      Provider.of<BudgetProvider>(context, listen: false).updateSpendingGoal(updatedGoal);
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal updated successfully!')),
      );
    }
  }
}

class AddSavingsGoalDialog extends StatefulWidget {
  final VoidCallback? onGoalAdded;
  
  const AddSavingsGoalDialog({super.key, this.onGoalAdded});

  @override
  State<AddSavingsGoalDialog> createState() => _AddSavingsGoalDialogState();
}

class _AddSavingsGoalDialogState extends State<AddSavingsGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _targetDate;
  int _priority = 1;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Savings Goal'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Goal Title'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Target Amount',
                prefixText: '\$',
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
            DropdownButtonFormField<int>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('High Priority')),
                DropdownMenuItem(value: 2, child: Text('Medium Priority')),
                DropdownMenuItem(value: 3, child: Text('Low Priority')),
              ],
              onChanged: (value) {
                setState(() {
                  _priority = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_targetDate == null 
                  ? 'Select Target Date (Optional)'
                  : 'Target Date: ${DateFormat('MMM dd, yyyy').format(_targetDate!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _targetDate = date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveGoal,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text;
      final amount = double.parse(_amountController.text);
      
      final goal = SavingsGoal(
        title: title,
        targetAmount: amount,
        targetDate: _targetDate,
        createdDate: DateTime.now(),
        priority: _priority,
      );
      
      Provider.of<BudgetProvider>(context, listen: false).addSavingsGoal(goal);
      widget.onGoalAdded?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Savings goal added successfully!')),
      );
    }
  }
}

class EditSavingsGoalDialog extends StatefulWidget {
  final SavingsGoal goal;
  
  const EditSavingsGoalDialog({super.key, required this.goal});

  @override
  State<EditSavingsGoalDialog> createState() => _EditSavingsGoalDialogState();
}

class _EditSavingsGoalDialogState extends State<EditSavingsGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late DateTime? _targetDate;
  late int _priority;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal.title);
    _amountController = TextEditingController(text: widget.goal.targetAmount.toString());
    _targetDate = widget.goal.targetDate;
    _priority = widget.goal.priority;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Savings Goal'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Goal Title'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Target Amount',
                prefixText: '\$',
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
            DropdownButtonFormField<int>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('High Priority')),
                DropdownMenuItem(value: 2, child: Text('Medium Priority')),
                DropdownMenuItem(value: 3, child: Text('Low Priority')),
              ],
              onChanged: (value) {
                setState(() {
                  _priority = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_targetDate == null 
                  ? 'Select Target Date (Optional)'
                  : 'Target Date: ${DateFormat('MMM dd, yyyy').format(_targetDate!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _targetDate = date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveGoal,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text;
      final amount = double.parse(_amountController.text);
      
      final updatedGoal = widget.goal.copyWith(
        title: title,
        targetAmount: amount,
        targetDate: _targetDate,
        priority: _priority,
      );
      
      Provider.of<BudgetProvider>(context, listen: false).updateSavingsGoal(updatedGoal);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Savings goal updated successfully!')),
      );
    }
  }
}