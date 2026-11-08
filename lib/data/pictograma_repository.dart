import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pictograma.dart';
import '../models/tarea.dart';

class FormatoNoAdmitidoException implements Exception {
  const FormatoNoAdmitidoException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

class PictogramaRepository {
  PictogramaRepository({FirebaseFirestore? firestore}) : _db = firestore;

  final FirebaseFirestore? _db;

  /// Catálogo inicial pre-cargado con pictogramas básicos de ARASAAC (Entrega 1).
  static final List<Pictograma> _precargadosArasaac = [
    const Pictograma(idPictograma: '2262', nombre: 'Asamblea matinal'),
    const Pictograma(idPictograma: '2337', nombre: 'Recreo y patio'),
    const Pictograma(idPictograma: '2457', nombre: 'Taller de tareas'),
    const Pictograma(idPictograma: '2342', nombre: 'Comedor'),
    const Pictograma(idPictograma: '2255', nombre: 'Lavarse las manos'),
    const Pictograma(idPictograma: '6964', nombre: 'Leer cuento'),
    const Pictograma(idPictograma: '2475', nombre: 'Música'),
    const Pictograma(idPictograma: '2369', nombre: 'Educación física'),
  ];

  final List<Pictograma> _bibliotecaLocal = List.of(_precargadosArasaac);

  /// Sincroniza los pictogramas básicos de ARASAAC en Firestore si la colección está vacía.
  Future<void> precargarPictogramasArasaacEnBD() async {
    final db = _db;
    if (db == null) return;

    final snap = await db.collection('pictogramas').limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = db.batch();
    for (final p in _precargadosArasaac) {
      final ref = db.collection('pictogramas').doc(p.idPictograma);
      batch.set(ref, p.toMap());
    }
    await batch.commit();
  }

  /// Prueba de aceptación 1 y 3:
  /// Sube un pictograma validando que sea formato PNG y asociándole una etiqueta textual.
  /// Si el archivo es PDF u otro formato, lanza [FormatoNoAdmitidoException].
  Future<Pictograma> subirPictograma({
    required String nombreArchivo,
    required String etiquetaTextual,
    String? imagenUrl,
  }) async {
    if (!Pictograma.esFormatoValido(nombreArchivo)) {
      throw const FormatoNoAdmitidoException(
        'Formato de archivo no admitido. Solo se permiten imágenes en formato PNG (.png).',
      );
    }

    if (etiquetaTextual.trim().isEmpty) {
      throw ArgumentError('La etiqueta textual no puede estar vacía.');
    }

    final nuevoId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final nuevoPictograma = Pictograma(
      idPictograma: nuevoId,
      nombre: etiquetaTextual.trim(),
      imagenUrl: imagenUrl ?? 'assets/pictogramas/$nombreArchivo',
      esDeArasaac: false,
    );

    // Guardar en la biblioteca en memoria
    _bibliotecaLocal.add(nuevoPictograma);

    // Guardar en Cloud Firestore si está disponible
    final db = _db;
    if (db != null) {
      await db
          .collection('pictogramas')
          .doc(nuevoId)
          .set(nuevoPictograma.toMap());
    }

    return nuevoPictograma;
  }

  /// Prueba de aceptación 2:
  /// Busca en la biblioteca interna pictogramas cuya etiqueta coincida con [consulta].
  Future<List<Pictograma>> buscarPorEtiqueta(String consulta) async {
    final texto = consulta.trim().toLowerCase();

    final db = _db;
    if (db != null) {
      final snap = await db.collection('pictogramas').get();
      if (snap.docs.isNotEmpty) {
        final todos = snap.docs
            .map((d) => Pictograma.fromMap(d.data(), id: d.id))
            .toList();
        if (texto.isEmpty) return todos;
        return todos
            .where((p) => p.nombre.toLowerCase().contains(texto))
            .toList();
      }
    }

    if (texto.isEmpty) {
      return List.unmodifiable(_bibliotecaLocal);
    }

    return _bibliotecaLocal
        .where((p) => p.nombre.toLowerCase().contains(texto))
        .toList();
  }

  /// Asigna un pictograma a una tarea (relación muchos a muchos).
  Future<Tarea> asignarPictogramaATarea({
    required Tarea tarea,
    required Pictograma pictograma,
  }) async {
    final yaExiste = tarea.pictogramas
        .any((p) => p.idPictograma == pictograma.idPictograma);

    final nuevaLista = yaExiste
        ? tarea.pictogramas
        : [...tarea.pictogramas, pictograma];

    final tareaActualizada = tarea.copyWith(pictogramas: nuevaLista);

    final db = _db;
    if (db != null) {
      await db
          .collection('tareas')
          .doc(tarea.id)
          .set(tareaActualizada.toMap(includePictogramas: true));
    }

    return tareaActualizada;
  }
}

