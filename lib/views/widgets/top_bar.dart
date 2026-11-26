import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../data/audio_service.dart';
import '../../data/notificacion_repository.dart';
import '../../data/pictograma_repository.dart';
import '../../data/usuario_repository.dart';
import '../../models/notificacion.dart';
import '../../models/pictograma.dart';
import '../../models/usuario.dart';
import '../../viewmodels/auth_view_model.dart';
import 'gestion_roles_dialog.dart';
import 'pictograma_imagen.dart';
import 'avatar_usuario.dart';
import 'perfil_dialog.dart';
import '../notificaciones_page.dart';
import 'pictograma_selector_dialog.dart';
import '../../core/app_theme.dart'; // Importante para context.palette

/// Barra superior: logo, pestañas y accesos rápidos.
class TopBar extends StatelessWidget {
  const TopBar({super.key, this.selectedIndex = 0});

  final int selectedIndex;

  static const _tabs = [
    'Día a día',
    'Mes y festivos',
    'Fin de semana',
    'Mis datos',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final usuario = auth.usuario;
    final puedeRoles =
        usuario?.tienePermiso(PermisoUsuario.gestionarRolesYPermisos) ?? false;
    final puedePictos =
        usuario?.tienePermiso(PermisoUsuario.gestionarPictogramas) ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.palette.surface, // Cambio dinámico
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: context.palette.primary, // Cambio dinámico
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            'Mi Agenda',
            style: TextStyle(
              // Sin const
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: context.palette.primary, // Cambio dinámico
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context
                    .palette
                    .tabTrack, // Cambio dinámico (usa el color base de la paleta)
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: _TabItem(
                        label: _tabs[i],
                        selected: i == selectedIndex,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Receptor en tiempo real de notificaciones push para el alumno (HU 35)
          if (usuario != null && usuario.rol == RolUsuario.alumno) ...[
            _ReceptorNotificaciones(alumnoId: usuario.id),
            const SizedBox(width: 8),
            BotonBandeja(alumno: usuario),
            const SizedBox(width: 8),
          ],

          if (puedeRoles) ...[
            _SquareButton(
              icon: Icons.admin_panel_settings_outlined,
              tooltip: 'Gestión de Roles y Permisos (HU 03)',
              background: context.palette.tabTrack, // Cambio dinámico
              color: context.palette.primary, // Cambio dinámico
              onTap: () async {
                final usuario = context.read<AuthViewModel>().usuario;
                if (usuario == null) return;
                await showDialog(
                  context: context,
                  builder: (_) => GestionRolesDialog(
                    repository: UsuarioRepository(),
                    solicitante: usuario,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          if (puedePictos) ...[
            _SquareButton(
              icon: Icons.photo_library_outlined,
              tooltip: 'Biblioteca de Pictogramas (HU 05)',
              background: context.palette.badge, // Cambio dinámico
              color: context.palette.primary, // Cambio dinámico
              onTap: () async {
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
                      backgroundColor:
                          context.palette.primary, // Cambio dinámico
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
          ],
          if (usuario != null) ...[
            Tooltip(
              message: 'Mi perfil',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => mostrarPerfil(context),
                child: AvatarUsuario(
                  nombre: usuario.nombre,
                  fotoUrl: usuario.fotoUrl,
                  size: 56,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          _SquareButton(
            // Sin const para permitir acceso al context internamente
            icon: Icons.settings_outlined,
            tooltip: 'Ajustes',
            background: context.palette.tabTrack,
            color: context.palette.textDark,
          ),
          const SizedBox(width: 8),
          _SquareButton(
            // Sin const
            icon: Icons.logout,
            tooltip: 'Cerrar sesión',
            background: context.palette.tabTrack,
            color: context.palette.textDark,
            onTap: () {
              final nav = Navigator.of(context);
              final authVm = context.read<AuthViewModel>();
              nav.popUntil((r) => r.isFirst);
              authVm.cerrarSesion();
            },
          ),
        ],
      ),
    );
  }
}

/// Escucha avisos en Firestore en tiempo real y dispara la alerta visual y sonora.
class _ReceptorNotificaciones extends StatefulWidget {
  const _ReceptorNotificaciones({required this.alumnoId});

  final String alumnoId;

  @override
  State<_ReceptorNotificaciones> createState() =>
      _ReceptorNotificacionesState();
}

class _ReceptorNotificacionesState extends State<_ReceptorNotificaciones> {
  final _notiService = NotificacionService();
  final _audioService = AudioService();
  final Set<String> _mostradasEnSesion = {};

  void _mostrarAlertaUrgente(Notificacion noti) {
    _mostradasEnSesion.add(noti.idNotificacion);

    // Soporte sonoro inmediato mediante síntesis de voz
    _audioService.leerTexto('${noti.titulo}. ${noti.mensaje}');

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        // Extraemos ctx del builder pero usamos context de la app para paleta
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.notifications_active,
              color: context.palette.primary, // Cambio dinámico
              size: 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                noti.titulo,
                style: TextStyle(
                  // Sin const
                  fontWeight: FontWeight.w800,
                  color: context.palette.primary, // Cambio dinámico
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (noti.pictogramaUrl != null && noti.pictogramaUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  noti.pictogramaUrl!,
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      PictogramaImagen(consulta: noti.mensaje, size: 160),
                ),
              )
            else
              PictogramaImagen(consulta: noti.mensaje, size: 160),
            const SizedBox(height: 16),
            Text(
              noti.mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                // Sin const
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.palette.textDark, // Cambio dinámico
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton.icon(
            onPressed: () => _audioService.leerTexto(noti.mensaje),
            icon: const Icon(Icons.volume_up),
            label: const Text('Escuchar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.green, // Cambio dinámico
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              await _notiService.marcarComoLeida(
                noti.idNotificacion,
                widget.alumnoId,
              );
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            icon: const Icon(Icons.check_circle),
            label: const Text(
              'Entendido',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Notificacion>>(
      stream: _notiService.watchNotificacionesAlumno(widget.alumnoId),
      builder: (context, snapshot) {
        final todas = snapshot.data ?? [];
        final noLeidas = todas
            .where((n) => !n.estaLeidaPor(widget.alumnoId))
            .toList();

        // Si llega una notificación urgente nueva sin leer, saltará al instante
        final pendientesDeMostrar = noLeidas
            .where((n) => !_mostradasEnSesion.contains(n.idNotificacion))
            .toList();

        if (pendientesDeMostrar.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mostrarAlertaUrgente(pendientesDeMostrar.first);
            }
          });
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _SquareButton(
              icon: Icons.notifications_outlined,
              tooltip: 'Avisos (${noLeidas.length} sin leer)',
              background: noLeidas.isNotEmpty
                  ? AppColors.orangeSoft
                  : context
                        .palette
                        .tabTrack, // Cambio dinámico (el naranja lo dejamos fijo porque es de alerta universal)
              color: noLeidas.isNotEmpty
                  ? AppColors.orange
                  : context.palette.textDark, // Cambio dinámico
              onTap: () {
                if (noLeidas.isNotEmpty) {
                  _mostrarAlertaUrgente(noLeidas.first);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No tienes avisos pendientes.'),
                    ),
                  );
                }
              },
            ),
            if (noLeidas.isNotEmpty)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${noLeidas.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? context.palette.primary
              : Colors.transparent, // Cambio dinámico
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            // Sin const
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: selected
                ? Colors.white
                : context.palette.textDark, // Cambio dinámico
          ),
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.tooltip,
    this.background = Colors.transparent, // Se asigna desde fuera si hace falta
    this.color = Colors.black, // Se asigna desde fuera
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color background;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap ?? () {},
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(icon, color: color),
          ),
        ),
      ),
    );
  }
}
