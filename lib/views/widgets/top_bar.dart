import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/audio_service.dart';
import '../../data/notificacion_repository.dart';
import '../../models/notificacion.dart';
import '../../models/usuario.dart';
import '../../viewmodels/auth_view_model.dart';
import 'menu_perfil.dart';
import 'pictograma_imagen.dart';
import '../../core/app_theme.dart'; // Importante para context.palette
import '../../core/tamanos.dart';

/// Barra superior: logo, pestañas y el botón de "Mi espacio" (perfil).
class TopBar extends StatelessWidget {
  const TopBar({super.key, this.selectedIndex = 0});

  final int selectedIndex;

  static const _tabs = ['Hoy', 'Mes y festivos', 'Fin de semana'];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final usuario = auth.usuario;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.palette.surface, // Cambio dinámico
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Text(
            'Mi Agenda',
            style: TextStyle(
              // Sin const
              fontSize: context.letra(Letra.destacado),
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
          if (usuario != null && usuario.rol == RolUsuario.alumno)
            _ReceptorNotificaciones(alumnoId: usuario.id),

          // Un único botón: avatar y nombre. Dentro están el avatar, los
          // avisos, los colores, mis datos y salir.
          if (usuario != null) BotonPerfil(usuario: usuario),
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

        // Solo escucha y lanza la alerta: el icono visible es la campana
        // del botón de perfil (BotonPerfil), con su globito de avisos.
        return const SizedBox.shrink();
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
        height: context.medida(56),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? context.palette.primary
              : Colors.transparent, // Cambio dinámico
          borderRadius: BorderRadius.circular(11),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: context.letra(Letra.detalle),
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : context.palette.textDark, // Cambio dinámico
            ),
          ),
        ),
      ),
    );
  }
}
