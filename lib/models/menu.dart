/// Modelo de datos que representa el menú de un día.
/// Relación: Pertenece a un [Comedor] a través de [idComedor].
class Menu {
  const Menu({
    required this.idMenu,
    required this.idComedor,
    required this.platos,
    required this.postre,
    required this.fecha,
  });

  final String idMenu;
  final String idComedor;
  final List<String> platos;
  final String postre;
  final DateTime fecha;

  /// Crea una copia de este menú modificando únicamente los campos indicados.
  Menu copyWith({
    String? idMenu,
    String? idComedor,
    List<String>? platos,
    String? postre,
    DateTime? fecha,
  }) {
    return Menu(
      idMenu: idMenu ?? this.idMenu,
      idComedor: idComedor ?? this.idComedor,
      platos: platos ?? this.platos,
      postre: postre ?? this.postre,
      fecha: fecha ?? this.fecha,
    );
  }

  /// Convierte el menú a un mapa compatible con JSON o Firebase Firestore.
  Map<String, dynamic> toMap() {
    return {
      'idMenu': idMenu,
      'idComedor': idComedor,
      'platos': platos,
      'postre': postre,
      'fecha': fecha.toIso8601String(),
    };
  }

  /// Construye un menú a partir de un mapa (por ejemplo recibido de Firebase o una API).
  factory Menu.fromMap(Map<String, dynamic> map, {String? id}) {
    return Menu(
      idMenu: id ?? map['idMenu'] as String? ?? '',
      idComedor: map['idComedor'] as String? ?? '',
      platos: (map['platos'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      postre: map['postre'] as String? ?? '',
      fecha: map['fecha'] != null
          ? DateTime.tryParse(map['fecha'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
