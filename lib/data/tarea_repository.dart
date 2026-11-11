import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tarea.dart';

class TareaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Tarea>> getTareasPorFecha(DateTime fecha) async {
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day, 0, 0, 0);
    final finDia = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection('tareas')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(finDia))
        .get();

    return snapshot.docs
        .map((doc) => Tarea.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> guardarTarea(Tarea tarea) async {
    if (tarea.id.isEmpty) {
      await _firestore.collection('tareas').add(tarea.toMap());
    } else {
      await actualizarTarea(tarea);
    }
  }

  Future<void> actualizarTarea(Tarea tarea) async {
    await _firestore.collection('tareas').doc(tarea.id).update(tarea.toMap());
  }

  Future<void> eliminarTarea(String id) async {
    await _firestore.collection('tareas').doc(id).delete();
  }

  Future<void> guardarTareasBatch(List<Tarea> tareas) async {
    final batch = _firestore.batch();
    for (final tarea in tareas) {
      final docRef = _firestore.collection('tareas').doc();
      batch.set(docRef, tarea.toMap());
    }
    await batch.commit();
  }

  /// Tareas del alumno para un día, en tiempo real.
  /// Filtramos la fecha en cliente para no necesitar un índice compuesto.
  Stream<List<Tarea>> streamTareasAlumno(String alumnoId, DateTime fecha) {
    return _firestore
        .collection('tareas')
        .where('alumnoIds', arrayContains: alumnoId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => Tarea.fromMap(d.id, d.data()))
                  .where(
                    (t) =>
                        t.fecha.year == fecha.year &&
                        t.fecha.month == fecha.month &&
                        t.fecha.day == fecha.day,
                  )
                  .toList()
                ..sort((a, b) => a.horaInicio.compareTo(b.horaInicio)),
        );
  }

  Stream<List<Tarea>> streamTareasPorFecha(DateTime fecha) {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));
    return _firestore
        .collection('tareas')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha', isLessThan: Timestamp.fromDate(fin))
        .snapshots()
        .map((s) => s.docs.map((d) => Tarea.fromMap(d.id, d.data())).toList());
  }

  Future<void> marcarCompletada(String tareaId, String alumnoId) {
    return _firestore.collection('tareas').doc(tareaId).update({
      'completadaPor.$alumnoId': FieldValue.serverTimestamp(),
    });
  }

  Future<void> desmarcarCompletada(String tareaId, String alumnoId) {
    return _firestore.collection('tareas').doc(tareaId).update({
      'completadaPor.$alumnoId': FieldValue.delete(),
    });
  }

  Stream<List<Tarea>> streamTareasAlumnoDesde(String alumnoId, DateTime desde) {
    final inicio = DateTime(desde.year, desde.month, desde.day);
    return _firestore
        .collection('tareas')
        .where('alumnoIds', arrayContains: alumnoId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => Tarea.fromMap(d.id, d.data()))
                  .where((t) => !t.fecha.isBefore(inicio))
                  .toList()
                ..sort((a, b) => a.horaInicio.compareTo(b.horaInicio)),
        );
  }

  /// Sustituye el horario de ejemplo del rango [desde, hasta) por [tareas].
  /// Borra antes las tareas de ejemplo anteriores (ids "ejemplo_..." y las 4
  /// del primer ejemplo) para no duplicar. No toca las demás.
  Future<void> reemplazarHorarioEjemplo({
    required List<Tarea> tareas,
    required DateTime desde,
    required DateTime hasta,
  }) async {
    const antiguas = {
      'Asamblea matinal',
      'Recreo y patio',
      'Taller de tareas',
      'Comedor y aseo',
    };
    final snap = await _firestore
        .collection('tareas')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
        .where('fecha', isLessThan: Timestamp.fromDate(hasta))
        .get();

    final batch = _firestore.batch();
    for (final d in snap.docs) {
      if (d.id.startsWith('ejemplo_') ||
          antiguas.contains(d.data()['nombre'])) {
        batch.delete(d.reference);
      }
    }
    for (final t in tareas) {
      batch.set(_firestore.collection('tareas').doc(t.id), t.toMap());
    }
    await batch.commit();
  }
}
