import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/comedor.dart';

class ComedorRepository {
  final _db = FirebaseFirestore.instance;

  Future<Comedor?> getComedor(String comedorId) async {
    final doc = await _db.collection('comedores').doc(comedorId).get();
    if (!doc.exists) return null;
    return Comedor.fromMap(doc.id, doc.data() ?? {});
  }
}
