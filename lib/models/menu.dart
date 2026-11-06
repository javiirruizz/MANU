import 'pictograma.dart';

/// Modelo de datos que representa el menú de un día.
/// Relación: Pertenece a un [Comedor] a través de [idComedor].
/// Relación: * a * con [Pictograma] (Un menú puede tener varios pictogramas
/// y un pictograma puede pertenecer a varios menús).
class Menu {
  const Menu({
    required this.idMenu,
    required this.idComedor,
    required this.platos,
    required this.postre,
    required this.fecha,
    this.pictogramas = const [],
  });

  final String idMenu;
  final String idComedor;
  final List<String> platos;
  final String postre;
  final DateTime fecha;
  final List<Pictograma> pictogramas;

  /// Crea una copia de este menú modificando únicamente los campos indicados.
  Menu copyWith({
    String? idMenu,
    String? idComedor,
    List<String>? platos,
    String? postre,
    DateTime? fecha,
    List<Pictograma>? pictogramas,
  }) {
    return Menu(
      idMenu: idMenu ?? this.idMenu,
      idComedor: idComedor ?? this.idComedor,
      platos: platos ?? this.platos,
      postre: postre ?? this.postre,
      fecha: fecha ?? this.fecha,
      pictogramas: pictogramas ?? this.pictogramas,
    );
  }

  /// Convierte el menú a un mapa compatible con JSON o Firebase Firestore.
  /// [includePictogramas] permite evitar referencias circulares durante la serialización.
  Map<String, dynamic> toMap({bool includePictogramas = true}) {
    return {
      'idMenu': idMenu,
      'idComedor': idComedor,
      'platos': platos,
      'postre': postre,
      'fecha': fecha.toIso8601String(),
      if (includePictogramas)
        'pictogramas':
            pictogramas.map((p) => p.toMap(includeMenus: false)).toList(),
    };
  }

  /// Construye un menú a partir de un mapa.
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
      pictogramas: (map['pictogramas'] as List<dynamic>?)
              ?.map((item) => item is Map<String, dynamic>
                  ? Pictograma.fromMap(item)
                  : Pictograma(
                      idPictograma: item.toString(),
                      nombre: '',
                    ))
              .toList() ??
          const [],
    );
  }
}
