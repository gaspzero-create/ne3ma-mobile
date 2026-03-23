import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageUploadService {
  ImageUploadService._();

  // ── Cloudinary config ──────────────────────────
  static const String _cloudName    = 'dc4gxpkpb';
  static const String _uploadPreset = 'tpg1r7nd';
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/dc4gxpkpb/image/upload';

  static final _picker = ImagePicker();

  // ── Pick from gallery ──────────────────────────
  static Future<File?> pickFromGallery() async {
    debugPrint('🖼️ ImageUpload: Opening gallery...');
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (picked == null) {
        debugPrint('⚠️ ImageUpload: User cancelled picker');
        return null;
      }

      debugPrint('✅ ImageUpload: Image picked - ${picked.path}');
      return File(picked.path);
    } catch (e) {
      debugPrint('❌ ImageUpload: Pick error - $e');
      rethrow;
    }
  }

  // ── Compress image ─────────────────────────────
  static Future<File> compressImage(File file) async {
    debugPrint('🗜️ ImageUpload: Compressing...');
    try {
      final dir        = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 512,
        minHeight: 512,
        format: CompressFormat.jpeg,
      );

      if (compressed == null) {
        debugPrint('⚠️ ImageUpload: Compression failed, using original');
        return file;
      }

      final originalSize   = await file.length();
      final compressedSize = await compressed.length();
      debugPrint(
        '✅ ImageUpload: Compressed '
        '${(originalSize / 1024).toStringAsFixed(1)}KB → '
        '${(compressedSize / 1024).toStringAsFixed(1)}KB',
      );

      return File(compressed.path);
    } catch (e) {
      debugPrint('⚠️ ImageUpload: Compress error - $e, using original');
      return file;
    }
  }

  // ── Upload to Cloudinary ───────────────────────
  static Future<String> uploadToCloudinary(File file) async {
    debugPrint('☁️ ImageUpload: Uploading to Cloudinary...');
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder']        = 'ne3ma/avatars';

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      debugPrint('📡 ImageUpload: Sending request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json    = jsonDecode(response.body);
        final url     = json['secure_url'] as String;
        debugPrint('✅ ImageUpload: Upload success - $url');
        return url;
      } else {
        debugPrint('❌ ImageUpload: Upload failed - ${response.body}');
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ ImageUpload: Upload error - $e');
      rethrow;
    }
  }

  // ── Pick + Compress + Upload (all in one) ──────
  static Future<String?> pickAndUpload() async {
    // 1. Pick
    final file = await pickFromGallery();
    if (file == null) return null;

    // 2. Compress
    final compressed = await compressImage(file);

    // 3. Upload
    final url = await uploadToCloudinary(compressed);
    return url;
  }
}
