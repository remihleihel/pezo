import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import '../models/receipt_data.dart';

class DebugReceiptScreen extends StatefulWidget {
  const DebugReceiptScreen({super.key});

  @override
  State<DebugReceiptScreen> createState() => _DebugReceiptScreenState();
}

class _DebugReceiptScreenState extends State<DebugReceiptScreen> {
  String _extractedText = '';
  String _parsedData = '';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Receipt Scanner'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Receipt Image'),
            ),
            const SizedBox(height: 20),
            if (_isProcessing)
              const CircularProgressIndicator()
            else ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Extracted Text:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_extractedText.isEmpty ? 'No text extracted' : _extractedText),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Parsed Data:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_parsedData.isEmpty ? 'No data parsed' : _parsedData),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      setState(() {
        _isProcessing = true;
        _extractedText = '';
        _parsedData = '';
      });

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        // Extract text using ML Kit
        final textRecognizer = TextRecognizer();
        final inputImage = InputImage.fromFile(File(image.path));
        final recognizedText = await textRecognizer.processImage(inputImage);
        
        await textRecognizer.close();

        // Parse the extracted text
        final receiptData = ReceiptParser.parseReceiptText(recognizedText.text);

        setState(() {
          _extractedText = recognizedText.text;
          _parsedData = '''
Merchant: ${receiptData.merchantName ?? 'Not found'}
Amount: ${receiptData.totalAmount?.toString() ?? 'Not found'}
Date: ${receiptData.date?.toString() ?? 'Not found'}
Category: ${receiptData.suggestedCategory ?? 'Not found'}
Confidence: ${(receiptData.confidence * 100).toStringAsFixed(1)}%
Valid: ${receiptData.isValid}
Items: ${receiptData.items.join(', ')}
          ''';
          _isProcessing = false;
        });
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _extractedText = 'Error: $e';
        _parsedData = '';
        _isProcessing = false;
      });
    }
  }
}
