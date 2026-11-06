import 'package:cloud_firestore/cloud_firestore.dart';

import 'paso.dart';

class Tarea {
  const Tarea({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fecha,
    required this.horario,
    required this.horaInicio,
    required this.horaFinal,
    required this.aulaId,
    required this.creadaPor,
    this.pasos = const [],
    this.alumnoIds = const [],
    this.contingenciaIds = const [],
  });

  final String id;
  final String nombre;
  final String descripcion;
  final DateTime fecha;
  final String horario; // p. ej. "mañana" / "tarde"
  final DateTime horaInicio;
  final DateTime horaFinal;
  final String aulaId; // relación "se realiza en"
  final String creadaPor; // idUsuario del profesor/administrador
  final List<Paso> pasos;
  final List<String> alumnoIds; // "se asigna a"
  final List<String> contingenciaIds; // "prepara"

  /// Pictograma de la tarea = el del último paso
  /// (si solo hay uno, es ese mismo).
  String? get pictogramaId => pasos.isEmpty ? null : pasos.last.pictogramaId;

  factory Tarea.fromMap(String id, Map<String, dynamic> m) {
    final pasos =
        (m['pasos'] as List<dynamic>? ?? [])
            .map(
              (p) => Paso.fromMap(p['id'] ?? '', Map<String, dynamic>.from(p)),
            )
            .toList()
          ..sort((a, b) => a.orden.compareTo(b.orden));

    return Tarea(
      id: id,
      nombre: m['nombre'] ?? '',
      descripcion: m['descripcion'] ?? '',
      fecha: (m['fecha'] as Timestamp).toDate(),
      horario: m['horario'] ?? '',
      horaInicio: (m['horaInicio'] as Timestamp).toDate(),
      horaFinal: (m['horaFinal'] as Timestamp).toDate(),
      aulaId: m['aulaId'] ?? '',
      creadaPor: m['creadaPor'] ?? '',
      pasos: pasos,
      alumnoIds: List<String>.from(m['alumnoIds'] ?? []),
      contingenciaIds: List<String>.from(m['contingenciaIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'fecha': Timestamp.fromDate(fecha),
    'horario': horario,
    'horaInicio': Timestamp.fromDate(horaInicio),
    'horaFinal': Timestamp.fromDate(horaFinal),
    'aulaId': aulaId,
    'creadaPor': creadaPor,
    'pasos': pasos.map((p) => p.toMap()).toList(),
    'alumnoIds': alumnoIds,
    'contingenciaIds': contingenciaIds,
  };
}
