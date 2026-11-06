import 'package:cloud_firestore/cloud_firestore.dart';

class Menu {
  const Menu({
    required this.id,
    required this.platos,
    required this.postre,
    required this.fecha,
    required this.comedorId,
  });

  final String id;
  final List<String> platos;
  final String postre;
  final DateTime fecha;
  final String comedorId;

  factory Menu.fromMap(String id, Map<String, dynamic> m) => Menu(
    id: id,
    platos: List<String>.from(m['platos'] ?? []),
    postre: m['postre'] ?? '',
    fecha: (m['fecha'] as Timestamp).toDate(),
    comedorId: m['comedorId'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'platos': platos,
    'postre': postre,
    'fecha': Timestamp.fromDate(fecha),
    'comedorId': comedorId,
  };
}
