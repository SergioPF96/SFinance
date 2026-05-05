import 'package:file_picker/file_picker.dart';

/// Thin wrapper around [FilePicker] that opens the OS file dialog
/// and returns the selected file path, or null if the user cancelled.
class ImagePickerService {
  const ImagePickerService();

  Future<String?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
      allowMultiple: false,
    );
    return result?.files.single.path;
  }
}
