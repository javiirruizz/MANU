import 'package:flutter/material.dart';
import 'package:manu/views/widgets/gestion_roles_dialog.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../data/usuario_repository.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/usuario_view_model.dart';
import 'agenda_page.dart';
import 'alta_usuario_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final admin = auth.usuario!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de administración'),
        actions: [
          TextButton.icon(
            onPressed: auth.cerrarSesion,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hola, ${admin.nombre}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider(
                          create: (_) => UsuarioViewModel(
                            UsuarioRepository(),
                            solicitante: admin,
                          ),
                          child: const AltaUsuarioPage(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Gestión de usuarios'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => GestionRolesDialog(
                      repository: UsuarioRepository(),
                      solicitante: admin,
                    ),
                  ),
                  icon: const Icon(Icons.security),
                  label: const Text('Roles y permisos'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AgendaPage()),
                    );
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Ver la agenda'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
