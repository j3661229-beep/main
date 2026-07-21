import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Compresses photos before AI upload (JPEG). Server also optimizes via Sharp/WebP.
class ImageUploadHelper {
  ImageUploadHelper._();

  static const int maxSide = 1280;
  static const int quality = 82;
  static const int skipBelowBytes = 380 * 1024;

  static Future<String> prepareForUpload(String path) async {
    final file = File(path);
    if (!await file.exists()) return path;

    final originalSize = await file.length();
    if (originalSize <= skipBelowBytes) return path;

    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return path;

      final output = _resize(decoded);
      final jpeg = img.encodeJpg(output, quality: quality);
      if (jpeg.length >= originalSize) return path;

      final dir = await getTemporaryDirectory();
      final outPath = '${dir.path}/agri_upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outPath).writeAsBytes(jpeg);
      return outPath;
    } catch (_) {
      return path;
    }
  }

  static img.Image _resize(img.Image decoded) {
    final longest = decoded.width > decoded.height ? decoded.width : decoded.height;
    if (longest <= maxSide) return decoded;
    if (decoded.width >= decoded.height) {
      return img.copyResize(decoded, width: maxSide);
    }
    return img.copyResize(decoded, height: maxSide);
  }
}
