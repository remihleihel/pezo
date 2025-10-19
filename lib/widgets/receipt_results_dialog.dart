import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/receipt_data.dart';
import '../models/transaction.dart';

class ReceiptResultsDialog extends StatefulWidget {
  final ReceiptData receiptData;
  final String imagePath;
  final Function(Transaction) onSave;

  const ReceiptResultsDialog({
    super.key,
    required this.receiptData,
    required this.imagePath,
    required this.onSave,
  });

  @override
  State<ReceiptResultsDialog> createState() => _ReceiptResultsDialogState();
}

class _ReceiptResultsDialogState extends State<ReceiptResultsDialog> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late TextEditingController _dateController;
  late DateTime _selectedDate;

  final List<String> _categories = [
    'Food & Dining',
    'Groceries',
    'Gas',
    'Shopping',
    'Transportation',
    'Entertainment',
    'Health',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.receiptData.merchantName ?? 'Receipt');
    _amountController = TextEditingController(text: widget.receiptData.totalAmount?.toString() ?? '');
    _categoryController = TextEditingController(text: widget.receiptData.suggestedCategory ?? 'Other');
    _selectedDate = widget.receiptData.date ?? DateTime.now();
    _dateController = TextEditingController(text: _formatDate(_selectedDate));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  void _saveTransaction() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showErrorDialog('Please enter a valid amount');
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a title');
      return;
    }

    final transaction = Transaction(
      title: _titleController.text.trim(),
      amount: amount,
      type: TransactionType.expense,
      category: _categoryController.text.trim(),
      date: _selectedDate,
      description: 'Scanned from receipt',
      receiptImagePath: widget.imagePath,
      isFromReceipt: true,
      merchantName: widget.receiptData.merchantName,
    );

    widget.onSave(transaction);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Receipt Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Confidence indicator
                    if (widget.receiptData.confidence > 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.receiptData.confidence > 0.7 
                              ? Colors.green.withOpacity(0.1)
                              : widget.receiptData.confidence > 0.4
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.receiptData.confidence > 0.7 
                                ? Colors.green
                                : widget.receiptData.confidence > 0.4
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.receiptData.confidence > 0.7 
                                  ? Icons.check_circle
                                  : widget.receiptData.confidence > 0.4
                                      ? Icons.warning
                                      : Icons.error,
                              color: widget.receiptData.confidence > 0.7 
                                  ? Colors.green
                                  : widget.receiptData.confidence > 0.4
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Confidence: ${(widget.receiptData.confidence * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: widget.receiptData.confidence > 0.7 
                                    ? Colors.green
                                    : widget.receiptData.confidence > 0.4
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Title field
                    const Text('Title', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Enter transaction title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount field
                    const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category field
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _categoryController.text,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _categoryController.text = value;
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date field
                    const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 16),

                    // Extracted items (if any)
                    if (widget.receiptData.items.isNotEmpty) ...[
                      const Text('Extracted Items', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.receiptData.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('• $item'),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Raw extracted text (collapsible)
                    ExpansionTile(
                      title: const Text('Raw Extracted Text', style: TextStyle(fontWeight: FontWeight.w600)),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.receiptData.extractedText,
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Transaction'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}




