import 'dart:math' as math;
import 'receipt_data.dart';

class EnhancedReceiptParser {
  static ReceiptData parseText(String text) {
    print('EnhancedReceiptParser: Parsing text with ${text.length} characters');
    
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    print('EnhancedReceiptParser: Found ${lines.length} non-empty lines');
    
    // Clean and normalize text
    final cleanText = _cleanText(text);
    final cleanLines = cleanText.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    final merchantName = _extractMerchantName(cleanLines);
    final totalAmount = _extractTotalAmount(cleanLines);
    final date = _extractDate(cleanLines);
    final items = _extractItems(cleanLines);
    final suggestedCategory = _suggestCategory(merchantName, items);
    
    // Calculate confidence based on extracted data quality
    double confidence = _calculateConfidence(totalAmount, merchantName, date, items, cleanLines);
    
    print('EnhancedReceiptParser: Extracted - Merchant: $merchantName, Total: $totalAmount, Date: $date, Items: ${items.length}');
    
    return ReceiptData(
      extractedText: text,
      totalAmount: totalAmount,
      merchantName: merchantName,
      date: date,
      items: items,
      suggestedCategory: suggestedCategory,
      confidence: confidence,
    );
  }

  static String _cleanText(String text) {
    // Remove common OCR artifacts and improve text quality
    return text
        .replaceAll(RegExp(r'[^\w\s\.\$,:/-]'), ' ') // Keep only alphanumeric, spaces, and common symbols
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .replaceAll(RegExp(r'[|]'), 'I') // Common OCR mistake: | becomes I
        .replaceAll(RegExp(r'[0]'), 'O') // Common OCR mistake: 0 becomes O in text
        .replaceAll(RegExp(r'[1]'), 'I') // Common OCR mistake: 1 becomes I in text
        .replaceAll(RegExp(r'[5]'), 'S') // Common OCR mistake: 5 becomes S in text
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace again
        .trim();
  }

  static String? _extractMerchantName(List<String> lines) {
    if (lines.isEmpty) return null;

    // Strategy 1: Look for business names in first 5 lines (most common location)
    for (int i = 0; i < math.min(5, lines.length); i++) {
      final line = lines[i];
      
      // Skip obvious non-business lines
      if (_isNonBusinessLine(line)) continue;
      
      // Check if this looks like a business name
      if (_isBusinessName(line)) {
        print('EnhancedReceiptParser: Found merchant in line $i: $line');
        return _cleanBusinessName(line);
      }
    }

    // Strategy 2: Look for lines with business suffixes
    for (int i = 0; i < math.min(8, lines.length); i++) {
      final line = lines[i];
      if (line.contains(RegExp(r'\b(Inc|LLC|Corp|Ltd|Co|Company|Store|Shop|Market|Restaurant|Cafe|Bar|Pizza|Burger|McDonald|KFC|Subway|Starbucks|Walmart|Target|Amazon|CVS|Walgreens|Shell|Exxon|Chevron|BP|Mobil|Best Buy|Home Depot|Lowes)\b', caseSensitive: false))) {
        print('EnhancedReceiptParser: Found merchant with business suffix: $line');
        return _cleanBusinessName(line);
      }
    }

    // Strategy 3: Look for capitalized words that could be business names
    for (int i = 0; i < math.min(6, lines.length); i++) {
      final line = lines[i];
      if (line.length >= 3 && line.length <= 50 && 
          line.contains(RegExp(r'^[A-Z][a-z]+(\s+[A-Z][a-z]+)*$'))) {
        print('EnhancedReceiptParser: Found merchant with proper case: $line');
        return _cleanBusinessName(line);
      }
    }

    // Strategy 4: Look for lines that are mostly uppercase (common for business names)
    for (int i = 0; i < math.min(5, lines.length); i++) {
      final line = lines[i];
      if (line.length >= 3 && line.length <= 40 && 
          line.contains(RegExp(r'^[A-Z\s]+$')) &&
          !line.contains(RegExp(r'^\d+$')) && // Not just numbers
          !line.contains(RegExp(r'^\$?\d+\.?\d*$'))) { // Not just amounts
        print('EnhancedReceiptParser: Found merchant with uppercase: $line');
        return _cleanBusinessName(line);
      }
    }

    // Strategy 5: Look for common business name patterns
    for (int i = 0; i < math.min(5, lines.length); i++) {
      final line = lines[i];
      if (line.contains(RegExp(r'\b(^[A-Z][a-z]+\s+[A-Z][a-z]+$|^[A-Z][a-z]+\s+&\s+[A-Z][a-z]+$|^[A-Z][a-z]+\s+[A-Z][a-z]+\s+[A-Z][a-z]+$)\b'))) {
        print('EnhancedReceiptParser: Found merchant with name pattern: $line');
        return _cleanBusinessName(line);
      }
    }

    print('EnhancedReceiptParser: No merchant name found');
    return null;
  }

  static bool _isNonBusinessLine(String line) {
    if (line.length < 3) return true;
    
    // Skip lines that are clearly not business names
    return line.contains(RegExp(r'^\d+$')) || // Just numbers
           line.contains(RegExp(r'^\$?\d+\.?\d*$')) || // Just amounts
           line.toLowerCase().contains('receipt') ||
           line.toLowerCase().contains('total') ||
           line.toLowerCase().contains('subtotal') ||
           line.toLowerCase().contains('tax') ||
           line.toLowerCase().contains('change') ||
           line.toLowerCase().contains('date') ||
           line.toLowerCase().contains('time') ||
           line.toLowerCase().contains('cashier') ||
           line.toLowerCase().contains('register') ||
           line.toLowerCase().contains('thank') ||
           line.toLowerCase().contains('visit') ||
           line.contains(RegExp(r'^\d{1,2}:\d{2}')) || // Time
           line.contains(RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}')) || // Date
           (line.contains(RegExp(r'^[A-Z\s]+$')) && line.length > 20) || // All caps long lines
           line.contains(RegExp(r'^\d+\s+[A-Z]')) || // Number followed by letter (often addresses)
           line.contains(RegExp(r'^[A-Z]\d+[A-Z]?\s')) || // Postal codes
           line.contains(RegExp(r'^\d{3}-\d{3}-\d{4}')) || // Phone numbers
           line.contains(RegExp(r'@')) || // Email addresses
           line.contains(RegExp(r'www\.')) || // URLs
           line.contains(RegExp(r'http')) || // URLs
           line.length > 50; // Too long to be a business name
  }

  static bool _isBusinessName(String line) {
    return line.length >= 3 && 
           line.length <= 50 && 
           !_isNonBusinessLine(line) &&
           (line.contains(RegExp(r'[A-Za-z]')) && // Contains letters
            !line.contains(RegExp(r'^\d+\.?\d*$')) && // Not just numbers
            !line.contains(RegExp(r'^\d{1,2}:\d{2}')) && // Not time
            !line.contains(RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}'))); // Not date
  }

  static String _cleanBusinessName(String name) {
    return name
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters except spaces
        .trim();
  }

  static double? _extractTotalAmount(List<String> lines) {
    print('EnhancedReceiptParser: Extracting total amount from ${lines.length} lines');
    
    // Strategy 1: Look for "Total:" patterns first (most reliable)
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Enhanced regex to catch more total patterns
      final totalMatch = RegExp(r'(?i)(total|amount|due|balance|grand\s+total|final\s+total|sum|pay|charge)[:\s]*\$?(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)').firstMatch(line);
      if (totalMatch != null) {
        final amountStr = totalMatch.group(2)?.replaceAll(',', '') ?? '';
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0 && amount < 100000) {
          print('EnhancedReceiptParser: Found total with keyword: $amount from "$line"');
          return amount;
        }
      }
    }

    // Strategy 2: Look for currency patterns with better regex
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Look for $X.XX patterns, including with commas
      final currencyMatch = RegExp(r'\$(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)').firstMatch(line);
      if (currencyMatch != null) {
        final amountStr = currencyMatch.group(1)?.replaceAll(',', '') ?? '';
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0 && amount < 100000) {
          print('EnhancedReceiptParser: Found total with currency symbol: $amount from "$line"');
          return amount;
        }
      }
    }

    // Strategy 3: Look for decimal numbers that could be totals (enhanced)
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Look for X.XX patterns (exactly 2 decimal places)
      final decimalMatch = RegExp(r'(\d{1,3}(?:,\d{3})*\.\d{2})').firstMatch(line);
      if (decimalMatch != null) {
        final amountStr = decimalMatch.group(1)?.replaceAll(',', '') ?? '';
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0 && amount < 100000) {
          print('EnhancedReceiptParser: Found total with decimal: $amount from "$line"');
          return amount;
        }
      }
    }

    // Strategy 4: Look for the largest amount in the last few lines (common pattern)
    final lastLines = lines.length > 5 ? lines.sublist(lines.length - 5) : lines;
    double? largestAmount;
    
    for (final line in lastLines) {
      // Find all amounts in this line
      final amounts = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)').allMatches(line);
      for (final match in amounts) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0 && amount < 100000) {
          if (largestAmount == null || amount > largestAmount) {
            largestAmount = amount;
          }
        }
      }
    }
    
    if (largestAmount != null) {
      print('EnhancedReceiptParser: Found largest amount in last lines: $largestAmount');
      return largestAmount;
    }

    // Strategy 5: Look for amounts with "TOTAL" or similar keywords anywhere in the line
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.toLowerCase().contains(RegExp(r'\b(total|amount|due|balance|sum|pay|charge)\b'))) {
        final amounts = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)').allMatches(line);
        for (final match in amounts) {
          final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
          final amount = double.tryParse(amountStr);
          if (amount != null && amount > 0 && amount < 100000) {
            print('EnhancedReceiptParser: Found amount near total keyword: $amount from "$line"');
            return amount;
          }
        }
      }
    }

    print('EnhancedReceiptParser: No total amount found');
    return null;
  }

  static DateTime? _extractDate(List<String> lines) {
    // Look for date patterns in various formats
    for (final line in lines) {
      // MM/DD/YYYY or MM-DD-YYYY
      final dateMatch1 = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})').firstMatch(line);
      if (dateMatch1 != null) {
        final month = int.tryParse(dateMatch1.group(1) ?? '');
        final day = int.tryParse(dateMatch1.group(2) ?? '');
        final year = int.tryParse(dateMatch1.group(3) ?? '');
        if (month != null && day != null && year != null && 
            month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          try {
            final date = DateTime(year, month, day);
            print('EnhancedReceiptParser: Found date MM/DD/YYYY: $date from "$line"');
            return date;
          } catch (e) {
            continue;
          }
        }
      }

      // MM/DD/YY or MM-DD-YY
      final dateMatch2 = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2})').firstMatch(line);
      if (dateMatch2 != null) {
        final month = int.tryParse(dateMatch2.group(1) ?? '');
        final day = int.tryParse(dateMatch2.group(2) ?? '');
        final year = int.tryParse(dateMatch2.group(3) ?? '');
        if (month != null && day != null && year != null && 
            month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          try {
            final fullYear = year < 50 ? 2000 + year : 1900 + year;
            final date = DateTime(fullYear, month, day);
            print('EnhancedReceiptParser: Found date MM/DD/YY: $date from "$line"');
            return date;
          } catch (e) {
            continue;
          }
        }
      }

      // Month name format (e.g., "Jan 15, 2024" or "January 15, 2024")
      final dateMatch3 = RegExp(r'(?i)(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2}),?\s+(\d{4})').firstMatch(line);
      if (dateMatch3 != null) {
        final monthName = dateMatch3.group(1)?.toLowerCase();
        final day = int.tryParse(dateMatch3.group(2) ?? '');
        final year = int.tryParse(dateMatch3.group(3) ?? '');
        if (day != null && year != null) {
          final month = _getMonthNumber(monthName);
          if (month != null) {
            try {
              final date = DateTime(year, month, day);
              print('EnhancedReceiptParser: Found date with month name: $date from "$line"');
              return date;
            } catch (e) {
              continue;
            }
          }
        }
      }
    }

    print('EnhancedReceiptParser: No date found');
    return null;
  }

  static int? _getMonthNumber(String? monthName) {
    if (monthName == null) return null;
    
    const monthMap = {
      'jan': 1, 'january': 1,
      'feb': 2, 'february': 2,
      'mar': 3, 'march': 3,
      'apr': 4, 'april': 4,
      'may': 5,
      'jun': 6, 'june': 6,
      'jul': 7, 'july': 7,
      'aug': 8, 'august': 8,
      'sep': 9, 'september': 9,
      'oct': 10, 'october': 10,
      'nov': 11, 'november': 11,
      'dec': 12, 'december': 12,
    };
    
    return monthMap[monthName.toLowerCase()];
  }

  static List<String> _extractItems(List<String> lines) {
    final items = <String>[];
    
    for (final line in lines) {
      // Skip lines that are clearly not items
      if (_isNonBusinessLine(line) || 
          line.contains(RegExp(r'^\$?\d+\.?\d*$')) || // Just amounts
          line.toLowerCase().contains('total') ||
          line.toLowerCase().contains('subtotal') ||
          line.toLowerCase().contains('tax') ||
          line.toLowerCase().contains('change') ||
          line.toLowerCase().contains('receipt') ||
          line.toLowerCase().contains('thank') ||
          line.toLowerCase().contains('visit') ||
          line.toLowerCase().contains('cashier') ||
          line.toLowerCase().contains('register') ||
          line.length < 3) {
        continue;
      }
      
      // Look for lines that could be items (contain letters and possibly numbers/amounts)
      if (line.contains(RegExp(r'[A-Za-z]')) && 
          line.length >= 3 && 
          line.length <= 100) {
        // Clean up the item name more intelligently
        final cleanItem = _cleanItemName(line);
        
        if (cleanItem.length >= 3 && !_isCommonReceiptWord(cleanItem)) {
          items.add(cleanItem);
        }
      }
    }
    
    print('EnhancedReceiptParser: Found ${items.length} items');
    return items;
  }

  static String _cleanItemName(String line) {
    return line
        .replaceAll(RegExp(r'\$\d{1,3}(?:,\d{3})*(?:\.\d{2})?'), '') // Remove currency amounts
        .replaceAll(RegExp(r'\d{1,3}(?:,\d{3})*(?:\.\d{2})?'), '') // Remove decimal numbers
        .replaceAll(RegExp(r'\d+'), '') // Remove remaining numbers
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
  }

  static bool _isCommonReceiptWord(String word) {
    final commonWords = {
      'receipt', 'total', 'subtotal', 'tax', 'change', 'thank', 'visit', 'cashier',
      'register', 'date', 'time', 'amount', 'due', 'balance', 'sum', 'pay', 'charge',
      'inc', 'llc', 'corp', 'ltd', 'co', 'company', 'store', 'shop', 'market'
    };
    return commonWords.contains(word.toLowerCase());
  }

  static String? _suggestCategory(String? merchantName, List<String> items) {
    if (merchantName == null && items.isEmpty) return null;
    
    final text = '${merchantName ?? ''} ${items.join(' ')}'.toLowerCase();
    
    // Food & Dining
    if (text.contains(RegExp(r'\b(restaurant|cafe|coffee|pizza|burger|food|dining|eat|meal|kitchen|grill|bar|pub|fast food|mcdonald|kfc|subway|starbucks|dunkin|domino|pizza hut)\b'))) {
      return 'Food & Dining';
    }
    
    // Groceries
    if (text.contains(RegExp(r'\b(grocery|supermarket|market|walmart|target|costco|safeway|kroger|whole foods|trader joe|grocery store|food store)\b'))) {
      return 'Groceries';
    }
    
    // Transportation
    if (text.contains(RegExp(r'\b(gas|fuel|gasoline|petrol|station|shell|exxon|chevron|bp|mobil|uber|lyft|taxi|bus|train|metro|parking|toll)\b'))) {
      return 'Transportation';
    }
    
    // Shopping
    if (text.contains(RegExp(r'\b(store|shop|mall|retail|amazon|ebay|clothing|fashion|apparel|shoes|electronics|best buy|home depot|lowes)\b'))) {
      return 'Shopping';
    }
    
    // Entertainment
    if (text.contains(RegExp(r'\b(movie|cinema|theater|netflix|spotify|music|game|entertainment|fun|leisure|sports|gym|fitness)\b'))) {
      return 'Entertainment';
    }
    
    // Healthcare
    if (text.contains(RegExp(r'\b(pharmacy|drug|medicine|medical|doctor|hospital|clinic|health|wellness|cvs|walgreens)\b'))) {
      return 'Healthcare';
    }
    
    // Utilities
    if (text.contains(RegExp(r'\b(electric|water|gas|internet|phone|cable|utility|bill|payment)\b'))) {
      return 'Utilities';
    }
    
    return 'Other';
  }

  static double _calculateConfidence(double? totalAmount, String? merchantName, DateTime? date, List<String> items, List<String> lines) {
    double confidence = 0.0;
    
    // Total amount confidence (40% weight)
    if (totalAmount != null) {
      confidence += 0.4;
      // Bonus for reasonable amounts
      if (totalAmount > 0.01 && totalAmount < 10000) {
        confidence += 0.1;
      }
    }
    
    // Merchant name confidence (30% weight)
    if (merchantName != null && merchantName.isNotEmpty) {
      confidence += 0.3;
      // Bonus for longer, more specific names
      if (merchantName.length > 5) {
        confidence += 0.1;
      }
    }
    
    // Date confidence (20% weight)
    if (date != null) {
      confidence += 0.2;
      // Bonus for recent dates
      final now = DateTime.now();
      final daysDiff = now.difference(date).inDays;
      if (daysDiff >= 0 && daysDiff <= 30) {
        confidence += 0.1;
      }
    }
    
    // Items confidence (10% weight)
    if (items.isNotEmpty) {
      confidence += 0.1;
      // Bonus for more items
      if (items.length > 2) {
        confidence += 0.05;
      }
    }
    
    // Text quality bonus
    if (lines.length > 5) {
      confidence += 0.05;
    }
    
    return math.min(confidence, 1.0); // Cap at 1.0
  }
}



