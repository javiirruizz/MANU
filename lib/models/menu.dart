import 'package:cloud_firestore/cloud_firestore.dart';

class PlatoMenu {
  const PlatoMenu({
    required this.nombre,
    this.pictogramaId,
    this.pictogramaUrl,
  });

  final String nombre;
  final String? pictogramaId;
  final String? pictogramaUrl;

  factory PlatoMenu.fromMap(Map<String, dynamic> m) => PlatoMenu(
        nombre: m['nombre'] ?? '',
        pictogramaId: m['pictogramaId'] as String?,
        pictogramaUrl: m['pictogramaUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        if (pictogramaId != null) 'pictogramaId': pictogramaId,
        if (pictogramaUrl != null) 'pictogramaUrl': pictogramaUrl,
      };
}

class Menu {
  const Menu({
    required this.id,
    this.primerPlato = const PlatoMenu(nombre: ''),
    this.segundoPlato = const PlatoMenu(nombre: ''),
    Object? postre,
    List<String>? platos,
    required this.fecha,
    required this.comedorId,
  })  : _postreRaw = postre,
        _platosLegacy = platos;

  final String id;
  final PlatoMenu primerPlato;
  final PlatoMenu segundoPlato;
  final Object? _postreRaw;
  final List<String>? _platosLegacy;
  final DateTime fecha;
  final String comedorId;

  PlatoMenu get postre {
    final p = _postreRaw;
    if (p is PlatoMenu) return p;
    if (p is String) return PlatoMenu(nombre: p);
    return const PlatoMenu(nombre: '');
  }

  /// Compatibilidad con la lista de nombres de platos.
  List<String> get platos {
    if (_platosLegacy != null) return _platosLegacy;
    return [
      if (primerPlato.nombre.isNotEmpty) primerPlato.nombre,
      if (segundoPlato.nombre.isNotEmpty) segundoPlato.nombre,
    ];
  }

  factory Menu.fromMap(String id, Map<String, dynamic> m) {
    final listaAntigua =
        m['platos'] is List ? List<String>.from(m['platos']) : <String>[];

    final primer = m['primerPlato'] is Map<String, dynamic>
        ? PlatoMenu.fromMap(Map<String, dynamic>.from(m['primerPlato']))
        : PlatoMenu(nombre: listaAntigua.isNotEmpty ? listaAntigua[0] : '');

    final segundo = m['segundoPlato'] is Map<String, dynamic>
        ? PlatoMenu.fromMap(Map<String, dynamic>.from(m['segundoPlato']))
        : PlatoMenu(nombre: listaAntigua.length > 1 ? listaAntigua[1] : '');

    final postreObj = m['postre'] is Map<String, dynamic>
        ? PlatoMenu.fromMap(Map<String, dynamic>.from(m['postre']))
        : PlatoMenu(nombre: m['postre']?.toString() ?? '');

    return Menu(
      id: id,
      primerPlato: primer,
      segundoPlato: segundo,
      postre: postreObj,
      fecha: m['fecha'] is Timestamp
          ? (m['fecha'] as Timestamp).toDate()
          : DateTime.tryParse(m['fecha']?.toString() ?? '') ?? DateTime.now(),
      comedorId: m['comedorId'] ?? 'comedor_principal',
    );
  }

  Map<String, dynamic> toMap() => {
        'primerPlato': primerPlato.toMap(),
        'segundoPlato': segundoPlato.toMap(),
        'postre': postre.toMap(),
        'platos': platos,
        'fecha':
            Timestamp.fromDate(DateTime(fecha.year, fecha.month, fecha.day)),
        'comedorId': comedorId,
      };
}