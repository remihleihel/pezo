// import 'package:json_annotation/json_annotation.dart';

// part 'transaction.g.dart';

// @JsonSerializable()
class Transaction {
  final int? id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? description;
  final String? receiptImagePath;
  final bool isFromReceipt;
  final String? merchantName;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.description,
    this.receiptImagePath,
    this.isFromReceipt = false,
    this.merchantName,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int?,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
      receiptImagePath: json['receipt_image_path'] as String?,
      isFromReceipt: (json['is_from_receipt'] as int? ?? 0) == 1,
      merchantName: json['merchant_name'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'date': date.toIso8601String(),
      'description': description,
      'receipt_image_path': receiptImagePath,
      'is_from_receipt': isFromReceipt ? 1 : 0,
      'merchant_name': merchantName,
    };
  }

  Transaction copyWith({
    int? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? description,
    String? receiptImagePath,
    bool? isFromReceipt,
    String? merchantName,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      isFromReceipt: isFromReceipt ?? this.isFromReceipt,
      merchantName: merchantName ?? this.merchantName,
    );
  }
}

enum TransactionType {
  income,
  expense,
}

class TransactionCategory {
  static const List<String> expenseCategories = [
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

  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Refund',
    'Other',
  ];

  static List<String> getCategoriesForType(TransactionType type) {
    return type == TransactionType.income ? incomeCategories : expenseCategories;
  }

  static String getCategoryIcon(String category) {
    switch (category) {
      case 'Food & Dining':
        return '🍽️';
      case 'Transportation':
        return '🚗';
      case 'Shopping':
        return '🛍️';
      case 'Entertainment':
        return '🎬';
      case 'Bills & Utilities':
        return '💡';
      case 'Healthcare':
        return '🏥';
      case 'Education':
        return '📚';
      case 'Travel':
        return '✈️';
      case 'Groceries':
        return '🛒';
      case 'Gas':
        return '⛽';
      case 'Salary':
        return '💰';
      case 'Freelance':
        return '💼';
      case 'Investment':
        return '📈';
      case 'Gift':
        return '🎁';
      case 'Refund':
        return '↩️';
      default:
        return '📝';
    }
  }
}
