import 'package:cloud_firestore/cloud_firestore.dart';

String formatoHoraChat(DateTime d) {
  String dos(int n) => n.toString().padLeft(2, '0');
  final hora = '${dos(d.hour)}:${dos(d.minute)}';
  final n = DateTime.now();
  final hoy = d.year == n.year && d.month == n.month && d.day == n.day;
  return hoy ? hora : '${d.day}/${d.month} $hora';
}

class MensajeChat {
  const MensajeChat({
    required this.id,
    required this.autorId,
    required this.texto,
    required this.fecha,
  });

  final String id;
  final String autorId;
  final String texto;
  final DateTime fecha;

  factory MensajeChat.fromMap(String id, Map<String, dynamic> m) => MensajeChat(
    id: id,
    autorId: m['autorId'] ?? '',
    texto: m['texto'] ?? '',
    // Hasta que el servidor confirma el timestamp llega null
    fecha: m['fecha'] is Timestamp
        ? (m['fecha'] as Timestamp).toDate()
        : DateTime.now(),
  );
}

class Conversacion {
  const Conversacion({
    required this.id,
    required this.tutorId,
    required this.tutorNombre,
    required this.familiarId,
    required this.familiarNombre,
    this.ultimoMensaje = '',
    this.ultimoAutorId = '',
    this.ultimaFecha,
    this.noLeidos = const {},
    this.tutorFotoUrl,
    this.familiarFotoUrl,
  });

  final String id;
  final String tutorId;
  final String tutorNombre;
  final String familiarId;
  final String familiarNombre;
  final String ultimoMensaje;
  final String ultimoAutorId;
  final DateTime? ultimaFecha;
  final Map<String, int> noLeidos;
  final String? tutorFotoUrl;
  final String? familiarFotoUrl;

  String? otroFoto(String miId) =>
      miId == tutorId ? familiarFotoUrl : tutorFotoUrl;

  static String idPara(String tutorId, String familiarId) =>
      '${tutorId}_$familiarId';

  String otroId(String miId) => miId == tutorId ? familiarId : tutorId;
  String otroNombre(String miId) =>
      miId == tutorId ? familiarNombre : tutorNombre;
  int noLeidosDe(String uid) => noLeidos[uid] ?? 0;

  factory Conversacion.fromMap(String id, Map<String, dynamic> m) {
    final nl = <String, int>{};
    if (m['noLeidos'] is Map) {
      (m['noLeidos'] as Map).forEach((k, v) {
        nl[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    }
    return Conversacion(
      id: id,
      tutorId: m['tutorId'] ?? '',
      tutorNombre: m['tutorNombre'] ?? '',
      familiarId: m['familiarId'] ?? '',
      familiarNombre: m['familiarNombre'] ?? '',
      ultimoMensaje: m['ultimoMensaje'] ?? '',
      ultimoAutorId: m['ultimoAutorId'] ?? '',
      ultimaFecha: m['ultimaFecha'] is Timestamp
          ? (m['ultimaFecha'] as Timestamp).toDate()
          : null,
      noLeidos: nl,
      tutorFotoUrl: m['tutorFotoUrl'] as String?,
      familiarFotoUrl: m['familiarFotoUrl'] as String?,
    );
  }
}
