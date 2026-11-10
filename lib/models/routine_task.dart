import 'package:flutter/material.dart';

/// Una tarea de la rutina del día.
class RoutineTask {
  const RoutineTask({
    required this.id,
    required this.time,
    required this.endTime,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    this.duration,
    this.completed = false,
    this.imageUrl,
    this.audioUrl,
  });

  final String id;
  final String time; // "09:00"
  final String endTime;
  final String? duration;
  final String title;
  final String subtitle;
  final IconData icon; // más adelante: pictograma de ARASAAC
  final Color iconColor;
  final Color iconBackground;
  final bool completed;
  final String? imageUrl;
  final String? audioUrl;

  String get timeRange => 'De $time a $endTime';

  RoutineTask copyWith({bool? completed}) => RoutineTask(
    id: id,
    time: time,
    endTime: endTime,
    duration: duration,
    title: title,
    subtitle: subtitle,
    icon: icon,
    iconColor: iconColor,
    iconBackground: iconBackground,
    completed: completed ?? this.completed,
    imageUrl: imageUrl ?? imageUrl,
    audioUrl: audioUrl ?? audioUrl,
  );
}
