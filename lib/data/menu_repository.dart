import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/menu.dart';

class MenuRepository {
  final _db = FirebaseFirestore.instance;

  /// Menú de hoy de un comedor (o null si no hay).
  Future<Menu?> getMenuDeHoy(String comedorId) async {
    final n = DateTime.now();
    final inicio = DateTime(n.year, n.month, n.day);
    final fin = inicio.add(const Duration(days: 1));

    final snap = await _db
        .collection('menus')
        .where('comedorId', isEqualTo: comedorId)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha', isLessThan: Timestamp.fromDate(fin))
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return Menu.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  /// Menús de un rango de fechas (p. ej. la semana).
  Future<List<Menu>> getMenus(
    String comedorId, {
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final snap = await _db
        .collection('menus')
        .where('comedorId', isEqualTo: comedorId)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
        .where('fecha', isLessThan: Timestamp.fromDate(hasta))
        .orderBy('fecha')
        .get();

    return snap.docs.map((d) => Menu.fromMap(d.id, d.data())).toList();
  }
}
