import 'package:cloud_firestore/cloud_firestore.dart';

/// HU 22: emoción y estrellas que un alumno deja al terminar una tarea.
class ValoracionTarea {
  const ValoracionTarea({
    required this.emocionId,
    this.estrellas = 0,
    required this.fecha,
  });

  final String emocionId; // contento, tranquilo, preocupado, enfadado, cansado
  final int estrellas; // 0 = sin valorar, 1..5
  final DateTime fecha;

  String get emocionEtiqueta => etiquetaEmocion(emocionId);

  /// Emociones que conviene vigilar (ansiedad, frustración).
  bool get requiereAtencion =>
      emocionId == 'preocupado' ||
      emocionId == 'enfadado' ||
      (estrellas > 0 && estrellas <= 2);

  static String etiquetaEmocion(String id) =>
      id.isEmpty ? '' : id[0].toUpperCase() + id.substring(1);

  static Map<String, ValoracionTarea> mapaDesde(dynamic raw) {
    final resultado = <String, ValoracionTarea>{};
    if (raw is! Map) return resultado;
    raw.forEach((alumnoId, v) {
      if (v is! Map) return;
      final f = v['fecha'];
      resultado[alumnoId.toString()] = ValoracionTarea(
        emocionId: (v['emocion'] ?? '').toString(),
        estrellas: (v['estrellas'] as num?)?.toInt() ?? 0,
        fecha: f is Timestamp ? f.toDate() : DateTime.now(),
      );
    });
    return resultado;
  }
}
