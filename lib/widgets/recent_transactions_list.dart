import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../screens/edit_transaction_screen.dart';

class RecentTransactionsList extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback? onViewAllTransactions;

  const RecentTransactionsList({
    super.key,
    required this.transactions,
    this.onViewAllTransactions,
  });

  @override
  Widget build(BuildContext context) {
    print('RecentTransactionsList: Building with ${transactions.length} transactions');
    
    if (transactions.isEmpty) {
      print('RecentTransactionsList: No transactions, showing empty state');
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No transactions yet',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    print('RecentTransactionsList: Building transaction list');

    return Card(
      child: Column(
        children: [
          ...transactions.take(5).map((transaction) => 
            _buildTransactionTile(context, transaction)
          ).toList(),
          if (transactions.length > 5)
            ListTile(
              title: const Text(
                'View all transactions',
                style: TextStyle(color: Colors.blue),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: onViewAllTransactions,
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, Transaction transaction) {
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome ? (Theme.of(context).brightness == Brightness.dark ? Colors.orange : Colors.green) : Colors.red;
    final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: amountColor.withOpacity(0.1),
        child: Icon(icon, color: amountColor, size: 20),
      ),
      title: Text(
        transaction.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${transaction.category} • ${DateFormat('MMM dd').format(transaction.date)}',
        style: TextStyle(color: Colors.grey[600]),
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
            ),
          ),
          if (transaction.isFromReceipt)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Receipt',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      onTap: () => _showTransactionDetails(context, transaction),
    );
  }

  void _showTransactionDetails(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(transaction.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Amount', '\$${transaction.amount.toStringAsFixed(2)}'),
            _buildDetailRow('Category', transaction.category),
            _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(transaction.date)),
            if (transaction.description != null)
              _buildDetailRow('Description', transaction.description!),
            if (transaction.merchantName != null)
              _buildDetailRow('Merchant', transaction.merchantName!),
            if (transaction.isFromReceipt)
              _buildDetailRow('Source', 'Receipt Scan'),
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
              _editTransaction(context, transaction);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTransaction(context, transaction);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editTransaction(BuildContext context, Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(transaction: transaction),
      ),
    );
  }

  void _deleteTransaction(BuildContext context, Transaction transaction) {
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

