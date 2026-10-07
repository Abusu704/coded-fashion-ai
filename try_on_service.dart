import 'dart:io';

import '../models/models.dart';

/// Contract 2 - API handoff (A calls, B implements).
/// TODO(B): implement with Gemini 2.5 Flash + silent IDM-VTON / CatVTON
/// fallback on 500/429 (contract 3). A's loader must stay up meanwhile.
abstract class TryOnService {
  Future<ImageResult> processTryOn({
    required File modelImg,
    required File garmentImg,
  });
}

/// Placeholder so the UI runs end-to-end before B's pipeline is ready.
/// Simply echoes the model photo after a short delay.
class MockTryOnService implements TryOnService {
  @override
  Future<ImageResult> processTryOn({
    required File modelImg,
    required File garmentImg,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 3));
    return ImageResult(bytes: await modelImg.readAsBytes());
  }
}
