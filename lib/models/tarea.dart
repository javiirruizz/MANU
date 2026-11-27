import 'package:cloud_firestore/cloud_firestore.dart';

import 'paso.dart';
import 'valoracion.dart';
import 'pictograma.dart';

/// Modelo de datos que representa una tarea.
/// Relación: * a * con [Pictograma] (Una tarea puede contener/asociar varios pictogramas
/// y un pictograma puede estar asociado a varias tareas).
class Tarea {
  const Tarea({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fecha,
    required this.horario,
    required this.horaInicio,
    required this.horaFinal,
    required this.aulaId,
    required this.creadaPor,
    this.pasos = const [],
    this.alumnoIds = const [],
    this.contingenciaIds = const [],
    this.completadaPor = const {},
    this.valoraciones = const {},
    this.pictogramas = const [],
    this.imagenAdjuntaUrl,
    this.audioUrl,
    this.videoUrl,
    this.enlaceWeb,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final DateTime fecha;
  final String horario; // p. ej. "mañana" / "tarde"
  final DateTime horaInicio;
  final DateTime horaFinal;
  final String aulaId; // relación "se realiza en"
  final String creadaPor; // idUsuario del profesor/administrador
  final List<Paso> pasos;
  final List<String> alumnoIds; // "se asigna a"
  final List<String> contingenciaIds; // "prepara"
  final Map<String, DateTime> completadaPor; // idAlumno -> timestamp
  final Map<String, ValoracionTarea> valoraciones; // idAlumno -> emoción y estrellas (HU 22)
  final List<Pictograma> pictogramas; // relación muchos a muchos (* a *)
  final String? imagenAdjuntaUrl;
  final String? audioUrl;
  final String? videoUrl;
  final String? enlaceWeb;

  /// Pictograma de la tarea = el del último paso
  /// (si solo hay uno, es ese mismo).
  String? get pictogramaId => pasos.isEmpty ? null : pasos.last.pictogramaId;

  /// Obtiene los identificadores de todos los pictogramas asociados.
  List<String> get pictogramaIds =>
      pictogramas.map((p) => p.idPictograma).toList();

  /// Crea una copia de esta tarea modificando únicamente los campos indicados.
  Tarea copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    DateTime? fecha,
    String? horario,
    DateTime? horaInicio,
    DateTime? horaFinal,
    String? aulaId,
    String? creadaPor,
    List<Paso>? pasos,
    List<String>? alumnoIds,
    List<String>? contingenciaIds,
    Map<String, DateTime>? completadaPor,
    Map<String, ValoracionTarea>? valoraciones,
    List<Pictograma>? pictogramas,
    String? imagenAdjuntaUrl,
    String? audioUrl,
    String? videoUrl,
    String? enlaceWeb,
  }) {
    return Tarea(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      horario: horario ?? this.horario,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFinal: horaFinal ?? this.horaFinal,
      aulaId: aulaId ?? this.aulaId,
      creadaPor: creadaPor ?? this.creadaPor,
      pasos: pasos ?? this.pasos,
      alumnoIds: alumnoIds ?? this.alumnoIds,
      contingenciaIds: contingenciaIds ?? this.contingenciaIds,
      completadaPor: completadaPor ?? this.completadaPor,
      valoraciones: valoraciones ?? this.valoraciones,
      pictogramas: pictogramas ?? this.pictogramas,
      imagenAdjuntaUrl: imagenAdjuntaUrl ?? this.imagenAdjuntaUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      enlaceWeb: enlaceWeb ?? this.enlaceWeb,
    );
  }

  factory Tarea.fromMap(
    String id,
    Map<String, dynamic> m, {
    List<Pictograma>? pictogramas,
  }) {
    final pasos =
        (m['pasos'] as List<dynamic>? ?? [])
            .map(
              (p) => Paso.fromMap(p['id'] ?? '', Map<String, dynamic>.from(p)),
            )
            .toList()
          ..sort((a, b) => a.orden.compareTo(b.orden));

    final parsedPictogramas =
        pictogramas ??
        (m['pictogramas'] as List<dynamic>?)
            ?.map(
              (item) => item is Map<String, dynamic>
                  ? Pictograma.fromMap(
                      item,
                      id: item['idPictograma'] as String?,
                    )
                  : Pictograma(idPictograma: item.toString(), nombre: ''),
            )
            .toList() ??
        const [];

    final completadaPor = <String, DateTime>{};
    final rawCompletada = m['completadaPor'];
    if (rawCompletada is Map) {
      rawCompletada.forEach((alumnoId, v) {
        completadaPor[alumnoId.toString()] = v is Timestamp
            ? v.toDate()
            : DateTime.now();
      });
    }

    return Tarea(
      id: id,
      nombre: m['nombre'] ?? '',
      descripcion: m['descripcion'] ?? '',
      fecha: m['fecha'] is Timestamp
          ? (m['fecha'] as Timestamp).toDate()
          : (m['fecha'] is DateTime
                ? m['fecha'] as DateTime
                : DateTime.tryParse(m['fecha']?.toString() ?? '') ??
                      DateTime.now()),
      horario: m['horario'] ?? '',
      horaInicio: m['horaInicio'] is Timestamp
          ? (m['horaInicio'] as Timestamp).toDate()
          : (m['horaInicio'] is DateTime
                ? m['horaInicio'] as DateTime
                : DateTime.tryParse(m['horaInicio']?.toString() ?? '') ??
                      DateTime.now()),
      horaFinal: m['horaFinal'] is Timestamp
          ? (m['horaFinal'] as Timestamp).toDate()
          : (m['horaFinal'] is DateTime
                ? m['horaFinal'] as DateTime
                : DateTime.tryParse(m['horaFinal']?.toString() ?? '') ??
                      DateTime.now()),
      aulaId: m['aulaId'] ?? '',
      creadaPor: m['creadaPor'] ?? '',
      pasos: pasos,
      alumnoIds: List<String>.from(m['alumnoIds'] ?? []),
      contingenciaIds: List<String>.from(m['contingenciaIds'] ?? []),
      pictogramas: parsedPictogramas,
      completadaPor: completadaPor,
      valoraciones: ValoracionTarea.mapaDesde(m['valoraciones']),
      imagenAdjuntaUrl: m['imagenAdjuntaUrl'] as String?,
      audioUrl: m['audioUrl'] as String?,
      videoUrl: m['videoUrl'] as String?,
      enlaceWeb: m['enlaceWeb'] as String?,
    );
  }

  bool estaCompletadaPor(String idAlumno) =>
      completadaPor.containsKey(idAlumno);

  Duration get duracion => horaFinal.difference(horaInicio);

  String get tramoHorario => 'De ${hhmm(horaInicio)} a ${hhmm(horaFinal)}';

  String get duracionTexto {
    final h = duracion.inHours;
    final min = duracion.inMinutes.remainder(60);
    if (h == 0) return '$min min';
    if (min == 0) return '$h h';
    return '$h h $min min';
  }

  static String hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Tarea agregarPaso(String descripcion, {String? pictogramaId}) {
    final texto = descripcion.trim();
    if (texto.isEmpty) {
      throw ArgumentError('La descripción del paso no puede estar vacía.');
    }
    final nuevo = Paso(
      id: 'paso_${DateTime.now().microsecondsSinceEpoch}_${pasos.length + 1}',
      descripcion: texto,
      orden: pasos.length + 1,
      pictogramaId: pictogramaId,
    );
    return copyWith(pasos: [...pasos, nuevo]);
  }

  Tarea editarPaso(String pasoId, String nuevaDescripcion) {
    final texto = nuevaDescripcion.trim();
    if (texto.isEmpty) {
      throw ArgumentError('La descripción del paso no puede estar vacía.');
    }
    final actualizados = pasos
        .map((p) => p.id == pasoId ? p.copyWith(descripcion: texto) : p)
        .toList();
    return copyWith(pasos: actualizados);
  }

  Tarea eliminarPaso(String pasoId) {
    final filtrados = pasos.where((p) => p.id != pasoId).toList();
    final normalizados = [
      for (var i = 0; i < filtrados.length; i++)
        filtrados[i].copyWith(orden: i + 1),
    ];
    return copyWith(pasos: normalizados);
  }

  Tarea reordenarPasos(int indiceOrigen, int indiceDestino) {
    if (indiceOrigen < 0 ||
        indiceOrigen >= pasos.length ||
        indiceDestino < 0 ||
        indiceDestino >= pasos.length) {
      throw RangeError('Índice de paso fuera de rango.');
    }
    if (indiceOrigen == indiceDestino) return this;

    final lista = List<Paso>.from(pasos);
    final movido = lista.removeAt(indiceOrigen);
    lista.insert(indiceDestino, movido);

    final normalizados = [
      for (var i = 0; i < lista.length; i++) lista[i].copyWith(orden: i + 1),
    ];
    return copyWith(pasos: normalizados);
  }

  /// Convierte la entidad a un mapa compatible con JSON o Firebase.
  /// [includePictogramas] permite evitar referencias circulares durante la serialización.
  Map<String, dynamic> toMap({bool includePictogramas = false}) => {
    'nombre': nombre,
    'descripcion': descripcion,
    'fecha': Timestamp.fromDate(fecha),
    'horario': horario,
    'horaInicio': Timestamp.fromDate(horaInicio),
    'horaFinal': Timestamp.fromDate(horaFinal),
    'aulaId': aulaId,
    'creadaPor': creadaPor,
    'pasos': pasos.map((p) => p.toMap()).toList(),
    'alumnoIds': alumnoIds,
    'contingenciaIds': contingenciaIds,
    if (includePictogramas)
      'pictogramas': pictogramas.map((p) => p.toMap()).toList(),
    if (imagenAdjuntaUrl != null) 'imagenAdjuntaUrl': imagenAdjuntaUrl,
    if (audioUrl != null) 'audioUrl': audioUrl,
    if (videoUrl != null) 'videoUrl': videoUrl,
    if (enlaceWeb != null) 'enlaceWeb': enlaceWeb,
  };
}
