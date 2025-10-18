import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class MonthlySpendingChart extends StatelessWidget {
  final List<Transaction> transactions;
  final String period;

  const MonthlySpendingChart({
    super.key,
    required this.transactions,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final spendingData = _prepareSpendingData();

    if (spendingData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No spending data available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Trend - $period',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('');
                          return Text(
                            '\$${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < spendingData.length) {
                            return Text(
                              spendingData[value.toInt()].label,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spendingData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.amount);
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SpendingDataPoint> _prepareSpendingData() {
    final Map<String, double> spendingData = {};

    // Group transactions based on period
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        String key;
        switch (period) {
          case 'This Week':
            key = DateFormat('E').format(transaction.date); // Day of week
            break;
          case 'This Month':
          case 'Last Month':
            key = DateFormat('MMM dd').format(transaction.date); // Day of month
            break;
          case 'This Year':
          case 'Last Year':
            key = DateFormat('MMM').format(transaction.date); // Month
            break;
          default:
            key = DateFormat('MMM dd').format(transaction.date); // Default to day
        }
        spendingData[key] = (spendingData[key] ?? 0.0) + transaction.amount;
      }
    }

    // Fill in missing periods with zero values
    final filledData = _fillMissingPeriods(spendingData);

    // Convert to list and sort by date
    final sortedEntries = filledData.entries.toList()
      ..sort((a, b) {
        return _compareKeys(a.key, b.key, period);
      });

    return sortedEntries.map((entry) {
      return SpendingDataPoint(entry.key, entry.value);
    }).toList();
  }

  Map<String, double> _fillMissingPeriods(Map<String, double> data) {
    final Map<String, double> filledData = Map.from(data);
    
    switch (period) {
      case 'This Week':
        final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        for (final day in weekDays) {
          filledData.putIfAbsent(day, () => 0.0);
        }
        break;
      case 'This Year':
      case 'Last Year':
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        for (final month in months) {
          filledData.putIfAbsent(month, () => 0.0);
        }
        break;
      // For daily data (This Month, Last Month), we don't fill missing days
      // as it would create too many data points
    }
    
    return filledData;
  }

  int _compareKeys(String a, String b, String period) {
    switch (period) {
      case 'This Week':
        // Sort by day of week
        final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final aIndex = weekDays.indexOf(a);
        final bIndex = weekDays.indexOf(b);
        return aIndex.compareTo(bIndex);
      case 'This Month':
      case 'Last Month':
        // Sort by actual date for proper chronological order
        return _compareDateStrings(a, b);
      case 'This Year':
      case 'Last Year':
        // Sort by month
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final aIndex = months.indexOf(a);
        final bIndex = months.indexOf(b);
        return aIndex.compareTo(bIndex);
      default:
        // Default sort by actual date
        return _compareDateStrings(a, b);
    }
  }

  int _compareDateStrings(String a, String b) {
    // Parse date strings like "Jan 15" to actual dates for proper sorting
    try {
      final now = DateTime.now();
      final aDate = _parseDateString(a, now);
      final bDate = _parseDateString(b, now);
      return aDate.compareTo(bDate);
    } catch (e) {
      // Fallback to simple day comparison if parsing fails
      final aDay = int.tryParse(a.split(' ').last) ?? 0;
      final bDay = int.tryParse(b.split(' ').last) ?? 0;
      return aDay.compareTo(bDay);
    }
  }

  DateTime _parseDateString(String dateStr, DateTime referenceDate) {
    final parts = dateStr.split(' ');
    if (parts.length != 2) return referenceDate;
    
    final monthStr = parts[0];
    final dayStr = parts[1];
    
    final months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
    };
    
    final month = months[monthStr] ?? referenceDate.month;
    final day = int.tryParse(dayStr) ?? referenceDate.day;
    
    // Use current year for "This Month", previous year for "Last Month"
    final year = referenceDate.year;
    
    return DateTime(year, month, day);
  }
}

class SpendingDataPoint {
  final String label;
  final double amount;

  SpendingDataPoint(this.label, this.amount);
}


