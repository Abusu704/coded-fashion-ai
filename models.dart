import 'dart:typed_data';

/// Garment as described by Member C's catalog JSON
/// (contract 1: selectedGarment {id, category, url}).
class Garment {
  final String id;
  final String category; // e.g. "tops", "bottoms"
  final String url; // http(s) URL or asset path
  final String name;

  const Garment({
    required this.id,
    required this.category,
    required this.url,
    required this.name,
  });

  // TODO(C): add mask data here once the catalog JSON shape is final.
  factory Garment.fromJson(Map<String, dynamic> j) => Garment(
        id: j['id'] as String,
        category: j['category'] as String,
        url: j['url'] as String,
        name: (j['name'] ?? j['id']) as String,
      );
}

/// Result of processTryOn (contract 2).
/// TODO(B): the real ImageResult type is undefined in the source -
/// replace/extend this once B publishes it (Appendix A, item 5).
class ImageResult {
  final Uint8List bytes;
  final String extension; // 'jpg' | 'png'
  final bool usedFallback; // B silently switched to IDM-VTON / CatVTON

  const ImageResult({
    required this.bytes,
    this.extension = 'jpg',
    this.usedFallback = false,
  });
}
