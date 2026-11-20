import 'package:cloud_firestore/cloud_firestore.dart';

class Notificacion {
  String idNotificacion;
  String idTarea;
  List<String> idAlumnos; // Vector de alumnos a los que va dirigida
  DateTime fecha;
  DateTime hora;
  String? periodicidad;
  int? numeroPeriodicidad;

  // Campos para notificaciones push personalizadas (HU 35 y HU 36)
  String titulo;
  String mensaje;
  String? pictogramaId;
  String? pictogramaUrl;
  String? emisorId;
  String? emisorNombre;
  bool urgente;
  List<String> leidaPor;

  Notificacion({
    required this.idNotificacion,
    this.idTarea = '',
    required this.idAlumnos,
    required this.fecha,
    DateTime? hora,
    this.periodicidad,
    this.numeroPeriodicidad,
    this.titulo = 'Aviso del tutor',
    this.mensaje = '',
    this.pictogramaId,
    this.pictogramaUrl,
    this.emisorId,
    this.emisorNombre,
    this.urgente = true,
    this.leidaPor = const [],
  }) : hora = hora ?? fecha;

  bool estaLeidaPor(String alumnoId) => leidaPor.contains(alumnoId);

  static DateTime _parseFecha(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    return DateTime.tryParse(val?.toString() ?? '') ?? DateTime.now();
  }

  factory Notificacion.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Notificacion(
      idNotificacion: docId ?? json['idNotificacion'] ?? '',
      idTarea: json['idTarea'] ?? '',
      idAlumnos: List<String>.from(json['idAlumnos'] ?? []),
      fecha: _parseFecha(json['fecha']),
      hora: _parseFecha(json['hora'] ?? json['fecha']),
      periodicidad: json['periodicidad'],
      numeroPeriodicidad: json['numeroPeriodicidad'],
      titulo: json['titulo'] ?? 'Aviso del tutor',
      mensaje: json['mensaje'] ?? '',
      pictogramaId: json['pictogramaId'] as String?,
      pictogramaUrl: json['pictogramaUrl'] as String?,
      emisorId: json['emisorId'] as String?,
      emisorNombre: json['emisorNombre'] as String?,
      urgente: json['urgente'] ?? true,
      leidaPor: List<String>.from(json['leidaPor'] ?? []),
    );
  }

  factory Notificacion.fromMap(String id, Map<String, dynamic> map) =>
      Notificacion.fromJson(map, docId: id);

  Map<String, dynamic> toJson() {
    return {
      'idNotificacion': idNotificacion,
      'idTarea': idTarea,
      'idAlumnos': idAlumnos,
      'fecha': Timestamp.fromDate(fecha),
      'hora': Timestamp.fromDate(hora),
      'periodicidad': periodicidad,
      'numeroPeriodicidad': numeroPeriodicidad,
      'titulo': titulo,
      'mensaje': mensaje,
      if (pictogramaId != null) 'pictogramaId': pictogramaId,
      if (pictogramaUrl != null) 'pictogramaUrl': pictogramaUrl,
      if (emisorId != null) 'emisorId': emisorId,
      if (emisorNombre != null) 'emisorNombre': emisorNombre,
      'urgente': urgente,
      'leidaPor': leidaPor,
    };
  }

  Map<String, dynamic> toMap() => toJson();
}