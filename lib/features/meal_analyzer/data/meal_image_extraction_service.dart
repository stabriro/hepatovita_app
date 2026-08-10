import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class MealImageExtractionService {
  final ImagePicker _picker;
  final BarcodeScanner _barcodeScanner;
  final TextRecognizer _textRecognizer;

  MealImageExtractionService({
    ImagePicker? picker,
    BarcodeScanner? barcodeScanner,
    TextRecognizer? textRecognizer,
  })  : _picker = picker ?? ImagePicker(),
        _barcodeScanner = barcodeScanner ?? BarcodeScanner(),
        _textRecognizer = textRecognizer ?? TextRecognizer();

  Future<String?> extractBarcode({
    required ImageSource source,
  }) async {
    final image = await _pickImage(source: source);
    if (image == null) {
      return null;
    }

    final inputImage = InputImage.fromFilePath(image.path);
    final barcodes = await _safeCall<List<Barcode>>(
      () => _barcodeScanner.processImage(inputImage),
    );
    if (barcodes == null) {
      return null;
    }

    for (final barcode in barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  Future<String?> extractText({
    required ImageSource source,
  }) async {
    final image = await _pickImage(source: source);
    if (image == null) {
      return null;
    }

    final inputImage = InputImage.fromFilePath(image.path);
    final recognizedText = await _safeCall<RecognizedText>(
      () => _textRecognizer.processImage(inputImage),
    );
    if (recognizedText == null) {
      return null;
    }

    final merged = recognizedText.text.trim();
    if (merged.isEmpty) {
      return null;
    }
    return merged;
  }

  String pickBestMealQuery(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    for (final line in lines) {
      if (line.length >= 3 && line.length <= 80) {
        return line;
      }
    }

    if (text.length <= 80) {
      return text;
    }
    return text.substring(0, 80).trim();
  }

  Future<XFile?> _pickImage({
    required ImageSource source,
  }) {
    return _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1800,
    );
  }

  Future<void> dispose() async {
    await _safeCall<void>(() => _barcodeScanner.close());
    await _safeCall<void>(() => _textRecognizer.close());
  }

  Future<T?> _safeCall<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on MissingPluginException {
      return null;
    }
  }
}
