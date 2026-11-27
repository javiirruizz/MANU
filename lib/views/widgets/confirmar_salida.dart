import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../viewmodels/auth_view_model.dart';

/// Pregunta "¿Seguro que quieres salir?" y, si se confirma, cierra la sesión.
Future<void> confirmarCerrarSesion(BuildContext context) async {
  final p = context.palette;
  final salir = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Icon(Icons.logout, size: 44, color: p.primary),
      title: const Text(
        '¿Seguro que quieres salir?',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: const Text(
        'Se cerrará tu sesión.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          style: OutlinedButton.styleFrom(minimumSize: const Size(130, 56)),
          child: const Text('No, quedarme', style: TextStyle(fontSize: 18)),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(ctx).pop(true),
          icon: const Icon(Icons.logout),
          label: const Text(
            'Sí, salir',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            minimumSize: const Size(130, 56),
          ),
        ),
      ],
    ),
  );
  if (salir != true || !context.mounted) return;
  final authVm = context.read<AuthViewModel>();
  Navigator.of(context).popUntil((r) => r.isFirst);
  await authVm.cerrarSesion();
}
