import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/file_resolver.dart';
import '../services/try_on_service.dart';
import '../utils/image_normalizer.dart';

/// Contract 1 - TryOnState {modelImage, selectedGarment, fallbackMode}.
/// Co-owned with Member C. Freeze the field names early.
/// TODO(C): C may replace this with their own state module; keep the same
/// fields/methods so the screens do not change.
class TryOnState extends ChangeNotifier {
  File? modelImage;
  Garment? selectedGarment;
  bool fallbackMode = false;
  final List<ImageResult> outputs = [];

  // UI-only flags (owned by A).
  bool isBusy = false;
  String? error;

  bool get canTryOn => modelImage != null && selectedGarment != null;
  ImageResult? get latestOutput => outputs.isEmpty ? null : outputs.last;

  void setModelImage(File? f) {
    modelImage = f;
    notifyListeners();
  }

  void selectGarment(Garment g) {
    selectedGarment = g;
    notifyListeners();
  }

  /// TODO(B/C): who writes the result into state is unspecified (Appendix A #4).
  void addOutput(ImageResult r) {
    outputs.add(r);
    fallbackMode = r.usedFallback;
    notifyListeners();
  }

  /// The API orchestrator: normalize -> resolve files -> processTryOn.
  /// Returns true on success. The loader (isBusy) stays up until this ends,
  /// including while B silently falls back to another endpoint.
  Future<bool> runTryOn(TryOnService service) async {
    if (!canTryOn) return false;
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      final modelFile = await ImageNormalizer.normalize(modelImage!);
      final garmentFile = await GarmentFileResolver.toFile(selectedGarment!.url);
      final result = await service
          .processTryOn(modelImg: modelFile, garmentImg: garmentFile)
          .timeout(const Duration(seconds: 90));
      addOutput(result);
      return true;
    } on TimeoutException {
      error = 'This is taking too long. Please try again.';
    } catch (e) {
      // TODO(B): Appendix A #6 - behaviour when Gemini AND fallback both fail.
      error = 'Something went wrong: $e';
    } finally {
      isBusy = false;
      notifyListeners();
    }
    return false;
  }
}
