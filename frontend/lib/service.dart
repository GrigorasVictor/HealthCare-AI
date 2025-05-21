// services.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class FilePickerResult {
  final String name;
  final Uint8List bytes;
  final String? path;

  FilePickerResult({required this.name, required this.bytes, this.path});
}

class ServiceFunctions {
  static const String _baseUrl = 'https://api.medicare-ai.example.com';

  static const String _apiKey = 'YOUR_API_KEY';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_apiKey',
  };

  static Future<bool> checkServerStatus() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return DateTime.now().second % 10 != 0; // 90% chance of being online
    } catch (e) {
      print('Error checking server status: $e');
      return false;
    }
  }

  static Future<bool> checkAIStatus() async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      return DateTime.now().second % 5 != 0;
    } catch (e) {
      print('Error checking AI status: $e');
      return false;
    }
  }

  static Future<bool> checkGoogleCalendarStatus() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return DateTime.now().second % 7 != 0; // 85% chance of being online
    } catch (e) {
      print('Error checking Google Calendar status: $e');
      return false;
    }
  }

  static Future<bool> sendPayload({
    required Map<String, dynamic> payload,
    Uint8List? fileBytes,
    String? filePath,
  }) async {
    try {
      // Simulate a delay for sending the payload
      await Future.delayed(const Duration(seconds: 2));

      // Log the payload and file details for debugging
      print('Sending payload: $payload');
      if (fileBytes != null && filePath != null) {
        print('With file: $filePath (${fileBytes.length} bytes)');
      } else if (filePath != null) {
        print('With file: $filePath');
      }

      // Simulate a successful response
      return true;
    } catch (e) {
      // Log the error
      print('Error sending payload: $e');
      return false;
    }
  }

  /// Pick an image locally (no server interaction)
  ///
  /// Returns a FilePickerResult with the selected file information
  static Future<FilePickerResult?> pickImageLocally() async {
    try {
      // Use image picker to select an image
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        // User canceled the picker
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
      print('Error picking image: $e');
      throw Exception('Failed to pick image: $e');
    }
  }

  static Future<bool> sendConfirmationPayload(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://your-server-endpoint/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending confirmation payload: $e');
      return false;
    }
  }
}
