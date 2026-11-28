import 'package:material_ui/material_ui.dart';

import '../../core/app_theme.dart';
import '../../data/audio_service.dart';
import '../../data/chat_repository.dart';
import '../../models/chat.dart';
import '../../models/usuario.dart';
import '../widgets/avatar_usuario.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.conversacion, required this.yo});

  final Conversacion conversacion;
  final Usuario yo;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _repo = ChatRepository();
  final _ctrl = TextEditingController();
  final _audio = AudioService();
  late final Stream<List<MensajeChat>> _mensajes;
  String? _ultimoMarcadoId;

  @override
  void initState() {
    super.initState();
    _mensajes = _repo.streamMensajes(widget.conversacion.id);
    _repo.actualizarMiFoto(widget.conversacion, widget.yo).catchError((_) {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty) return;
    _ctrl.clear();
    try {
      await _repo.enviarMensaje(
        conversacion: widget.conversacion,
        autorId: widget.yo.id,
        texto: texto,
      );
    } catch (_) {
      if (!mounted) return;
      _ctrl.text = texto; // no se pierde lo escrito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar el mensaje. Inténtalo de nuevo.'),
        ),
      );
    }
  }

  /// Si lo último que hay es de la otra persona, queda marcado como leído.
  void _marcarLeidaSiHaceFalta(List<MensajeChat> mensajes) {
    if (mensajes.isEmpty) return;
    final ultimo = mensajes.first;
    if (ultimo.autorId == widget.yo.id || ultimo.id == _ultimoMarcadoId) return;
    _ultimoMarcadoId = ultimo.id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _repo.marcarLeida(widget.conversacion.id, widget.yo.id);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final otro = widget.conversacion.otroNombre(widget.yo.id);
    final rolOtro = widget.yo.rol == RolUsuario.familiar
        ? 'Tutor/a'
        : 'Familiar';

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: Row(
          children: [
            AvatarUsuario(nombre: otro, fotoUrl: null, size: 44),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otro,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: p.primary,
                    ),
                  ),
                  Text(
                    rolOtro,
                    style: TextStyle(fontSize: 14, color: p.textSoft),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<MensajeChat>>(
                    stream: _mensajes,
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Center(
                          child: Text(
                            'No se pudieron cargar los mensajes.',
                            style: TextStyle(fontSize: 18, color: p.textSoft),
                          ),
                        );
                      }
                      if (!snap.hasData) {
                        return Center(
                          child: CircularProgressIndicator(color: p.primary),
                        );
                      }
                      final mensajes = snap.data!;
                      _marcarLeidaSiHaceFalta(mensajes);

                      if (mensajes.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Escribe el primer mensaje a $otro.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 20, color: p.textSoft),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: mensajes.length,
                        itemBuilder: (_, i) => _burbuja(mensajes[i], p, otro),
                      );
                    },
                  ),
                ),
                _barraEscritura(p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _burbuja(MensajeChat m, AppPalette p, String otro) {
    final mio = m.autorId == widget.yo.id;
    final fondo = mio ? p.primary : p.surface;
    final colorTexto = mio ? Colors.white : p.textDark;
    final colorSuave = mio ? Colors.white70 : p.textSoft;
    final ancho = (MediaQuery.sizeOf(context).width * 0.8)
        .clamp(0.0, 560.0)
        .toDouble();

    return Align(
      alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: ancho),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(mio ? 20 : 4),
            bottomRight: Radius.circular(mio ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // El autor se indica con texto, no solo con color ni posición
            Text(
              '${mio ? 'Tú' : otro} · ${formatoHoraChat(m.fecha)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorSuave,
              ),
            ),
            const SizedBox(height: 4),
            Text(m.texto, style: TextStyle(fontSize: 20, color: colorTexto)),
            if (!mio)
              TextButton.icon(
                onPressed: () => _audio.leerTexto(m.texto),
                icon: const Icon(Icons.volume_up, size: 24),
                label: const Text(
                  'Escuchar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _barraEscritura(AppPalette p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      color: p.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              minLines: 1,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                hintText: 'Escribe tu mensaje...',
                filled: true,
                fillColor: p.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _ctrl,
            builder: (_, v, _) => FilledButton.icon(
              onPressed: v.text.trim().isEmpty ? null : _enviar,
              icon: const Icon(Icons.send),
              label: const Text('Enviar'),
              style: FilledButton.styleFrom(
                backgroundColor: p.primary,
                minimumSize: const Size(0, 60),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
