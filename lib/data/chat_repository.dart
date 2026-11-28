import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat.dart';
import '../models/usuario.dart';

class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _conversaciones =>
      _db.collection('conversaciones');

  /// Conversaciones con mensajes de un usuario, la más reciente primero.
  /// Solo filtra por array-contains (sin índice compuesto) y ordena en cliente.
  Stream<List<Conversacion>> streamConversaciones(String uid) => _conversaciones
      .where('participantes', arrayContains: uid)
      .snapshots()
      .map((snap) {
        final lista = snap.docs
            .map((d) => Conversacion.fromMap(d.id, d.data()))
            .where((c) => c.ultimoMensaje.isNotEmpty)
            .toList();
        lista.sort(
          (a, b) => (b.ultimaFecha ?? DateTime.now()).compareTo(
            a.ultimaFecha ?? DateTime.now(),
          ),
        );
        return lista;
      });

  /// Total de mensajes sin leer (para la insignia del panel).
  Stream<int> streamNoLeidos(String uid) => streamConversaciones(
    uid,
  ).map((l) => l.fold<int>(0, (s, c) => s + c.noLeidosDe(uid)));

  /// Mensajes de una conversación, el más reciente primero.
  Stream<List<MensajeChat>> streamMensajes(String conversacionId) =>
      _conversaciones
          .doc(conversacionId)
          .collection('mensajes')
          .orderBy('fecha', descending: true)
          .limit(150)
          .snapshots()
          .map(
            (s) =>
                s.docs.map((d) => MensajeChat.fromMap(d.id, d.data())).toList(),
          );

  /// Crea (o recupera) el canal entre un tutor y un familiar.
  Future<Conversacion> abrirConversacion({
    required Usuario tutor,
    required Usuario familiar,
  }) async {
    final id = Conversacion.idPara(tutor.id, familiar.id);
    await _conversaciones.doc(id).set({
      'participantes': [tutor.id, familiar.id],
      'tutorId': tutor.id,
      'tutorNombre': tutor.nombre,
      'familiarId': familiar.id,
      'familiarNombre': familiar.nombre,
      'tutorFotoUrl': tutor.fotoUrl,
      'familiarFotoUrl': familiar.fotoUrl,
    }, SetOptions(merge: true));
    final doc = await _conversaciones.doc(id).get();
    return Conversacion.fromMap(id, doc.data()!);
  }

  Future<void> actualizarMiFoto(Conversacion c, Usuario yo) async {
    final esTutor = yo.id == c.tutorId;
    final guardada = esTutor ? c.tutorFotoUrl : c.familiarFotoUrl;
    if (guardada == yo.fotoUrl) return;
    await _conversaciones.doc(c.id).update({
      esTutor ? 'tutorFotoUrl' : 'familiarFotoUrl': yo.fotoUrl,
    });
  }

  Future<void> enviarMensaje({
    required Conversacion conversacion,
    required String autorId,
    required String texto,
  }) async {
    final limpio = texto.trim();
    if (limpio.isEmpty) return;

    final destinatario = conversacion.otroId(autorId);
    final ref = _conversaciones.doc(conversacion.id);
    final batch = _db.batch();

    batch.set(ref.collection('mensajes').doc(), {
      'autorId': autorId,
      'texto': limpio,
      'fecha': FieldValue.serverTimestamp(),
    });
    batch.set(ref, {
      'ultimoMensaje': limpio.length > 120
          ? '${limpio.substring(0, 120)}…'
          : limpio,
      'ultimoAutorId': autorId,
      'ultimaFecha': FieldValue.serverTimestamp(),
      'noLeidos': {destinatario: FieldValue.increment(1), autorId: 0},
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> marcarLeida(String conversacionId, String uid) =>
      _conversaciones.doc(conversacionId).update({'noLeidos.$uid': 0});
}
