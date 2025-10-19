// import 'package:json_annotation/json_annotation.dart';

// part 'budget.g.dart';

// @JsonSerializable()
class Budget {
  final int? id;
  final String category;
  final double amount;
  final String month;
  final int year;
  final bool carryoverEnabled;
  final double? carriedOverAmount;

  Budget({
    this.id,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
    this.carryoverEnabled = false,
    this.carriedOverAmount,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as int?,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      month: json['month'] as String,
      year: json['year'] as int,
      carryoverEnabled: (json['carryover_enabled'] as int? ?? 0) == 1,
      carriedOverAmount: json['carried_over_amount'] != null 
          ? (json['carried_over_amount'] as num).toDouble() 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'month': month,
      'year': year,
      'carryover_enabled': carryoverEnabled ? 1 : 0,
      'carried_over_amount': carriedOverAmount,
    };
  }

  Budget copyWith({
    int? id,
    String? category,
    double? amount,
    String? month,
    int? year,
    bool? carryoverEnabled,
    double? carriedOverAmount,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      carryoverEnabled: carryoverEnabled ?? this.carryoverEnabled,
      carriedOverAmount: carriedOverAmount ?? this.carriedOverAmount,
    );
  }

  // Helper method to get effective budget amount (base + carryover)
  double get effectiveAmount {
    return amount + (carriedOverAmount ?? 0.0);
  }
}

// @JsonSerializable()
class SpendingGoal {
  final int? id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final bool isAchieved;
  final DateTime createdDate;

  SpendingGoal({
    this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    this.isAchieved = false,
    required this.createdDate,
  });

  factory SpendingGoal.fromJson(Map<String, dynamic> json) {
    return SpendingGoal(
      id: json['id'] as int?,
      title: json['title'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
      targetDate: json['target_date'] == null ? null : DateTime.parse(json['target_date'] as String),
      isAchieved: (json['is_achieved'] as int? ?? 0) == 1,
      createdDate: DateTime.parse(json['created_date'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate?.toIso8601String(),
      'is_achieved': isAchieved ? 1 : 0,
      'created_date': createdDate.toIso8601String(),
    };
  }

  double get progressPercentage => targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0.0;
  
  bool get isOverdue => targetDate != null && 
      DateTime.now().isAfter(targetDate!) && 
      !isAchieved;

  SpendingGoal copyWith({
    int? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    bool? isAchieved,
    DateTime? createdDate,
  }) {
    return SpendingGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      isAchieved: isAchieved ?? this.isAchieved,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}

// Savings Goals - for tracking savings progress automatically
class SavingsGoal {
  final int? id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final bool isAchieved;
  final DateTime createdDate;
  final int priority; // 1 = highest priority, 2 = medium, 3 = low

  SavingsGoal({
    this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    this.isAchieved = false,
    required this.createdDate,
    this.priority = 1,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as int?,
      title: json['title'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
      targetDate: json['target_date'] == null ? null : DateTime.parse(json['target_date'] as String),
      isAchieved: (json['is_achieved'] as int? ?? 0) == 1,
      createdDate: DateTime.parse(json['created_date'] as String),
      priority: json['priority'] as int? ?? 1,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate?.toIso8601String(),
      'is_achieved': isAchieved ? 1 : 0,
      'created_date': createdDate.toIso8601String(),
      'priority': priority,
    };
  }

  double get progressPercentage => targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0.0;
  
  bool get isOverdue => targetDate != null && 
      DateTime.now().isAfter(targetDate!) && 
      !isAchieved;

  SavingsGoal copyWith({
    int? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    bool? isAchieved,
    DateTime? createdDate,
    int? priority,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      isAchieved: isAchieved ?? this.isAchieved,
      createdDate: createdDate ?? this.createdDate,
      priority: priority ?? this.priority,
    );
  }
}
