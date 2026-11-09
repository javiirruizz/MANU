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

    return snapshot.docs.map((doc) => Tarea.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> guardarTarea(Tarea tarea) async {
    if (tarea.id.isEmpty) {
      await _firestore.collection('tareas').add(tarea.toMap());
    } else {
      await actualizarTarea(tarea);
    }
  }

  Future<void> actualizarTarea(Tarea tarea) async {
    await _firestore
        .collection('tareas')
        .doc(tarea.id)
        .update(tarea.toMap());
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
}