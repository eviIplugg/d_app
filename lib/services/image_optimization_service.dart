import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageOptimizationService {
  ImageOptimizationService._();

  static Future<File> optimizeJpeg(
    File input, {
    int minWidth = 1440,
    int minHeight = 1440,
    int quality = 75,
    bool keepExif = false,
  }) async {
    if (kIsWeb) return input;
    final dir = await getTemporaryDirectory();
    final outPath = '${dir.path}/opt_${DateTime.now().millisecondsSinceEpoch}_${input.uri.pathSegments.last}.jpg';

    final out = await FlutterImageCompress.compressAndGetFile(
      input.absolute.path,
      outPath,
      format: CompressFormat.jpeg,
      quality: quality.clamp(40, 95),
      minWidth: minWidth,
      minHeight: minHeight,
      keepExif: keepExif,
    );

    if (out == null) return input;
    return File(out.path);
  }
}

