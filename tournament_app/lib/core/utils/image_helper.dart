import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageHelper {
  static final _picker = ImagePicker();

  /// Pick an image from the gallery with quality compression.
  static Future<File?> pickFromGallery({int quality = 85}) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: quality,
    );
    return picked != null ? File(picked.path) : null;
  }

  /// Take a photo with the camera with quality compression.
  static Future<File?> pickFromCamera({int quality = 85}) async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: quality,
    );
    return picked != null ? File(picked.path) : null;
  }

  /// Shows a bottom sheet to choose between gallery and camera.
  static Future<File?> pickWithChoice(BuildContext context) async {
    File? result;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                result = await pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () async {
                Navigator.pop(context);
                result = await pickFromCamera();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    return result;
  }

  /// Returns a placeholder asset path for a given tournament or user.
  static String placeholderAsset(String type) {
    return switch (type) {
      'tournament' => 'assets/images/tournament_placeholder.png',
      'user' => 'assets/images/user_placeholder.png',
      _ => 'assets/images/placeholder.png',
    };
  }

  /// Returns the file size in a human-readable format.
  static String formatFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Returns true if the file is a valid image (jpg, png, webp, gif).
  static bool isValidImage(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext);
  }

  /// Returns true if the file is within the allowed size limit (default 5MB).
  static bool isWithinSizeLimit(File file, {int maxMb = 5}) {
    return file.lengthSync() <= maxMb * 1024 * 1024;
  }
}
