import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../models/transaction.dart';
import '../models/budget.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _includeIncome = true;
  bool _includeExpenses = true;
  String _selectedFormat = 'JSON';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeSelector(),
            const SizedBox(height: 20),
            _buildTransactionTypeSelector(),
            const SizedBox(height: 20),
            _buildFormatSelector(),
            const SizedBox(height: 20),
            _buildPreviewSection(),
            const SizedBox(height: 20),
            _buildExportButton(),
            const SizedBox(height: 20),
            _buildRestoreSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date Range',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('From'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: const Text('To'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Types',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Include Income'),
              subtitle: const Text('Salary, freelance, etc.'),
              value: _includeIncome,
              onChanged: (value) => setState(() => _includeIncome = value ?? true),
            ),
            CheckboxListTile(
              title: const Text('Include Expenses'),
              subtitle: const Text('Purchases, bills, etc.'),
              value: _includeExpenses,
              onChanged: (value) => setState(() => _includeExpenses = value ?? true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Format',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...['JSON', 'CSV', 'PDF'].map((format) {
              return RadioListTile<String>(
                title: Text(format),
                subtitle: Text(_getFormatDescription(format)),
                value: format,
                groupValue: _selectedFormat,
                onChanged: (value) => setState(() => _selectedFormat = value!),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final transactions = provider.getTransactionsByDateRange(_startDate, _endDate);
        final filteredTransactions = transactions.where((t) {
          if (t.type == TransactionType.income && !_includeIncome) return false;
          if (t.type == TransactionType.expense && !_includeExpenses) return false;
          return true;
        }).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildPreviewStat(
                        'Total Transactions',
                        filteredTransactions.length.toString(),
                        Icons.list,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPreviewStat(
                        'Total Amount',
                        '\$${filteredTransactions.fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                if (filteredTransactions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Sample Data:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getSampleData(filteredTransactions.first),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _exportData,
        icon: const Icon(Icons.download),
        label: const Text('Export Data'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildRestoreSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restore Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Import previously exported data to restore your transactions and budgets.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _restoreData,
                icon: const Icon(Icons.upload),
                label: const Text('Import Data File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFormatDescription(String format) {
    switch (format) {
      case 'JSON':
        return 'Machine-readable format for apps';
      case 'CSV':
        return 'Spreadsheet format for Excel';
      case 'PDF':
        return 'Printable report format';
      default:
        return '';
    }
  }

  String _getSampleData(Transaction transaction) {
    switch (_selectedFormat) {
      case 'JSON':
        return jsonEncode({
          'title': transaction.title,
          'amount': transaction.amount,
          'type': transaction.type.name,
          'category': transaction.category,
          'date': transaction.date.toIso8601String(),
        });
      case 'CSV':
        return 'Title,Amount,Type,Category,Date\n'
            '${transaction.title},${transaction.amount},${transaction.type.name},${transaction.category},${DateFormat('yyyy-MM-dd').format(transaction.date)}';
      case 'PDF':
        return 'Transaction Report\n'
            'Title: ${transaction.title}\n'
            'Amount: \$${transaction.amount}\n'
            'Type: ${transaction.type.name}\n'
            'Category: ${transaction.category}\n'
            'Date: ${DateFormat('MMM dd, yyyy').format(transaction.date)}';
      default:
        return '';
    }
  }

  void _exportData() async {
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final transactions = transactionProvider.transactions;
      
      // Filter transactions based on selected criteria
      List<Transaction> filteredTransactions = transactions.where((transaction) {
        if (transaction.date.isBefore(_startDate) || transaction.date.isAfter(_endDate)) {
          return false;
        }
        if (transaction.type == TransactionType.income && !_includeIncome) {
          return false;
        }
        if (transaction.type == TransactionType.expense && !_includeExpenses) {
          return false;
        }
        return true;
      }).toList();

      if (filteredTransactions.isEmpty) {
        _showErrorDialog('No transactions found for the selected criteria.');
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting data...'),
            ],
          ),
        ),
      );

      String filePath;
      String fileName;

      switch (_selectedFormat) {
        case 'JSON':
          filePath = await _exportToJSON(filteredTransactions);
          fileName = 'transactions_${DateFormat('yyyyMMdd').format(DateTime.now())}.json';
          break;
        case 'CSV':
          filePath = await _exportToCSV(filteredTransactions);
          fileName = 'transactions_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
          break;
        case 'PDF':
          filePath = await _exportToPDF(filteredTransactions);
          fileName = 'transactions_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
          break;
        default:
          throw Exception('Unsupported format: $_selectedFormat');
      }

      // Close loading dialog
      Navigator.pop(context);

      // Share the file
      await Share.shareXFiles([XFile(filePath)], text: 'Pezo Export');

      // Show success dialog
      _showSuccessDialog('Data exported successfully!\n\nFile: $fileName\n\nShared via system share dialog.');

    } catch (e) {
      // Close loading dialog if it's open
      Navigator.pop(context);
      _showErrorDialog('Failed to export data: $e');
    }
  }

  Future<String> _exportToJSON(List<Transaction> transactions) async {
    final data = {
      'export_date': DateTime.now().toIso8601String(),
      'date_range': {
        'start': _startDate.toIso8601String(),
        'end': _endDate.toIso8601String(),
      },
      'transaction_count': transactions.length,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    return await _saveToFile(jsonString, 'json');
  }

  Future<String> _exportToCSV(List<Transaction> transactions) async {
    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln('Date,Title,Amount,Type,Category,Description,Merchant,From Receipt');
    
    // CSV Data
    for (final transaction in transactions) {
      buffer.writeln([
        DateFormat('yyyy-MM-dd').format(transaction.date),
        '"${transaction.title.replaceAll('"', '""')}"',
        transaction.amount.toStringAsFixed(2),
        transaction.type.name,
        '"${transaction.category.replaceAll('"', '""')}"',
        '"${(transaction.description ?? '').replaceAll('"', '""')}"',
        '"${(transaction.merchantName ?? '').replaceAll('"', '""')}"',
        transaction.isFromReceipt ? 'Yes' : 'No',
      ].join(','));
    }

    return await _saveToFile(buffer.toString(), 'csv');
  }

  Future<String> _exportToPDF(List<Transaction> transactions) async {
    // For PDF, we'll create a simple text-based report
    final buffer = StringBuffer();
    
    buffer.writeln('PEZO - NEVER RUN OUT OF PESOS EXPORT REPORT');
    buffer.writeln('=' * 40);
    buffer.writeln('Export Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('Date Range: ${DateFormat('yyyy-MM-dd').format(_startDate)} to ${DateFormat('yyyy-MM-dd').format(_endDate)}');
    buffer.writeln('Total Transactions: ${transactions.length}');
    buffer.writeln('');
    
    // Summary
    final income = transactions.where((t) => t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount);
    final expenses = transactions.where((t) => t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount);
    
    buffer.writeln('SUMMARY:');
    buffer.writeln('Total Income: \$${income.toStringAsFixed(2)}');
    buffer.writeln('Total Expenses: \$${expenses.toStringAsFixed(2)}');
    buffer.writeln('Net Balance: \$${(income - expenses).toStringAsFixed(2)}');
    buffer.writeln('');
    
    // Transactions
    buffer.writeln('TRANSACTIONS:');
    buffer.writeln('-' * 40);
    
    for (final transaction in transactions) {
      buffer.writeln('${DateFormat('yyyy-MM-dd').format(transaction.date)} | ${transaction.title}');
      buffer.writeln('  ${transaction.type.name.toUpperCase()} | \$${transaction.amount.toStringAsFixed(2)} | ${transaction.category}');
      if (transaction.description != null && transaction.description!.isNotEmpty) {
        buffer.writeln('  Description: ${transaction.description}');
      }
      if (transaction.isFromReceipt) {
        buffer.writeln('  [From Receipt]');
      }
      buffer.writeln('');
    }

    return await _saveToFile(buffer.toString(), 'txt');
  }

  Future<String> _saveToFile(String content, String extension) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'spending_export_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(content);
    return file.path;
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Complete'),
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Error'),
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

  void _restoreData() async {
    try {
      // Show file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv', 'txt'],
        allowMultiple: false,
      );

      if (result == null) {
        return; // User cancelled
      }

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Restoring data...'),
            ],
          ),
        ),
      );

      // Read and parse the file
      final String content = await file.readAsString();
      final Map<String, dynamic>? data = await _parseRestoreFile(content, fileName);
      
      if (data == null) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Failed to parse the selected file. Please make sure it\'s a valid Pezo export file.');
        return;
      }

      // Restore the data
      await _importData(data);

      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog
      _showRestoreSuccessDialog(data);

    } catch (e) {
      // Close loading dialog if it's open
      Navigator.pop(context);
      _showErrorDialog('Failed to restore data: $e');
    }
  }

  Future<Map<String, dynamic>?> _parseRestoreFile(String content, String fileName) async {
    try {
      // Try to parse as JSON first
      if (fileName.toLowerCase().endsWith('.json')) {
        final Map<String, dynamic> data = jsonDecode(content);
        
        // Validate that it's a Pezo export file
        if (data.containsKey('export_date') && data.containsKey('transactions')) {
          return data;
        }
      }
      
      // Try to parse as CSV
      if (fileName.toLowerCase().endsWith('.csv')) {
        return await _parseCSVFile(content);
      }
      
      // Try to parse as text/PDF
      if (fileName.toLowerCase().endsWith('.txt')) {
        return await _parseTextFile(content);
      }
      
      return null;
    } catch (e) {
      print('Error parsing file: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _parseCSVFile(String content) async {
    try {
      final lines = content.split('\n');
      if (lines.length < 2) return null;
      
      final header = lines[0].split(',');
      final transactions = <Map<String, dynamic>>[];
      
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        
        final values = _parseCSVLine(lines[i]);
        if (values.length >= 5) {
          transactions.add({
            'title': values[1].replaceAll('"', ''),
            'amount': double.tryParse(values[2]) ?? 0.0,
            'type': values[3].toLowerCase() == 'income' ? 'income' : 'expense',
            'category': values[4].replaceAll('"', ''),
            'date': DateTime.tryParse(values[0])?.toIso8601String() ?? DateTime.now().toIso8601String(),
            'description': values.length > 5 ? values[5].replaceAll('"', '') : null,
            'merchant_name': values.length > 6 ? values[6].replaceAll('"', '') : null,
            'is_from_receipt': values.length > 7 ? values[7].toLowerCase() == 'yes' : false,
          });
        }
      }
      
      return {
        'export_date': DateTime.now().toIso8601String(),
        'transaction_count': transactions.length,
        'transactions': transactions,
      };
    } catch (e) {
      print('Error parsing CSV: $e');
      return null;
    }
  }

  List<String> _parseCSVLine(String line) {
    final List<String> result = [];
    bool inQuotes = false;
    String current = '';
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current);
        current = '';
      } else {
        current += char;
      }
    }
    
    result.add(current);
    return result;
  }

  Future<Map<String, dynamic>?> _parseTextFile(String content) async {
    try {
      // Parse the Pezo text export format
      final lines = content.split('\n');
      final transactions = <Map<String, dynamic>>[];
      
      String? currentDate;
      String? currentTitle;
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i]; // Don't trim here to preserve leading spaces
        final trimmedLine = line.trim();
        
        // Look for transaction header lines: "2025-01-01 | Transaction Name"
        if (trimmedLine.contains('|') && !line.startsWith('  ') && !trimmedLine.startsWith('SUMMARY:') && !trimmedLine.startsWith('TRANSACTIONS:') && !trimmedLine.startsWith('PEZO') && !trimmedLine.startsWith('=') && !trimmedLine.startsWith('-') && !trimmedLine.startsWith('Export Date:') && !trimmedLine.startsWith('Date Range:') && !trimmedLine.startsWith('Total Transactions:')) {
          final parts = trimmedLine.split('|');
          if (parts.length >= 2) {
            currentDate = parts[0].trim();
            currentTitle = parts[1].trim();
          }
        }
        // Look for transaction detail lines: "  EXPENSE | $10.00 | Category"
        else if (line.startsWith('  ') && trimmedLine.contains('|') && trimmedLine.contains('\$') && currentDate != null && currentTitle != null && (trimmedLine.startsWith('EXPENSE') || trimmedLine.startsWith('INCOME'))) {
          final parts = trimmedLine.split('|');
          if (parts.length >= 3) {
            final type = parts[0].trim().toLowerCase();
            final amountPart = parts[1].trim();
            final category = parts[2].trim();
            
            // Extract amount (look for $X.XX pattern)
            final amountMatch = RegExp(r'\$(\d+\.?\d*)').firstMatch(amountPart);
            final amount = amountMatch != null ? double.tryParse(amountMatch.group(1)!) ?? 0.0 : 0.0;
            
            if (amount > 0) {
              final transaction = {
                'title': currentTitle,
                'amount': amount,
                'type': type,
                'category': category,
                'date': DateTime.tryParse(currentDate)?.toIso8601String() ?? DateTime.now().toIso8601String(),
                'description': 'Imported from text file',
                'is_from_receipt': 0, // Use 0 for false, 1 for true (database format)
              };
              transactions.add(transaction);
            }
            
            // Reset for next transaction
            currentDate = null;
            currentTitle = null;
          }
        }
      }
      
      if (transactions.isNotEmpty) {
        return {
          'export_date': DateTime.now().toIso8601String(),
          'transaction_count': transactions.length,
          'transactions': transactions,
        };
      }
      
      return null;
    } catch (e) {
      print('Error parsing text file: $e');
      return null;
    }
  }

  Future<void> _importData(Map<String, dynamic> data) async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    
    // Import transactions
    if (data.containsKey('transactions')) {
      final List<dynamic> transactionsData = data['transactions'];
      
      for (final transactionData in transactionsData) {
        try {
          final transaction = Transaction.fromJson(transactionData);
          await transactionProvider.addTransaction(transaction);
        } catch (e) {
          print('Error importing transaction: $e');
        }
      }
    }
    
    // Import budgets if available
    if (data.containsKey('budgets')) {
      final List<dynamic> budgetsData = data['budgets'];
      
      for (final budgetData in budgetsData) {
        try {
          final budget = Budget.fromJson(budgetData);
          await budgetProvider.addBudget(budget);
        } catch (e) {
          print('Error importing budget: $e');
        }
      }
    }
    
    // Import spending goals if available
    if (data.containsKey('spending_goals')) {
      final List<dynamic> goalsData = data['spending_goals'];
      
      for (final goalData in goalsData) {
        try {
          final goal = SpendingGoal.fromJson(goalData);
          await budgetProvider.addSpendingGoal(goal);
        } catch (e) {
          print('Error importing spending goal: $e');
        }
      }
    }
  }

  void _showRestoreSuccessDialog(Map<String, dynamic> data) {
    final transactionCount = data['transaction_count'] ?? 0;
    final budgetCount = data['budgets']?.length ?? 0;
    final goalCount = data['spending_goals']?.length ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Data restored successfully!'),
            const SizedBox(height: 16),
            Text('• Transactions: $transactionCount'),
            if (budgetCount > 0) Text('• Budgets: $budgetCount'),
            if (goalCount > 0) Text('• Spending Goals: $goalCount'),
            const SizedBox(height: 16),
            const Text(
              'Your data has been imported into the current account. You can now view all your transactions and budgets in the app.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

