import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Abstraction layer for file/image storage.
///
/// Currently uses Firebase Storage. Can be swapped for S3, GCS,
/// or any other storage provider by implementing the same interface.
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery.
  Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 80,
  }) async {
    return _picker.pickImage(
      source: source,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: quality,
    );
  }

  /// Pick multiple images from gallery.
  Future<List<XFile>> pickMultipleImages({
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 80,
    int limit = 5,
  }) async {
    final images = await _picker.pickMultiImage(
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: quality,
      limit: limit,
    );
    return images;
  }

  /// Upload an image to Firebase Storage.
  ///
  /// [path] is the storage path (e.g., 'chargers/{chargerId}/photo1.jpg').
  /// Returns the download URL.
  Future<String> uploadImage(String path, XFile file) async {
    final ref = _storage.ref().child(path);

    UploadTask task;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      task = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      task = ref.putFile(File(file.path));
    }

    final snapshot = await task;
    return snapshot.ref.getDownloadURL();
  }

  /// Upload a profile image for a user.
  Future<String> uploadProfileImage(String userId, XFile file) async {
    final ext = file.name.split('.').last;
    return uploadImage('profiles/$userId/avatar.$ext', file);
  }

  /// Upload a charger image.
  Future<String> uploadChargerImage(
      String chargerId, XFile file, int index) async {
    final ext = file.name.split('.').last;
    return uploadImage('chargers/$chargerId/photo_$index.$ext', file);
  }

  /// Delete a file from storage.
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      debugPrint('Error deleting file at $path: $e');
    }
  }

  /// Delete a file by its download URL.
  Future<void> deleteFileByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting file by URL: $e');
    }
  }
}
