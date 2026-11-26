import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/pictograma_repository.dart';
import '../../data/storage_repositoty.dart';
import '../../data/usuario_repository.dart';
import '../../models/pictograma.dart';
import '../../viewmodels/auth_view_model.dart';
import 'avatar_usuario.dart';
import 'pictograma_selector_dialog.dart';

/// HU 06: cambiar la foto de perfil (subir una foto o elegir un pictograma).
Future<void> mostrarPerfil(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _PerfilDialog(),
  );
}

class _PerfilDialog extends StatefulWidget {
  const _PerfilDialog();

  @override
  State<_PerfilDialog> createState() => _PerfilDialogState();
}

class _PerfilDialogState extends State<_PerfilDialog> {
  bool _guardando = false;
  String? _mensaje;

  Future<void> _guardar(String? url) async {
    if (url == null || url.isEmpty) {
      setState(() => _mensaje = 'No se ha podido subir la imagen.');
      return;
    }
    final auth = context.read<AuthViewModel>();
    final usuario = auth.usuario;
    if (usuario == null) return;
    try {
      await UsuarioRepository().actualizarFotoPerfil(usuario.id, url);
      auth.actualizarFotoLocal(url); // se ve al instante en todas las vistas
      if (mounted) setState(() => _mensaje = '¡Foto actualizada!');
    } catch (e) {
      if (mounted) setState(() => _mensaje = 'No se pudo guardar la foto.');
    }
  }

  Future<void> _subirFoto() async {
    setState(() {
      _guardando = true;
      _mensaje = null;
    });
    final url = await StorageRepository().seleccionarYSubirFotoPerfil();
    // Si cancela el selector no mostramos error
    if (url == null && mounted) {
      setState(() => _guardando = false);
      return;
    }
    await _guardar(url);
    if (mounted) setState(() => _guardando = false);
  }

  Future<void> _elegirPictograma() async {
    final elegido = await showDialog<Pictograma>(
      context: context,
      builder: (_) =>
          PictogramaSelectorDialog(repository: PictogramaRepository()),
    );
    if (elegido == null) return;
    setState(() {
      _guardando = true;
      _mensaje = null;
    });
    await _guardar(elegido.urlResuelta);
    if (mounted) setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final usuario = context.watch<AuthViewModel>().usuario;
    if (usuario == null) return const SizedBox.shrink();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: AvatarUsuario(
                  nombre: usuario.nombre,
                  fotoUrl: usuario.fotoUrl,
                  size: 150,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                usuario.nombre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: p.textDark,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _guardando ? null : _subirFoto,
                icon: const Icon(Icons.photo_camera_outlined, size: 30),
                label: const Text(
                  'Subir una foto',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: p.primary,
                  minimumSize: const Size.fromHeight(68),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _guardando ? null : _elegirPictograma,
                icon: const Icon(Icons.emoji_emotions_outlined, size: 30),
                label: const Text(
                  'Elegir un pictograma',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(68),
                ),
              ),
              if (_guardando) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_mensaje != null) ...[
                const SizedBox(height: 14),
                Text(
                  _mensaje!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _mensaje!.startsWith('¡') ? p.greenDark : Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar', style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
