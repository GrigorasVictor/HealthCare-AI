import 'package:flutter/material.dart';

class Medicine {
  final String name;
  final DateTime date;
  final TimeOfDay time;

  Medicine({required this.name, required this.date, required this.time});

  Medicine.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        date = DateTime.parse(json['date']),
        time = TimeOfDay(
          hour: int.parse(json['time'].split(':')[0]),
          minute: int.parse(json['time'].split(':')[1]),
        );
}