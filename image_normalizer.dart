import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// WS-A2: crop + aspect-ratio conversion (+ EXIF rotation fix, downscale).
/// TODO(B): agree final size/format with B (Appendix A #2, B's Day 7 task).
class ImageNormalizer {
  static const double targetAspect = 3 / 4; // width / height
  static const int maxSide = 1024;
  static const int minSide = 256;

  static Future<File> normalize(
    File src, {
    double aspect = targetAspect,
    int maxSidePx = maxSide,
  }) async {
    final bytes = await src.readAsBytes();
    final out = await compute(_work, <Object>[bytes, aspect, maxSidePx]);
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/norm_${DateTime.now().microsecondsSinceEpoch}.jpg');
    return f.writeAsBytes(out);
  }

  static Uint8List _work(List<Object> a) {
    final bytes = a[0] as Uint8List;
    final aspect = a[1] as double;
    final maxSidePx = a[2] as int;

    var image = img.decodeImage(bytes);
    if (image == null) throw const FormatException('Unsupported image');
    image = img.bakeOrientation(image); // phone photos are often rotated
    if (image.width < minSide || image.height < minSide) {
      throw const FormatException('Photo is too small. Use a larger one.');
    }

    // Largest centred box with the target aspect (swap for padding if the
    // subject gets cut off).
    var cw = image.width, ch = image.height;
    if (cw / ch > aspect) {
      cw = (ch * aspect).round();
    } else {
      ch = (cw / aspect).round();
    }
    var out = img.copyCrop(image,
        x: (image.width - cw) ~/ 2, y: (image.height - ch) ~/ 2, width: cw, height: ch);

    if (math.max(cw, ch) > maxSidePx) {
      out = ch >= cw
          ? img.copyResize(out, height: maxSidePx)
          : img.copyResize(out, width: maxSidePx);
    }
    return Uint8List.fromList(img.encodeJpg(out, quality: 90));
  }
}
