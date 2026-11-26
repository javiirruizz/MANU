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

  /// Stream en tiempo real del menú de hoy (se actualiza al instante al editar).
  Stream<Menu?> watchMenuDeHoy(String comedorId) {
    final db = _db;
    if (db == null) return Stream.value(null);

    final n = DateTime.now();
    final inicio = DateTime(n.year, n.month, n.day);
    final fin = inicio.add(const Duration(days: 1));

    return db
        .collection('menus')
        .where('comedorId', isEqualTo: comedorId)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha', isLessThan: Timestamp.fromDate(fin))
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return Menu.fromMap(snap.docs.first.id, snap.docs.first.data());
    });
  }

  /// Stream en tiempo real de todos los menús de una semana (lunes a domingo).
  Stream<List<Menu>> watchMenusSemana(String comedorId, DateTime lunes) {
    final db = _db;
    if (db == null) return Stream.value(const []);

    final inicio = DateTime(lunes.year, lunes.month, lunes.day);
    final fin = inicio.add(const Duration(days: 7));

    return db
        .collection('menus')
        .where('comedorId', isEqualTo: comedorId)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha', isLessThan: Timestamp.fromDate(fin))
        .orderBy('fecha')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Menu.fromMap(d.id, d.data())).toList());
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
    final db = _db;
    if (db == null) return null;

    final n = DateTime.now();
    final inicio = DateTime(n.year, n.month, n.day);
    final fin = inicio.add(const Duration(days: 1));

    final snap = await db
        .collection('menus')
        .where('comedorId', isEqualTo: comedorId)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha', isLessThan: Timestamp.fromDate(fin))
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return Menu.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  /// Menús de un rango de fechas.
  Future<List<Menu>> getMenus(
    String comedorId, {
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final db = _db;
    if (db == null) return const [];

    final snap = await db
        .collection('menus')
        .where('comedorId', isEqualTo: comedorId)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
        .where('fecha', isLessThan: Timestamp.fromDate(hasta))
        .orderBy('fecha')
        .get();

    return snap.docs.map((d) => Menu.fromMap(d.id, d.data())).toList();
  }
}