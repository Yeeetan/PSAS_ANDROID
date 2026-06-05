import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static final _picker = ImagePicker();

  /// Opens the photo gallery, saves the selected image locally, and returns the local file path.
  static Future<String?> uploadFloorPlan(String floorId) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );

    if (image == null) return null;

    // Get the safe local directory for the app
    final directory = await getApplicationDocumentsDirectory();
    final localPath = '${directory.path}/floor_$floorId.jpg';

    // Copy the image to the permanent local path
    await File(image.path).copy(localPath);

    // Return the local path to be saved in the Realtime Database
    return localPath;
  }
}