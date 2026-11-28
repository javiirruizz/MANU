import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/chat_repository.dart';
import '../../data/usuario_repository.dart';
import '../../models/chat.dart';
import '../../models/usuario.dart';
import '../../viewmodels/auth_view_model.dart';
import '../widgets/avatar_usuario.dart';
import '../chat/chat_page.dart';
import '../widgets/avatar_usuario.dart';

/// HU 32: bandeja de mensajes entre tutores y familias.
class ConversacionesPage extends StatefulWidget {
  const ConversacionesPage({super.key});

  @override
  State<ConversacionesPage> createState() => _ConversacionesPageState();
}

class _ConversacionesPageState extends State<ConversacionesPage> {
  final _repo = ChatRepository();
  Stream<List<Conversacion>>? _stream;

  @override
  void initState() {
    super.initState();
    final yo = context.read<AuthViewModel>().usuario;
    if (yo != null) _stream = _repo.streamConversaciones(yo.id);
  }

  bool _permitido(Usuario? u) =>
      u != null &&
      (u.rol == RolUsuario.profesor || u.rol == RolUsuario.familiar);

  void _abrir(Conversacion c, Usuario yo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(conversacion: c, yo: yo),
      ),
    );
  }

  Future<void> _nuevo(Usuario yo) async {
    final contacto = await showDialog<Usuario>(
      context: context,
      builder: (_) => _SelectorContacto(yo: yo),
    );
    if (contacto == null || !mounted) return;

    final esFamiliar = yo.rol == RolUsuario.familiar;
    try {
      final conv = await _repo.abrirConversacion(
        tutor: esFamiliar ? contacto : yo,
        familiar: esFamiliar ? yo : contacto,
      );
      if (!mounted) return;
      _abrir(conv, yo);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la conversación.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final yo = context.watch<AuthViewModel>().usuario;

    if (!_permitido(yo)) {
      return Scaffold(
        backgroundColor: p.background,
        appBar: AppBar(title: const Text('Mensajes')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Los mensajes están disponibles para profesorado y familias.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19),
            ),
          ),
        ),
      );
    }
    final usuario = yo!;
    final esFamiliar = usuario.rol == RolUsuario.familiar;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: Text(
          'Mensajes',
          style: TextStyle(color: p.primary, fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nuevo(usuario),
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit, size: 28),
        label: Text(
          esFamiliar ? 'Escribir al tutor' : 'Escribir a una familia',
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: StreamBuilder<List<Conversacion>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'No se pudieron cargar los mensajes.',
                      style: TextStyle(fontSize: 19, color: p.textSoft),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: p.primary),
                  );
                }
                final lista = snap.data!;
                if (lista.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 72,
                            color: p.textSoft,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Todavía no hay mensajes',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: p.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pulsa el botón de abajo para escribir el primero.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: p.textSoft),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _tarjeta(lista[i], usuario, p),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _tarjeta(Conversacion c, Usuario yo, AppPalette p) {
    final nuevos = c.noLeidosDe(yo.id);
    final mio = c.ultimoAutorId == yo.id;
    final nombre = c.otroNombre(yo.id);

    return Material(
      color: nuevos > 0 ? p.cardTint : p.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _abrir(c, yo),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AvatarUsuario(
                nombre: nombre,
                fotoUrl: c.otroFoto(yo.id),
                size: 60,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: p.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${mio ? 'Tú: ' : ''}${c.ultimoMensaje}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: nuevos > 0
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: nuevos > 0 ? p.textDark : p.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (c.ultimaFecha != null)
                    Text(
                      formatoHoraChat(c.ultimaFecha!),
                      style: TextStyle(fontSize: 14, color: p.textSoft),
                    ),
                  if (nuevos > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: p.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        nuevos == 1 ? '1 nuevo' : '$nuevos nuevos',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista de profesores (si eres familia) o de familias (si eres profesor).
class _SelectorContacto extends StatefulWidget {
  const _SelectorContacto({required this.yo});

  final Usuario yo;

  @override
  State<_SelectorContacto> createState() => _SelectorContactoState();
}

class _SelectorContactoState extends State<_SelectorContacto> {
  late final Future<List<Usuario>> _futuro;

  @override
  void initState() {
    super.initState();
    final rolBuscado = widget.yo.rol == RolUsuario.familiar
        ? RolUsuario.profesor
        : RolUsuario.familiar;
    _futuro = UsuarioRepository()
        .listarUsuarios(filtroRol: rolBuscado)
        .then(
          (lista) =>
              lista.where((u) => u.estado == EstadoCuenta.activa).toList()
                ..sort((a, b) => a.nombre.compareTo(b.nombre)),
        );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final esFamiliar = widget.yo.rol == RolUsuario.familiar;

    return AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        esFamiliar ? '¿A qué tutor quieres escribir?' : '¿A qué familia?',
        style: TextStyle(fontWeight: FontWeight.w800, color: p.textDark),
      ),
      content: SizedBox(
        width: 440,
        height: 360,
        child: FutureBuilder<List<Usuario>>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(child: Text('No se pudo cargar la lista.'));
            }
            if (!snap.hasData) {
              return Center(child: CircularProgressIndicator(color: p.primary));
            }
            final lista = snap.data!;
            if (lista.isEmpty) {
              return Center(
                child: Text(
                  'No hay a quién escribir todavía.',
                  style: TextStyle(fontSize: 18, color: p.textSoft),
                ),
              );
            }
            return ListView.separated(
              itemCount: lista.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final u = lista[i];
                return Material(
                  color: p.background,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: AvatarUsuario(
                      nombre: u.nombre,
                      fotoUrl: u.fotoUrl,
                      size: 48,
                    ),
                    title: Text(
                      u.nombre,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: p.textDark,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(u),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(fontSize: 17)),
        ),
      ],
    );
  }
}
