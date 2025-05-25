// services.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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
        return {"server": false, "ai": false, "calendar": false};
      }
    } catch (e) {
      print('Error checking service status: $e');
      return {"server": false, "ai": false, "calendar": false};
    }
  }

  static Future<Map<String, dynamic>> sendPayload({
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
    request.fields['child'] = (payload['isChild'] ?? false).toString();
    request.fields['pregnant'] = (payload['isPregnant'] ?? false).toString();

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
      var decoded = jsonDecode(response.body);
      print(decoded);
      if (decoded is List && decoded.isNotEmpty) {
        return decoded[0] as Map<String, dynamic>;
      } else if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        return {};
      }
    } else {
      return {};
    }
  } catch (e) {
    print('Error sending payload: $e');
    return {};
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
    print(payload);
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

  static List<Medicine> parseMedicationSchedule(Map<String, dynamic> payload) {
    List<Medicine> medicines = [];

    try {
      // Extract medication schedule data
      if (payload.containsKey('medications') &&
          payload['medications'] is List) {
        final List medicationsList = payload['medications'];
        final startDateStr = payload['start']['dateTime'];
        final DateTime startDate = DateTime.parse(startDateStr);

        for (var med in medicationsList) {
          final String name = med['name'];
          final int perDay = med['perDay'];
          final int days = med['days'];
          final String timeWindow = med['timeWindow'];

          // Parse time window (format: "09:00-17:00")
          final List<String> timeRange = timeWindow.split('-');
          final List<int> startTime =
              timeRange[0].split(':').map(int.parse).toList();
          final List<int> endTime =
              timeRange[1].split(':').map(int.parse).toList();

          final int startHour = startTime[0];
          final int endHour = endTime[0];

          // Calculate time between doses
          final int totalMinutes = (endHour - startHour) * 60;
          final int intervalMinutes = totalMinutes ~/ (perDay + 1);

          // Generate medicines for each day and each dose
          for (int day = 0; day < days; day++) {
            final DateTime medicineDate = startDate.add(Duration(days: day));

            for (int dose = 1; dose <= perDay; dose++) {
              // Calculate time for this dose
              final int doseMinutes = intervalMinutes * dose;
              final int hours = startHour + (doseMinutes ~/ 60);
              final int minutes = doseMinutes % 60;

              // Create medicine object
              medicines.add(
                Medicine(
                  name: name,
                  date: medicineDate,
                  time: TimeOfDay(hour: hours, minute: minutes),
                ),
              );
            }
          }
        }
      }
      return medicines;
    } catch (e) {
      print('Error parsing medication schedule: $e');
      return [];
    }
  }
}
