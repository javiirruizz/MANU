import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
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
import 'profesor/seguimiento_page.dart';
import 'widgets/confirmar_salida.dart';
import 'widgets/avatar_usuario.dart';
import 'widgets/perfil_dialog.dart';
import 'alta_usuario_page.dart';
import 'profesor/gestor_tareas_screen.dart';
import 'widgets/enviar_notificacion_dialog.dart';
import 'widgets/gestion_menu_dialog.dart';
import 'widgets/gestion_roles_dialog.dart';
import 'widgets/pictograma_selector_dialog.dart';
import 'familiar/conversaciones_page.dart';
import 'widgets/insignia_mensajes.dart';

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
    final p = context.palette;

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

    final accesos = <_Acceso>[
      // --- Planificar Tareas (acceso principal) ---
      if (user.tienePermiso(PermisoUsuario.gestionarTareas))
        _Acceso(
          icono: Icons.add_task,
          titulo: 'Planificar tareas',
          detalle: 'Crear y asignar la agenda',
          fondo: p.primary,
          color: Colors.white,
          destacada: true,
          onTap: () {
            final vm = GestorTareasViewModel(
              tareaRepo: TareaRepository(),
              usuarioRepo: UsuarioRepository(),
            );
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    GestorTareasScreen(viewModel: vm, profesorId: user.id),
              ),
            );
          },
        ),

      // --- Gestión de Usuarios ---
      if (user.tienePermiso(PermisoUsuario.gestionarUsuarios))
        _Acceso(
          icono: Icons.person_add,
          titulo: 'Gestión de usuarios',
          detalle: 'Altas, ediciones y bajas',
          fondo: p.cardTint,
          color: p.primary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) =>
                    UsuarioViewModel(UsuarioRepository(), solicitante: user),
                child: const AltaUsuarioPage(),
              ),
            ),
          ),
        ),

      // --- Roles y Permisos ---
      if (user.tienePermiso(PermisoUsuario.gestionarRolesYPermisos))
        _Acceso(
          icono: Icons.security,
          titulo: 'Roles y permisos',
          detalle: 'Quién puede hacer qué',
          fondo: p.badge,
          color: p.primary,
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => GestionRolesDialog(
              repository: UsuarioRepository(),
              solicitante: user,
            ),
          ),
        ),

      // --- Gestión del Menú Semanal (HU 12) ---
      if (user.tienePermiso(PermisoUsuario.gestionarMenu))
        _Acceso(
          icono: Icons.restaurant_menu,
          titulo: 'Menú semanal',
          detalle: 'Publicar el menú del comedor',
          fondo: p.orangeSoft,
          color: p.orange,
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => GestionMenuDialog(repository: MenuRepository()),
          ),
        ),

      // --- Biblioteca de Pictogramas (HU 05) ---
      if (user.tienePermiso(PermisoUsuario.gestionarPictogramas))
        _Acceso(
          icono: Icons.photo_library_outlined,
          titulo: 'Biblioteca de pictogramas',
          detalle: 'Buscar y subir imágenes',
          fondo: p.greenSoft,
          color: p.greenDark,
          onTap: () async {
            final seleccionado = await showDialog<Pictograma>(
              context: context,
              builder: (_) =>
                  PictogramaSelectorDialog(repository: PictogramaRepository()),
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
        ),

      // --- Enviar Aviso Push Personalizado (HU 35) ---
      if (user.tienePermiso(PermisoUsuario.gestionarTareas))
        _Acceso(
          icono: Icons.notifications_active_outlined,
          titulo: 'Enviar aviso urgente',
          detalle: 'Notificación a las familias',
          fondo: p.orangeSoft,
          color: p.orange,
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => EnviarNotificacionDialog(
              tutorId: user.id,
              tutorNombre: user.nombre,
            ),
          ),
        ),

      // --- Panel de seguimiento (HU 29) ---
      if (user.tienePermiso(PermisoUsuario.verSeguimiento))
        _Acceso(
          icono: Icons.insights_outlined,
          titulo: 'Panel de seguimiento',
          detalle: 'Progreso y emociones',
          fondo: p.greenSoft,
          color: p.greenDark,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SeguimientoPage())),
        ),

      if (user.rol == RolUsuario.profesor)
        _Acceso(
          icono: Icons.chat_bubble_outline,
          titulo: 'Mensajes',
          detalle: 'Hablar con las familias',
          fondo: p.cardTint,
          color: p.primary,
          conInsignia: true,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ConversacionesPage())),
        ),

      // --- Mi perfil (HU 06) ---
      _Acceso(
        icono: Icons.account_circle_outlined,
        titulo: 'Mi perfil y foto',
        detalle: 'Tus datos y tu imagen',
        fondo: p.cardTint,
        color: p.primary,
        onTap: () => mostrarPerfil(context),
      ),

      // --- Ver la Agenda ---
      _Acceso(
        icono: Icons.calendar_today,
        titulo: 'Vista previa de la agenda',
        detalle: 'Así la ven los alumnos',
        fondo: p.badge,
        color: p.primary,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AgendaPage())),
      ),
    ];

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: Text(
          user.esAdministrador
              ? 'Panel de administración'
              : 'Panel del profesor',
          style: TextStyle(color: p.primary, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => confirmarCerrarSesion(context),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _Cabecera(user: user),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, c) {
                    const hueco = 14.0;
                    final columnas = c.maxWidth >= 760
                        ? 3
                        : (c.maxWidth >= 480 ? 2 : 1);
                    final ancho =
                        (c.maxWidth - hueco * (columnas - 1)) / columnas;
                    return Wrap(
                      spacing: hueco,
                      runSpacing: hueco,
                      children: [
                        for (final a in accesos)
                          SizedBox(
                            width: ancho,
                            height: 112,
                            child: _TarjetaAcceso(acceso: a),
                          ),
                      ],
                    );
                  },
                ),
                if (user.tienePermiso(PermisoUsuario.gestionarTareas)) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _cargarHorario(context),
                      icon: const Icon(Icons.science_outlined),
                      label: const Text(
                        'Cargar horario de ejemplo (3 semanas)',
                      ),
                    ),
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

/// Datos de una tarjeta del panel.
class _Acceso {
  const _Acceso({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.fondo,
    required this.color,
    required this.onTap,
    this.destacada = false,
    this.conInsignia = false,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final Color fondo;
  final Color color;
  final VoidCallback onTap;
  final bool destacada;
  final bool conInsignia;
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.user});

  final Usuario user;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () => mostrarPerfil(context),
            child: AvatarUsuario(
              nombre: user.nombre,
              fotoUrl: user.fotoUrl,
              size: 80,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, ${user.nombre}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: p.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: p.badge,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.esAdministrador ? 'Administración' : 'Profesorado',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: p.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaAcceso extends StatelessWidget {
  const _TarjetaAcceso({required this.acceso});

  final _Acceso acceso;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final textoTitulo = acceso.destacada ? Colors.white : p.textDark;
    final textoDetalle = acceso.destacada ? Colors.white70 : p.textSoft;

    final tarjeta = Material(
      color: acceso.fondo,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: acceso.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: acceso.destacada ? Colors.white24 : p.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(acceso.icono, size: 34, color: acceso.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acceso.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: textoTitulo,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      acceso.detalle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: textoDetalle),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!acceso.conInsignia) return tarjeta;
    final uid = context.read<AuthViewModel>().usuario?.id;
    return uid == null ? tarjeta : InsigniaMensajes(uid: uid, child: tarjeta);
  }
}
