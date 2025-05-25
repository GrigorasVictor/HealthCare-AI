import 'package:flutter/material.dart';

class Medicine {
  final String name;
  final DateTime date;
  final TimeOfDay time;

  Medicine({
    required this.name,
    required this.date,
    required this.time,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    final parts = json['time'].split(':');
    return Medicine(
      name: json['name'],
      date: DateTime.parse(json['date']),
      time: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date.toIso8601String(),
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
    };
  }
}