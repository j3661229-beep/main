import 'package:image_picker/image_picker.dart';

/// Shared image picker settings for AI camera flows.
class AiImagePicker {
  AiImagePicker._();

  static const int maxSide = 1280;
  static const int quality = 80;

  static Future<XFile?> pick(ImageSource source) {
    return ImagePicker().pickImage(
      source: source,
      maxWidth: maxSide.toDouble(),
      maxHeight: maxSide.toDouble(),
      imageQuality: quality,
    );
  }
}
