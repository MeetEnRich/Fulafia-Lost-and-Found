import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StorageService {
  static String get _imgBbApiKey => dotenv.env['IMGBB_API_KEY'] ?? '';
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  /// Upload an image file to ImgBB using bytes to avoid Android scoped
  /// storage path access issues. Returns the direct image URL.
  Future<String> _uploadToImgBB(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse('$_uploadUrl?key=$_imgBbApiKey'),
      body: {'image': base64Image},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      return data['url'] as String;
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final error = json['error']?['message'] ?? 'Unknown error';
      throw Exception('ImgBB upload failed (${ response.statusCode}): $error');
    }
  }

  /// Upload a single item image and return its URL.
  Future<String> uploadItemImage({
    required File imageFile,
    required String itemId,
  }) =>
      _uploadToImgBB(imageFile);

  /// Upload multiple item images and return a list of URLs.
  Future<List<String>> uploadItemImages({
    required List<File> imageFiles,
    required String itemId,
  }) async {
    final urls = <String>[];
    for (final file in imageFiles) {
      final url = await _uploadToImgBB(file);
      urls.add(url);
    }
    return urls;
  }

  /// Upload a profile image and return its URL.
  Future<String> uploadProfileImage({
    required File imageFile,
    required String uid,
  }) =>
      _uploadToImgBB(imageFile);

  /// ImgBB free tier does not support deletion via the anonymous upload API.
  Future<void> deleteItemImages(String itemId) async {}

  /// ImgBB free tier does not support deletion via the anonymous upload API.
  Future<void> deleteImage(String imageUrl) async {}
}
