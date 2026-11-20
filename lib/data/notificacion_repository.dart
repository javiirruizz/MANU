import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notificacion.dart';

class NotificacionService {
  NotificacionService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference get _col => _db.collection('notificaciones');

  /// Guarda y envía una notificación en Firestore.
  Future<void> guardarNotificacionEnBD(Notificacion notificacion) async {
    final docRef = notificacion.idNotificacion.isNotEmpty
        ? _col.doc(notificacion.idNotificacion)
        : _col.doc();

    notificacion.idNotificacion = docRef.id;
    await docRef.set(notificacion.toJson());
  }

  /// Escucha en tiempo real todas las notificaciones dirigidas a [idAlumno].
  Stream<List<Notificacion>> watchNotificacionesAlumno(String idAlumno) {
    return _col
        .where('idAlumnos', arrayContains: idAlumno)
        .snapshots()
        .map((snap) {
      final lista = snap.docs
          .map((d) => Notificacion.fromMap(
                d.id,
                Map<String, dynamic>.from(d.data() as Map),
              ))
          .toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
      return lista;
    });
  }

  /// Marca una notificación como leída/vista por [idAlumno].
  Future<void> marcarComoLeida(String idNotificacion, String idAlumno) async {
    if (idNotificacion.isEmpty || idAlumno.isEmpty) return;
    await _col.doc(idNotificacion).update({
      'leidaPor': FieldValue.arrayUnion([idAlumno]),
    });
  }

  /// Descarga puntual de las notificaciones de un alumno.
  Future<List<Notificacion>> cargarNotificacionesAlumno(String idAlumno) async {
    final snap = await _col.where('idAlumnos', arrayContains: idAlumno).get();
    final lista = snap.docs
        .map((d) => Notificacion.fromMap(
              d.id,
              Map<String, dynamic>.from(d.data() as Map),
            ))
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }
}