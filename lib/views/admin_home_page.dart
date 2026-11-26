import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../data/horario_ejemplo.dart';
import '../data/menu_repository.dart';
import '../data/pictograma_repository.dart';
import '../data/tarea_repository.dart';
import '../data/usuario_repository.dart';
import '../models/pictograma.dart';
import '../models/usuario.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/gestor_tareas_view_model.dart';
import '../viewmodels/usuario_view_model.dart';
import 'agenda_page.dart';
import 'alta_usuario_page.dart';
import 'profesor/gestor_tareas_screen.dart';
import 'widgets/enviar_notificacion_dialog.dart';
import 'widgets/gestion_menu_dialog.dart';
import 'widgets/gestion_roles_dialog.dart';
import 'widgets/pictograma_selector_dialog.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  Future<void> _cargarHorario(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Creando el horario de la semana...')),
    );
    try {
      final alumnos = await UsuarioRepository().getAlumnos();
      if (alumnos.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Primero crea algún alumno en Gestión de usuarios.'),
          ),
        );
        return;
      }
      final n = await cargarHorarioEjemplo(
        alumnoIds: alumnos.map((a) => a.id).toList(),
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Horario creado: $n tareas para ${alumnos.length} alumno(s).',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.usuario;
    if (user == null ||
        (!user.esAdministrador && user.rol != RolUsuario.profesor)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel de gestión')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Acceso denegado: este panel de gestión es exclusivo para profesorado y administración.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }
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
                    onPressed: () {
                      final vm = GestorTareasViewModel(
                        tareaRepo: TareaRepository(),
                        usuarioRepo: UsuarioRepository(),
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GestorTareasScreen(
                            viewModel: vm,
                            profesorId: user.id,
                          ),
                        ),
                      );
                    },
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

                // --- Gestión del Menú Semanal (HU 12) ---
                if (user.tienePermiso(PermisoUsuario.gestionarMenu)) ...[
                  OutlinedButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          GestionMenuDialog(repository: MenuRepository()),
                    ),
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Gestión de menú semanal'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  gap,
                ],

                // --- Biblioteca de Pictogramas (HU 05) ---
                if (user.tienePermiso(PermisoUsuario.gestionarPictogramas)) ...[
                  OutlinedButton.icon(
                    onPressed: () async {
                      final seleccionado = await showDialog<Pictograma>(
                        context: context,
                        builder: (_) => PictogramaSelectorDialog(
                          repository: PictogramaRepository(),
                        ),
                      );
                      if (seleccionado != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Pictograma seleccionado: ${seleccionado.nombre}',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Biblioteca de pictogramas'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  gap,
                ],

                // --- Enviar Aviso Push Personalizado (HU 35) ---
                if (user.tienePermiso(PermisoUsuario.gestionarTareas)) ...[
                  OutlinedButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => EnviarNotificacionDialog(
                        tutorId: user.id,
                        tutorNombre: user.nombre,
                      ),
                    ),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Enviar aviso urgente'),
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
                  label: const Text('Vista previa de la agenda'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                if (user.tienePermiso(PermisoUsuario.gestionarTareas)) ...[
                  gap,
                  TextButton.icon(
                    onPressed: () => _cargarHorario(context),
                    icon: const Icon(Icons.science_outlined),
                    label: const Text('Cargar horario de ejemplo (semana)'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
