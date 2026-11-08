import 'menu.dart';
import 'tarea.dart';

/// Modelo de datos que representa un pictograma.
/// Relaciones:
/// - * a * con [Menu] (Un pictograma puede estar presente en varios menús
///   y un menú puede contener varios pictogramas).
/// - * a * con [Tarea] (Un pictograma puede estar asociado a varias tareas
///   y una tarea puede contener varios pictogramas).
class Pictograma {
  const Pictograma({
    required this.idPictograma,
    required this.nombre,
    this.imagenUrl,
    this.esDeArasaac = true,
    this.menus = const [],
    this.tareas = const [],
  });

  final String idPictograma;
  final String nombre; // Etiqueta textual asociada para búsquedas
  final String? imagenUrl; // URL de ARASAAC o ruta/base64 del PNG subido
  final bool esDeArasaac;
  final List<Menu> menus;
  final List<Tarea> tareas;

  /// Si es de ARASAAC y no tiene URL personalizada, construye la URL oficial en PNG.
  String get urlResuelta =>
      imagenUrl ??
      'https://static.arasaac.org/pictograms/$idPictograma/${idPictograma}_500.png';

  /// Valida que el archivo subido tenga formato PNG (Pruebas de aceptación 1 y 3).
  static bool esFormatoValido(String nombreArchivo) {
    return nombreArchivo.trim().toLowerCase().endsWith('.png');
  }

  /// Crea una copia de este pictograma modificando únicamente los campos indicados.
  Pictograma copyWith({
    String? idPictograma,
    String? nombre,
    String? imagenUrl,
    bool? esDeArasaac,
    List<Menu>? menus,
    List<Tarea>? tareas,
  }) {
    return Pictograma(
      idPictograma: idPictograma ?? this.idPictograma,
      nombre: nombre ?? this.nombre,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      esDeArasaac: esDeArasaac ?? this.esDeArasaac,
      menus: menus ?? this.menus,
      tareas: tareas ?? this.tareas,
    );
  }

  /// Convierte la entidad a un mapa compatible con JSON o Firebase.
  /// [includeMenus] e [includeTareas] permiten evitar referencias circulares durante la serialización.
  Map<String, dynamic> toMap({
    bool includeMenus = false,
    bool includeTareas = false,
  }) {
    return {
      'idPictograma': idPictograma,
      'nombre': nombre,
      'nombreBusqueda': nombre.trim().toLowerCase(),
      'imagenUrl': urlResuelta,
      'esDeArasaac': esDeArasaac,
      if (includeMenus)
        'menus': menus.map((m) => m.toMap()).toList(),
      if (includeTareas)
        'tareas': tareas.map((t) => t.toMap()).toList(),
    };
  }

  /// Construye una instancia de [Pictograma] a partir de un mapa.
  factory Pictograma.fromMap(
    Map<String, dynamic> map, {
    String? id,
    List<Menu>? menus,
    List<Tarea>? tareas,
  }) {
    return Pictograma(
      idPictograma: id ?? map['idPictograma'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      imagenUrl: map['imagenUrl'] as String?,
      esDeArasaac: map['esDeArasaac'] as bool? ?? true,
      menus: menus ??
          (map['menus'] as List<dynamic>?)
              ?.map((item) => item is Map<String, dynamic>
                  ? Menu.fromMap(item['id'] as String? ?? '', item)
                  : Menu(
                      id: item.toString(),
                      comedorId: '',
                      platos: const [],
                      postre: '',
                      fecha: DateTime.now(),
                    ))
              .toList() ??
          const [],
      tareas: tareas ??
          (map['tareas'] as List<dynamic>?)
              ?.map((item) => item is Map<String, dynamic>
                  ? Tarea.fromMap(item['id'] as String? ?? '', item)
                  : Tarea(
                      id: item.toString(),
                      nombre: '',
                      descripcion: '',
                      fecha: DateTime.now(),
                      horario: '',
                      horaInicio: DateTime.now(),
                      horaFinal: DateTime.now(),
                      aulaId: '',
                      creadaPor: '',
                    ))
              .toList() ??
          const [],
    );
  }
}
