import 'menu.dart';

/// Modelo de datos que representa el comedor.
/// Relación: Un [Comedor] tiene 1 o varios [Menu]s (1 a *).
class Comedor {
  const Comedor({
    required this.idComedor,
    this.menus = const [],
  });

  final String idComedor;
  final List<Menu> menus;

  /// Crea una copia de este comedor modificando únicamente los campos indicados.
  Comedor copyWith({
    String? idComedor,
    List<Menu>? menus,
  }) {
    return Comedor(
      idComedor: idComedor ?? this.idComedor,
      menus: menus ?? this.menus,
    );
  }

  /// Convierte la entidad a un mapa compatible con Firebase o JSON.
  Map<String, dynamic> toMap() {
    return {
      'idComedor': idComedor,
      'menus': menus.map((m) => m.toMap()).toList(),
    };
  }

  /// Construye una instancia de Comedor a partir de un mapa.
  factory Comedor.fromMap(Map<String, dynamic> map, {String? id}) {
    return Comedor(
      idComedor: id ?? map['idComedor'] as String? ?? '',
      menus: (map['menus'] as List<dynamic>?)
              ?.map((item) => Menu.fromMap(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
