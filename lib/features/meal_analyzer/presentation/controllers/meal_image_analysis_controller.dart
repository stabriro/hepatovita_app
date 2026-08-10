import 'package:image_picker/image_picker.dart';

import '../../data/meal_image_extraction_service.dart';

enum MealImageAnalysisFailure {
  barcodeNotFound,
  textNotFound,
  barcodeAnalysisFailed,
  textAnalysisFailed,
}

class MealImageAnalysisResult {
  final String? query;
  final MealImageAnalysisFailure? failure;
  final Object? error;
  final bool cancelled;

  const MealImageAnalysisResult({
    this.query,
    this.failure,
    this.error,
    this.cancelled = false,
  });

  bool get hasQuery => query != null && query!.trim().isNotEmpty;
}

class MealImageAnalysisController {
  const MealImageAnalysisController._();

  static Future<MealImageAnalysisResult> analyzeFromBarcodeImage({
    required Future<ImageSource?> Function() chooseImageSource,
    required MealImageExtractionService extractionService,
  }) async {
    try {
      final source = await chooseImageSource();
      if (source == null) {
        return const MealImageAnalysisResult(cancelled: true);
      }

      final barcode = await extractionService.extractBarcode(source: source);
      if (barcode == null || barcode.trim().isEmpty) {
        return const MealImageAnalysisResult(
          failure: MealImageAnalysisFailure.barcodeNotFound,
        );
      }

      return MealImageAnalysisResult(query: barcode.trim());
    } catch (error) {
      return MealImageAnalysisResult(
        failure: MealImageAnalysisFailure.barcodeAnalysisFailed,
        error: error,
      );
    }
  }

  static Future<MealImageAnalysisResult> analyzeFromTextImage({
    required Future<ImageSource?> Function() chooseImageSource,
    required MealImageExtractionService extractionService,
  }) async {
    try {
      final source = await chooseImageSource();
      if (source == null) {
        return const MealImageAnalysisResult(cancelled: true);
      }

      final extractedText = await extractionService.extractText(source: source);
      if (extractedText == null || extractedText.trim().isEmpty) {
        return const MealImageAnalysisResult(
          failure: MealImageAnalysisFailure.textNotFound,
        );
      }

      final query = extractionService.pickBestMealQuery(extractedText).trim();
      if (query.isEmpty) {
        return const MealImageAnalysisResult(
          failure: MealImageAnalysisFailure.textNotFound,
        );
      }

      return MealImageAnalysisResult(query: query);
    } catch (error) {
      return MealImageAnalysisResult(
        failure: MealImageAnalysisFailure.textAnalysisFailed,
        error: error,
      );
    }
  }
}
