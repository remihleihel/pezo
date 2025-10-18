import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

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
      await Share.shareXFiles([XFile(filePath)], text: 'WIS Export');

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
    
    buffer.writeln('WIS - WHAT I SPENT EXPORT REPORT');
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
}

