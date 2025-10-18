import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final bool? isIncome;

  const AddTransactionScreen({super.key, this.isIncome});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = '';
  DateTime _selectedDate = DateTime.now();
  bool _isIncome = false;

  @override
  void initState() {
    super.initState();
    _isIncome = widget.isIncome ?? false;
    _selectedCategory = _isIncome 
        ? TransactionCategory.incomeCategories.first
        : TransactionCategory.expenseCategories.first;
  }

  @override
  Widget build(BuildContext context) {
    print('AddTransactionScreen: Building screen');
    return Scaffold(
      appBar: AppBar(
        title: Text(_isIncome ? 'Add Income' : 'Add Expense'),
        actions: [
          TextButton(
            onPressed: () {
              print('AddTransactionScreen: Save button in app bar pressed');
              _saveTransaction();
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTransactionTypeToggle(),
              const SizedBox(height: 24),
              _buildFormFields(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTypeToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    'Income',
                    Icons.arrow_upward,
                    Colors.green,
                    _isIncome,
                    () => setState(() {
                      _isIncome = true;
                      _selectedCategory = TransactionCategory.incomeCategories.first;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                    'Expense',
                    Icons.arrow_downward,
                    Colors.red,
                    !_isIncome,
                    () => setState(() {
                      _isIncome = false;
                      _selectedCategory = TransactionCategory.expenseCategories.first;
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    String label,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Title',
            hintText: _isIncome ? 'e.g., Salary, Freelance' : 'e.g., Groceries, Gas',
            prefixIcon: const Icon(Icons.title),
          ),
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
            labelText: 'Amount',
            hintText: '0.00',
            prefixIcon: Icon(Icons.attach_money),
            prefixText: '\$ ',
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
            prefixIcon: Icon(Icons.category),
          ),
          items: (_isIncome 
              ? TransactionCategory.incomeCategories 
              : TransactionCategory.expenseCategories)
              .map((category) => DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Text(TransactionCategory.getCategoryIcon(category)),
                        const SizedBox(width: 8),
                        Text(category),
                      ],
                    ),
                  ))
              .toList(),
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
            hintText: 'Additional notes...',
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Date'),
          subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
          leading: const Icon(Icons.calendar_today),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() {
                _selectedDate = date;
              });
            }
          },
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              print('AddTransactionScreen: Save button at bottom pressed');
              _saveTransaction();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isIncome ? Colors.green : Colors.red,
            ),
            child: Text(
              'Save ${_isIncome ? 'Income' : 'Expense'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _saveTransaction() async {
    print('AddTransactionScreen: Save button pressed');
    print('AddTransactionScreen: Title: "${_titleController.text}"');
    print('AddTransactionScreen: Amount: "${_amountController.text}"');
    print('AddTransactionScreen: Category: "$_selectedCategory"');
    print('AddTransactionScreen: Description: "${_descriptionController.text}"');
    
    if (_formKey.currentState!.validate()) {
      print('AddTransactionScreen: Form validation passed');
      try {
        final transaction = Transaction(
          title: _titleController.text,
          amount: double.parse(_amountController.text),
          type: _isIncome ? TransactionType.income : TransactionType.expense,
          category: _selectedCategory,
          date: _selectedDate,
          description: _descriptionController.text.isEmpty 
              ? null 
              : _descriptionController.text,
        );

        print('AddTransactionScreen: Created transaction: ${transaction.title} - \$${transaction.amount}');
        print('AddTransactionScreen: Transaction type: ${transaction.type}');
        print('AddTransactionScreen: Transaction category: ${transaction.category}');
        print('AddTransactionScreen: Transaction date: ${transaction.date}');
        
        final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
        print('AddTransactionScreen: Got TransactionProvider, calling addTransaction...');
        await transactionProvider.addTransaction(transaction);
        print('AddTransactionScreen: Transaction saved successfully');

        if (mounted) {
          print('AddTransactionScreen: Navigating back and showing success message');
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_isIncome ? 'Income' : 'Expense'} added successfully!'),
              backgroundColor: _isIncome ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        print('AddTransactionScreen: Error saving transaction: $e');
        print('AddTransactionScreen: Error stack trace: ${e.toString()}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving transaction: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      print('AddTransactionScreen: Form validation failed');
      print('AddTransactionScreen: Form state: ${_formKey.currentState}');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

