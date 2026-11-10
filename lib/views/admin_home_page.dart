import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../data/tarea_repository.dart';
import '../data/usuario_repository.dart';
import '../models/usuario.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/usuario_view_model.dart';
import 'agenda_page.dart';
import 'alta_usuario_page.dart';
import 'profesor/gestor_tareas_screen.dart';
import '../viewmodels/gestor_tareas_view_model.dart';
import 'widgets/gestion_roles_dialog.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.usuario!;
    final gap = const SizedBox(height: 12);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          user.esAdministrador
              ? 'Panel de administración'
              : 'Panel del profesor',
        ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hola, ${user.nombre}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 24),

                // --- Planificar Tareas (Botón Principal) ---
                if (user.tienePermiso(PermisoUsuario.gestionarTareas)) ...[
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GestorTareasScreen(
                          viewModel: GestorTareasViewModel(
                            tareaRepo: TareaRepository(),
                            usuarioRepo: UsuarioRepository(),
                          ),
                          profesorId: user.id,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.add_task),
                    label: const Text('Planificar tareas'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  gap,
                ],

                // --- Gestión de Usuarios ---
                if (user.tienePermiso(PermisoUsuario.gestionarUsuarios)) ...[
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider(
                          create: (_) => UsuarioViewModel(
                            UsuarioRepository(),
                            solicitante: user,
                          ),
                          child: const AltaUsuarioPage(),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Gestión de usuarios'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  gap,
                ],

                // --- Roles y Permisos ---
                if (user.tienePermiso(
                  PermisoUsuario.gestionarRolesYPermisos,
                )) ...[
                  OutlinedButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => GestionRolesDialog(
                        repository: UsuarioRepository(),
                        solicitante: user,
                      ),
                    ),
                    icon: const Icon(Icons.security),
                    label: const Text('Roles y permisos'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  gap,
                ],

                // --- Ver la Agenda ---
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const AgendaPage())),
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
