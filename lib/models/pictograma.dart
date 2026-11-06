import 'menu.dart';

/// Modelo de datos que representa un pictograma.
/// Relación: * a * con [Menu] (Un pictograma puede estar presente en varios menús
/// y un menú puede contener varios pictogramas).
class Pictograma {
  const Pictograma({
    required this.idPictograma,
    required this.nombre,
    this.menus = const [],
  });

  final String idPictograma;
  final String nombre;
  final List<Menu> menus;

  /// Crea una copia de este pictograma modificando únicamente los campos indicados.
  Pictograma copyWith({
    String? idPictograma,
    String? nombre,
    List<Menu>? menus,
  }) {
    return Pictograma(
      idPictograma: idPictograma ?? this.idPictograma,
      nombre: nombre ?? this.nombre,
      menus: menus ?? this.menus,
    );
  }

  /// Convierte la entidad a un mapa compatible con JSON o Firebase.
  /// [includeMenus] permite evitar referencias circulares durante la serialización.
  Map<String, dynamic> toMap({bool includeMenus = false}) {
    return {
      'idPictograma': idPictograma,
      'nombre': nombre,
      if (includeMenus)
        'menus': menus.map((m) => m.toMap(includePictogramas: false)).toList(),
    };
  }

  /// Construye una instancia de [Pictograma] a partir de un mapa.
  factory Pictograma.fromMap(
    Map<String, dynamic> map, {
    String? id,
    List<Menu>? menus,
  }) {
    return Pictograma(
      idPictograma: id ?? map['idPictograma'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      menus: menus ??
          (map['menus'] as List<dynamic>?)
              ?.map((item) => item is Map<String, dynamic>
                  ? Menu.fromMap(item)
                  : Menu(
                      idMenu: item.toString(),
                      idComedor: '',
                      platos: const [],
                      postre: '',
                      fecha: DateTime.now(),
                    ))
              .toList() ??
          const [],
    );
  }
}

