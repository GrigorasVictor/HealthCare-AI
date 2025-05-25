// services.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:frontend/model.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class FilePickerResult {
  final String name;
  final Uint8List bytes;
  final String? path;

  FilePickerResult({required this.name, required this.bytes, this.path});
}

class ServiceFunctions {
  static const String _baseUrl = 'http://localhost:8080';

  static Future<Map<String, bool>> checkAllServiceStatus() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/server/status'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(key, value as bool));
      } else {
        return {"server": false,
                "ai": false,
                "calendar": false};
      }
    } catch (e) {
      print('Error checking service status: $e');
      return {"server": false,
                "ai": false,
                "calendar": false};
    }
  }
  static Future<List<Medicine>> sendPayload({
    required Map<String, dynamic> payload,
    Uint8List? fileBytes,
    String? filePath,
  }) async {
    try {
      var uri = Uri.parse('$_baseUrl/server/send');
      var request = http.MultipartRequest('POST', uri);

      // Add text fields
      request.fields['comment'] = payload['comment'] ?? '';
      request.fields['gender'] = payload['gender'] ?? '';
      request.fields['child'] = (payload['child'] ?? false).toString();
      request.fields['pregnant'] = (payload['pregnant'] ?? false).toString();

      // Add file if present
      if (fileBytes != null && filePath != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: filePath.split('/').last,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        return decoded.map((item) => Medicine.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  static Future<FilePickerResult?> pickImageLocally() async {
    try {
      // Use image picker to select an image
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        return null;
      }

      // Read the file as bytes
      final bytes = await pickedFile.readAsBytes();

      // Return the file information
      return FilePickerResult(
        name: pickedFile.name,
        bytes: bytes,
        path: pickedFile.path,
      );
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  static Future<bool> sendConfirmationPayload(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/server/calendar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}