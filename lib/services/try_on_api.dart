import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../data/garments/garments.dart';

class TryOnApiService {
  final String baseUrl;
  final http.Client _client;

  TryOnApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<TryOnApiResult> processTryOn({
    required String modelImagePath,
    required Garment garment,
  }) async {
    final garmentData = await rootBundle.load(garment.imagePath);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/try-on'),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'modelImage',
        modelImagePath,
      ),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        'garmentImage',
        garmentData.buffer.asUint8List(
          garmentData.offsetInBytes,
          garmentData.lengthInBytes,
        ),
        filename: garment.imagePath.split('/').last,
      ),
    );

    final streamedResponse = await _client
        .send(request)
        .timeout(const Duration(minutes: 2));

    final response = await http.Response.fromStream(streamedResponse);

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw TryOnApiException(
        'The server returned an invalid response.',
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw TryOnApiException(
        data['error']?.toString() ?? 'Try-on processing failed.',
      );
    }

    final resultUrl = data['resultImageUrl']?.toString();

    if (resultUrl == null || resultUrl.isEmpty) {
      throw TryOnApiException(
        'The server did not return a generated image URL.',
      );
    }

    return TryOnApiResult(
      resultImageUrl: resultUrl,
      detectedCategory: data['detectedCategory']?.toString(),
    );
  }

  void dispose() {
    _client.close();
  }
}

class TryOnApiResult {
  final String resultImageUrl;
  final String? detectedCategory;

  const TryOnApiResult({
    required this.resultImageUrl,
    this.detectedCategory,
  });
}

class TryOnApiException implements Exception {
  final String message;

  const TryOnApiException(this.message);

  @override
  String toString() => message;
}
