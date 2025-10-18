// import 'package:json_annotation/json_annotation.dart';
import 'dart:math' as math;

// part 'receipt_data.g.dart';

// @JsonSerializable()
class ReceiptData {
  final String extractedText;
  final double? totalAmount;
  final String? merchantName;
  final DateTime? date;
  final List<String> items;
  final String? suggestedCategory;
  final double confidence;

  ReceiptData({
    required this.extractedText,
    this.totalAmount,
    this.merchantName,
    this.date,
    this.items = const [],
    this.suggestedCategory,
    this.confidence = 0.0,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      extractedText: json['extractedText'] as String,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      merchantName: json['merchantName'] as String?,
      date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
      items: (json['items'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      suggestedCategory: json['suggestedCategory'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'extractedText': extractedText,
      'totalAmount': totalAmount,
      'merchantName': merchantName,
      'date': date?.toIso8601String(),
      'items': items,
      'suggestedCategory': suggestedCategory,
      'confidence': confidence,
    };
  }

  bool get isValid => totalAmount != null && totalAmount! > 0 && totalAmount! < 10000;
}

class ReceiptParser {
  static ReceiptData parseReceiptText(String text) {
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    double? totalAmount;
    String? merchantName;
    DateTime? date;
    List<String> items = [];
    String? suggestedCategory;
    double confidence = 0.0;

    // Clean and normalize text
    final cleanText = text.replaceAll(RegExp(r'[^\w\s\.\,\$\-\/]'), ' ').replaceAll(RegExp(r'\s+'), ' ');
    final cleanLines = cleanText.split(' ').where((word) => word.isNotEmpty).toList();

    // Extract merchant name (usually first few lines, look for business-like names)
    merchantName = _extractMerchantName(lines);
    if (merchantName != null) confidence += 0.3;

    // Extract total amount with multiple strategies
    totalAmount = _extractTotalAmount(lines, cleanText);
    if (totalAmount != null) confidence += 0.5;

    // Extract date with multiple formats
    date = _extractDate(lines, cleanText);
    if (date != null) confidence += 0.2;

    // Extract items
    items = _extractItems(lines);
    if (items.isNotEmpty) confidence += 0.1;

    // Suggest category
    suggestedCategory = _suggestCategory(merchantName, items);
    if (suggestedCategory != null) confidence += 0.1;

    return ReceiptData(
      extractedText: text,
      totalAmount: totalAmount,
      merchantName: merchantName,
      date: date,
      items: items,
      suggestedCategory: suggestedCategory,
      confidence: confidence.clamp(0.0, 1.0),
    );
  }

  static String? _extractMerchantName(List<String> lines) {
    if (lines.isEmpty) return null;

    // Look for business-like names in first few lines
    for (int i = 0; i < math.min(5, lines.length); i++) {
      final line = lines[i].trim();
      
      // Skip lines that are clearly not business names
      if (line.length < 3 || 
          line.contains(RegExp(r'^\d+$')) || // Just numbers
          line.contains(RegExp(r'^\$?\d+\.?\d*$')) || // Just amounts
          line.toLowerCase().contains('receipt') ||
          line.toLowerCase().contains('total') ||
          line.toLowerCase().contains('date') ||
          line.toLowerCase().contains('time') ||
          line.toLowerCase().contains('cashier') ||
          line.toLowerCase().contains('register') ||
          line.contains(RegExp(r'^\d{1,2}:\d{2}')) || // Time
          line.contains(RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}')) || // Date
          line.contains(RegExp(r'^[A-Z\s]+$')) && line.length > 20) { // All caps long lines (often addresses)
        continue;
      }

      // Check if line looks like a business name (title)
      if (line.length >= 3 && line.length <= 50 && 
          !line.contains(RegExp(r'^\d+\.?\d*$')) &&
          !line.contains(RegExp(r'^\d{1,2}:\d{2}')) && // Not time
          !line.contains(RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}')) && // Not date
          !line.toLowerCase().contains('subtotal') &&
          !line.toLowerCase().contains('tax') &&
          !line.toLowerCase().contains('change') &&
          !line.toLowerCase().contains('amount')) {
        return line;
      }
    }

    // Fallback: return first non-empty line if it looks reasonable
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.length >= 3 && trimmed.length <= 50 && 
          !trimmed.contains(RegExp(r'^\d+\.?\d*$')) &&
          !trimmed.toLowerCase().contains('total')) {
        return trimmed;
      }
    }

    return null;
  }

  static double? _extractTotalAmount(List<String> lines, String cleanText) {
    // Strategy 1: Look for explicit "Total:" patterns (most important)
    final totalPatterns = [
      RegExp(r'total\s*:?\s*\$?(\d+\.?\d{2})', caseSensitive: false),
      RegExp(r'total\s*:?\s*(\d+\.?\d{2})', caseSensitive: false),
      RegExp(r'\$(\d+\.?\d{2})\s*total', caseSensitive: false),
      RegExp(r'amount\s*:?\s*\$?(\d+\.?\d{2})', caseSensitive: false),
      RegExp(r'due\s*:?\s*\$?(\d+\.?\d{2})', caseSensitive: false),
      RegExp(r'balance\s*:?\s*\$?(\d+\.?\d{2})', caseSensitive: false),
    ];

    for (final pattern in totalPatterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        final amount = double.tryParse(match.group(1) ?? '');
        if (amount != null && amount > 0 && amount < 10000) {
          return amount;
        }
      }
    }

    // Strategy 2: Look for "Total:" in individual lines (more precise)
    for (final line in lines) {
      final lineLower = line.toLowerCase();
      if (lineLower.contains('total') && lineLower.contains(':')) {
        // Look for amount after "total:"
        final totalMatch = RegExp(r'total\s*:?\s*\$?(\d+\.?\d{2})', caseSensitive: false).firstMatch(line);
        if (totalMatch != null) {
          final amount = double.tryParse(totalMatch.group(1) ?? '');
          if (amount != null && amount > 0 && amount < 10000) {
            return amount;
          }
        }
      }
    }

    // Strategy 3: Look for currency amounts in the last few lines (fallback)
    final currencyPattern = RegExp(r'\$(\d+\.?\d{2})');
    final amounts = <double>[];
    
    // Check last 3 lines for amounts (more focused)
    final lastLines = lines.length > 3 ? lines.sublist(lines.length - 3) : lines;
    for (final line in lastLines) {
      final matches = currencyPattern.allMatches(line);
      for (final match in matches) {
        final amount = double.tryParse(match.group(1) ?? '');
        if (amount != null && amount > 0 && amount < 10000) {
          amounts.add(amount);
        }
      }
    }

    if (amounts.isNotEmpty) {
      amounts.sort();
      return amounts.last; // Return the largest amount
    }

    // Strategy 4: Look for decimal numbers in the last few lines (final fallback)
    final decimalPattern = RegExp(r'(\d+\.\d{2})');
    final decimalAmounts = <double>[];
    
    for (final line in lastLines) {
      final matches = decimalPattern.allMatches(line);
      for (final match in matches) {
        final amount = double.tryParse(match.group(1) ?? '');
        if (amount != null && amount > 0 && amount < 10000) {
          decimalAmounts.add(amount);
        }
      }
    }

    if (decimalAmounts.isNotEmpty) {
      decimalAmounts.sort();
      return decimalAmounts.last;
    }

    return null;
  }

  static DateTime? _extractDate(List<String> lines, String cleanText) {
    // Multiple date patterns
    final datePatterns = [
      RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})'), // MM/DD/YYYY or MM-DD-YYYY
      RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{4})'),   // MM/DD/YYYY
      RegExp(r'(\d{4}[/-]\d{1,2}[/-]\d{1,2})'),   // YYYY/MM/DD
      RegExp(r'(\d{1,2}\s+\w+\s+\d{4})'),         // DD Month YYYY
      RegExp(r'(\w+\s+\d{1,2},?\s+\d{4})'),       // Month DD, YYYY
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        final dateStr = match.group(1)!;
        final parsedDate = _parseDate(dateStr);
        if (parsedDate != null) {
          return parsedDate;
        }
      }
    }

    return null;
  }

  static DateTime? _parseDate(String dateStr) {
    try {
      // Handle MM/DD/YYYY or MM-DD-YYYY
      if (dateStr.contains('/') || dateStr.contains('-')) {
        final parts = dateStr.split(RegExp(r'[/-]'));
        if (parts.length == 3) {
          final month = int.parse(parts[0]);
          final day = int.parse(parts[1]);
          final year = int.parse(parts[2]) + (parts[2].length == 2 ? 2000 : 0);
          
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            return DateTime(year, month, day);
          }
        }
      }
      
      // Handle YYYY/MM/DD or YYYY-MM-DD
      if (dateStr.contains('/') || dateStr.contains('-')) {
        final parts = dateStr.split(RegExp(r'[/-]'));
        if (parts.length == 3 && parts[0].length == 4) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            return DateTime(year, month, day);
          }
        }
      }
    } catch (e) {
      // Continue if parsing fails
    }
    
    return null;
  }

  static List<String> _extractItems(List<String> lines) {
    final items = <String>[];
    
    for (final line in lines) {
      // Skip lines that are clearly not items
      if (line.length < 3 || 
          line.contains(RegExp(r'^\$?\d+\.?\d*$')) || // Just numbers/amounts
          line.toLowerCase().contains('total') ||
          line.toLowerCase().contains('subtotal') ||
          line.toLowerCase().contains('tax') ||
          line.toLowerCase().contains('receipt') ||
          line.toLowerCase().contains('date') ||
          line.toLowerCase().contains('time') ||
          line.contains(RegExp(r'^\d{1,2}:\d{2}')) || // Time
          line.contains(RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}')) || // Date
          line.length > 50) { // Too long to be an item
        continue;
      }
      
      // Check if line looks like an item description
      if (line.length >= 3 && line.length <= 50) {
        items.add(line);
      }
    }
    
    return items;
  }

  static String? _suggestCategory(String? merchantName, List<String> items) {
    if (merchantName == null && items.isEmpty) return null;

    final merchantLower = merchantName?.toLowerCase() ?? '';
    final itemsText = items.join(' ').toLowerCase();
    final combinedText = '$merchantLower $itemsText';

    // Food & Dining
    if (combinedText.contains('restaurant') || 
        combinedText.contains('cafe') || 
        combinedText.contains('pizza') ||
        combinedText.contains('burger') ||
        combinedText.contains('food') ||
        combinedText.contains('meal') ||
        combinedText.contains('dining') ||
        combinedText.contains('kitchen') ||
        combinedText.contains('grill') ||
        combinedText.contains('bar') ||
        combinedText.contains('pub')) {
      return 'Food & Dining';
    }

    // Groceries
    if (combinedText.contains('grocery') || 
        combinedText.contains('supermarket') ||
        combinedText.contains('market') ||
        combinedText.contains('fresh') ||
        combinedText.contains('organic') ||
        combinedText.contains('produce')) {
      return 'Groceries';
    }

    // Gas
    if (combinedText.contains('gas') || 
        combinedText.contains('fuel') ||
        combinedText.contains('station') ||
        combinedText.contains('shell') ||
        combinedText.contains('exxon') ||
        combinedText.contains('bp') ||
        combinedText.contains('chevron')) {
      return 'Gas';
    }

    // Shopping
    if (combinedText.contains('store') || 
        combinedText.contains('shop') ||
        combinedText.contains('retail') ||
        combinedText.contains('mall') ||
        combinedText.contains('amazon') ||
        combinedText.contains('walmart') ||
        combinedText.contains('target')) {
      return 'Shopping';
    }

    // Transportation
    if (combinedText.contains('uber') || 
        combinedText.contains('lyft') ||
        combinedText.contains('taxi') ||
        combinedText.contains('transport') ||
        combinedText.contains('bus') ||
        combinedText.contains('train') ||
        combinedText.contains('metro')) {
      return 'Transportation';
    }

    // Entertainment
    if (combinedText.contains('movie') || 
        combinedText.contains('cinema') ||
        combinedText.contains('theater') ||
        combinedText.contains('game') ||
        combinedText.contains('entertainment') ||
        combinedText.contains('netflix') ||
        combinedText.contains('spotify')) {
      return 'Entertainment';
    }

    // Health
    if (combinedText.contains('pharmacy') || 
        combinedText.contains('drug') ||
        combinedText.contains('medical') ||
        combinedText.contains('health') ||
        combinedText.contains('clinic') ||
        combinedText.contains('hospital')) {
      return 'Health';
    }

    return 'Other';
  }
}
