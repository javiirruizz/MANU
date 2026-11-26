import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/paso.dart';
import '../models/tarea.dart';

class TareaRepository {
  TareaRepository({FirebaseFirestore? firestore})
    : _firestore =
          firestore ??
          (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  final FirebaseFirestore? _firestore;

  Future<List<Tarea>> getTareasPorFecha(DateTime fecha) async {
    final db = _firestore;
    if (db == null) return const [];

    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day, 0, 0, 0);
    final finDia = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);

    final snapshot = await db
        .collection('tareas')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(finDia))
        .get();

    return snapshot.docs
        .map((doc) => Tarea.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> guardarTarea(Tarea tarea) async {
    final db = _firestore;
    if (db == null) return;

    if (tarea.id.isEmpty) {
      await db.collection('tareas').add(tarea.toMap());
    } else {
      await actualizarTarea(tarea);
    }
  }

  Future<void> actualizarTarea(Tarea tarea) async {
    final db = _firestore;
    if (db == null) return;
    await db.collection('tareas').doc(tarea.id).update(tarea.toMap());
  }

  Future<void> eliminarTarea(String id) async {
    final db = _firestore;
    if (db == null) return;
    await db.collection('tareas').doc(id).delete();
  }

  Future<void> guardarTareasBatch(List<Tarea> tareas) async {
    final db = _firestore;
    if (db == null) return;

    final batch = db.batch();
    for (final tarea in tareas) {
      final docRef = db.collection('tareas').doc();
      batch.set(docRef, tarea.toMap());
    }
    await batch.commit();
  }

  Future<void> actualizarRecursosMultimedia(String tareaId, {String? videoUrl, String? audioUrl, String? enlaceWeb}) async {
    final db = _firestore;
    if (db == null) return;

    Map<String, dynamic> dataToUpdate = {};
    
    if (videoUrl != null) dataToUpdate['videoUrl'] = videoUrl;
    if (audioUrl != null) dataToUpdate['audioUrl'] = audioUrl;
    if (enlaceWeb != null) dataToUpdate['enlaceWeb'] = enlaceWeb;

    if (dataToUpdate.isNotEmpty) {
      await db.collection('tareas').doc(tareaId).update(dataToUpdate);
    }
  }

  Future<void> actualizarPasos(String tareaId, List<Paso> pasos) async {
    final db = _firestore;
    if (db == null) return;

    final normalizados = [
      for (var i = 0; i < pasos.length; i++) pasos[i].copyWith(orden: i + 1),
    ];
    await db.collection('tareas').doc(tareaId).update({
      'pasos': normalizados.map((p) => p.toMap()).toList(),
    });
  }

  /// Tareas del alumno para un día, en tiempo real.
  /// Filtramos la fecha en cliente para no necesitar un índice compuesto.
  Stream<List<Tarea>> streamTareasAlumno(String alumnoId, DateTime fecha) {
    final db = _firestore;
    if (db == null) return Stream.value(const []);

    return db
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
    final db = _firestore;
    if (db == null) return Stream.value(const []);

    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));
    return db
        .collection('tareas')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha', isLessThan: Timestamp.fromDate(fin))
        .snapshots()
        .map((s) => s.docs.map((d) => Tarea.fromMap(d.id, d.data())).toList());
  }

  Future<void> marcarCompletada(String tareaId, String alumnoId) async {
    final db = _firestore;
    if (db == null) return;
    await db.collection('tareas').doc(tareaId).update({
      'completadaPor.$alumnoId': FieldValue.serverTimestamp(),
    });
  }

  Future<void> desmarcarCompletada(String tareaId, String alumnoId) async {
    final db = _firestore;
    if (db == null) return;
    await db.collection('tareas').doc(tareaId).update({
      'completadaPor.$alumnoId': FieldValue.delete(),
    });
  }

  Stream<List<Tarea>> streamTareasAlumnoDesde(String alumnoId, DateTime desde) {
    final db = _firestore;
    if (db == null) return Stream.value(const []);

    final inicio = DateTime(desde.year, desde.month, desde.day);
    return db
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
    final db = _firestore;
    if (db == null) return;

    const antiguas = {
      'Asamblea matinal',
      'Recreo y patio',
      'Taller de tareas',
      'Comedor y aseo',
    };
    final snap = await db
        .collection('tareas')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
        .where('fecha', isLessThan: Timestamp.fromDate(hasta))
        .get();

    final batch = db.batch();
    for (final d in snap.docs) {
      if (d.id.startsWith('ejemplo_') ||
          antiguas.contains(d.data()['nombre'])) {
        batch.delete(d.reference);
      }
    }
    for (final t in tareas) {
      batch.set(db.collection('tareas').doc(t.id), t.toMap());
    }
    await batch.commit();
  }
}
