import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';

class SavingsGoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SavingsGoalCard({
    super.key,
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercentage = goal.progressPercentage;
    final isOverdue = goal.isOverdue;
    final daysRemaining = goal.targetDate != null
        ? goal.targetDate!.difference(DateTime.now()).inDays
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getGoalColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    goal.isAchieved ? Icons.check_circle : Icons.savings,
                    color: _getGoalColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor().withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getPriorityText(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getPriorityColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (goal.targetDate != null)
                        Text(
                          isOverdue
                              ? 'Overdue by ${(-daysRemaining!).toString()} days'
                              : '${daysRemaining} days remaining',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue
                                ? Colors.red
                                : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      NumberFormat.currency(symbol: '\$').format(goal.currentAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      NumberFormat.currency(symbol: '\$').format(goal.targetAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progressPercentage > 100 ? 1.0 : progressPercentage / 100,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_getGoalColor()),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progressPercentage.toStringAsFixed(1)}% complete',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
                Text(
                  goal.isAchieved
                      ? 'Goal Achieved! 🎉'
                      : '\$${(goal.targetAmount - goal.currentAmount).toStringAsFixed(2)} to go',
                  style: TextStyle(
                    fontSize: 12,
                    color: goal.isAchieved ? (Theme.of(context).brightness == Brightness.dark ? Colors.orange : Colors.green) : _getGoalColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (goal.isAchieved)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (Theme.of(context).brightness == Brightness.dark ? Colors.orange : Colors.green).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.celebration, color: Theme.of(context).brightness == Brightness.dark ? Colors.orange : Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Congratulations! You achieved your savings goal!',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getGoalColor() {
    if (goal.isAchieved) {
      return Colors.green;
    } else if (goal.isOverdue) {
      return Colors.red;
    } else if (goal.progressPercentage >= 80) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  Color _getPriorityColor() {
    switch (goal.priority) {
      case 1:
        return Colors.red; // High priority
      case 2:
        return Colors.orange; // Medium priority
      case 3:
        return Colors.blue; // Low priority
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText() {
    switch (goal.priority) {
      case 1:
        return 'HIGH';
      case 2:
        return 'MED';
      case 3:
        return 'LOW';
      default:
        return 'N/A';
    }
  }
}
