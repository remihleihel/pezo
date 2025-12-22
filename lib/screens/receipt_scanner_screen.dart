import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../models/receipt_data.dart';
import '../models/enhanced_receipt_parser.dart';
import '../models/transaction.dart';
import '../providers/database_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/receipt_results_dialog.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              const Icon(
                Icons.receipt_long,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                'Scan Your Receipt',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Take a photo or select from gallery to automatically extract receipt information',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              
              // Camera Button
              _buildActionButton(
                icon: Icons.camera_alt,
                title: 'Take Photo',
                subtitle: 'Use camera to capture receipt',
                onTap: _takePhoto,
                color: Colors.white,
                textColor: Colors.blue,
              ),
              
              const SizedBox(height: 20),
              
              // Gallery Button
              _buildActionButton(
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                subtitle: 'Select existing photo',
                onTap: _pickFromGallery,
                color: Colors.white.withOpacity(0.9),
                textColor: Colors.blue,
              ),
              
              const SizedBox(height: 40),
              
              // Processing indicator
              if (_isProcessing)
                const Column(
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing receipt...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isProcessing ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: textColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: textColor.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> _pickFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      // Let image_picker handle permissions natively - it will show the system permission dialog
      // when needed. We should NOT check or request permissions manually before this call.
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        await _processImage(File(image.path));
      }
      // If image is null, user likely cancelled - don't show any error
      // image_picker will handle showing permission dialog automatically when needed
    } catch (e) {
      // Handle permission errors gracefully
      if (source == ImageSource.camera && e.toString().contains('permission')) {
        final cameraStatus = await Permission.camera.status;
        if (cameraStatus.isPermanentlyDenied) {
          _showPermissionDeniedDialog();
        } else {
          _showErrorDialog('Camera permission is required to take photos. Please grant permission when prompted.');
        }
      } else {
        _showErrorDialog('Failed to ${source == ImageSource.camera ? 'take photo' : 'pick image'}: $e');
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      // Extract text using ML Kit
      final textRecognizer = TextRecognizer();
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await textRecognizer.processImage(inputImage);
      
      await textRecognizer.close();

      // Clean and preprocess the extracted text
      final cleanedText = _cleanExtractedText(recognizedText.text);
      print('Original text: ${recognizedText.text}'); // Debug log
      print('Cleaned text: $cleanedText'); // Debug log

      // Parse the extracted text
      final receiptData = EnhancedReceiptParser.parseText(cleanedText);

      // Show results dialog
      if (receiptData.isValid) {
        _showReceiptResultsDialog(receiptData, imageFile.path);
      } else {
        // Show detailed extraction results for debugging
        _showDetailedErrorDialog(receiptData, recognizedText.text, cleanedText);
      }
    } catch (e) {
      _showErrorDialog('Failed to process receipt: $e');
    }
  }

  String _cleanExtractedText(String text) {
    // Remove common OCR artifacts and clean up the text
    String cleaned = text;
    
    // Replace common OCR mistakes
    cleaned = cleaned.replaceAll('O', '0'); // Replace O with 0 in numbers
    cleaned = cleaned.replaceAll('l', '1'); // Replace l with 1 in numbers
    cleaned = cleaned.replaceAll('I', '1'); // Replace I with 1 in numbers
    cleaned = cleaned.replaceAll('S', '5'); // Replace S with 5 in numbers
    cleaned = cleaned.replaceAll('B', '8'); // Replace B with 8 in numbers
    cleaned = cleaned.replaceAll('G', '6'); // Replace G with 6 in numbers
    
    // Fix common currency symbol issues
    cleaned = cleaned.replaceAll('§', '\$');
    cleaned = cleaned.replaceAll('s', '\$');
    
    // Remove extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove lines that are too short or too long
    final lines = cleaned.split('\n');
    final filteredLines = lines.where((line) {
      final trimmed = line.trim();
      return trimmed.length >= 2 && trimmed.length <= 100;
    }).toList();
    
    return filteredLines.join('\n');
  }

  void _showReceiptResultsDialog(ReceiptData receiptData, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => ReceiptResultsDialog(
        receiptData: receiptData,
        imagePath: imagePath,
        onSave: (transaction) => _saveTransaction(transaction),
      ),
    );
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

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Camera access is required to scan receipts. Please enable camera permission in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showDetailedErrorDialog(ReceiptData receiptData, String originalText, String cleanedText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receipt Processing Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Extraction Results:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Merchant: ${receiptData.merchantName ?? "Not found"}'),
              Text('Total Amount: ${receiptData.totalAmount?.toStringAsFixed(2) ?? "Not found"}'),
              Text('Date: ${receiptData.date?.toLocal().toString().split(' ')[0] ?? "Not found"}'),
              Text('Category: ${receiptData.suggestedCategory ?? "Not found"}'),
              Text('Confidence: ${(receiptData.confidence * 100).toStringAsFixed(1)}%'),
              Text('Items found: ${receiptData.items.length}'),
              const SizedBox(height: 16),
              const Text('Original Text:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  originalText.isEmpty ? 'No text extracted' : originalText,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Cleaned Text:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  cleanedText.isEmpty ? 'No text after cleaning' : cleanedText,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'The receipt could not be automatically processed. You can still save it manually.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Show manual entry dialog
              _showManualEntryDialog(receiptData);
            },
            child: const Text('Enter Manually'),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog(ReceiptData receiptData) {
    final amountController = TextEditingController(text: receiptData.totalAmount?.toStringAsFixed(2) ?? '');
    final merchantController = TextEditingController(text: receiptData.merchantName ?? '');
    final categoryController = TextEditingController(text: receiptData.suggestedCategory ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Receipt Details Manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                final transaction = Transaction(
                  title: merchantController.text.isNotEmpty ? merchantController.text : 'Receipt',
                  amount: amount,
                  type: TransactionType.expense,
                  category: categoryController.text.isNotEmpty ? categoryController.text : 'Other',
                  date: DateTime.now(),
                  description: 'Manual entry from receipt',
                );
                _saveTransaction(transaction);
              } else {
                _showErrorDialog('Please enter a valid amount');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTransaction(Transaction transaction) async {
    try {
      print('Attempting to save transaction: ${transaction.title} - \$${transaction.amount}');
      
      // Use TransactionProvider to save and update UI state
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.addTransaction(transaction);
      
      print('Transaction saved successfully');
      
      Navigator.pop(context); // Close results dialog
      Navigator.pop(context); // Close scanner screen
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving transaction: $e');
      _showErrorDialog('Failed to save transaction: $e');
    }
  }
}