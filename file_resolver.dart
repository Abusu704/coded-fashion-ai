import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Turns a catalog url (http(s) or asset path) into a File for processTryOn.
class GarmentFileResolver {
  static Future<File> toFile(String url) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/garment_${url.hashCode}.png');
    if (await f.exists()) return f;

    if (url.startsWith('http')) {
      final client = HttpClient();
      try {
        final res = await (await client.getUrl(Uri.parse(url))).close();
        if (res.statusCode != 200) {
          throw HttpException('Garment download failed (${res.statusCode})');
        }
        return f.writeAsBytes(await consolidateHttpClientResponseBytes(res));
      } finally {
        client.close();
      }
    }
    final data = await rootBundle.load(url);
    return f.writeAsBytes(data.buffer.asUint8List());
  }
}
