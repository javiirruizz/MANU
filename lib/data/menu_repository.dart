import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/menu.dart';

class MenuRepository {
  MenuRepository({FirebaseFirestore? firestore})
    : _db =
          firestore ??
          (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  final FirebaseFirestore? _db;

  /// Genera un ID único por comedor y día (ej. comedor_principal_2026-11-19)
  /// para evitar duplicados y actualizar al instante.
  String buildDocId(String comedorId, DateTime fecha) {
    final y = fecha.year.toString().padLeft(4, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '${comedorId}_$y-$m-$d';
  }

  /// Consulta solo por rango de fechas (índice simple, automático en
  /// Firestore) y filtra el comedor en cliente. Combinar `comedorId ==` con
  /// un rango de `fecha` exige un índice compuesto que no existe, y la
  /// consulta fallaba sin mostrar nada ("No hay menú publicado").
  Query<Map<String, dynamic>> _rango(
    FirebaseFirestore db,
    DateTime desde,
    DateTime hasta,
  ) => db
      .collection('menus')
      .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
      .where('fecha', isLessThan: Timestamp.fromDate(hasta));

  List<Menu> _delComedor(
    QuerySnapshot<Map<String, dynamic>> snap,
    String comedorId,
  ) =>
      snap.docs
          .map((d) => Menu.fromMap(d.id, d.data()))
          .where((m) => m.comedorId == comedorId)
          .toList()
        ..sort((a, b) => a.fecha.compareTo(b.fecha));

  static DateTime _inicioDeHoy() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Stream en tiempo real del menú de hoy (se actualiza al instante al editar).
  Stream<Menu?> watchMenuDeHoy(String comedorId) {
    final db = _db;
    if (db == null) return Stream.value(null);

    final inicio = _inicioDeHoy();
    return _rango(
      db,
      inicio,
      inicio.add(const Duration(days: 1)),
    ).snapshots().map((snap) => _delComedor(snap, comedorId).firstOrNull);
  }

  /// Stream en tiempo real de todos los menús de una semana (lunes a domingo).
  Stream<List<Menu>> watchMenusSemana(String comedorId, DateTime lunes) {
    final db = _db;
    if (db == null) return Stream.value(const []);

    final inicio = DateTime(lunes.year, lunes.month, lunes.day);
    return _rango(
      db,
      inicio,
      inicio.add(const Duration(days: 7)),
    ).snapshots().map((snap) => _delComedor(snap, comedorId));
  }

  /// Publica o actualiza el menú de un día específico.
  Future<void> guardarMenuDia(Menu menu) async {
    final db = _db;
    if (db == null) return;

    final docId = menu.id.isNotEmpty
        ? menu.id
        : buildDocId(menu.comedorId, menu.fecha);
    await db.collection('menus').doc(docId).set(menu.toMap());
  }

  /// Menú de hoy (consulta puntual).
  Future<Menu?> getMenuDeHoy(String comedorId) async {
    final inicio = _inicioDeHoy();
    final lista = await getMenus(
      comedorId,
      desde: inicio,
      hasta: inicio.add(const Duration(days: 1)),
    );
    return lista.firstOrNull;
  }

  /// Menús de un rango de fechas.
  Future<List<Menu>> getMenus(
    String comedorId, {
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final db = _db;
    if (db == null) return const [];

    final snap = await _rango(db, desde, hasta).get();
    return _delComedor(snap, comedorId);
  }
}
