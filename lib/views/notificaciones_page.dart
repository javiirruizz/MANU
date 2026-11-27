import 'package:material_ui/material_ui.dart';

import '../core/app_theme.dart';
import '../core/tamanos.dart';
import '../data/audio_service.dart';
import '../data/notificacion_repository.dart';
import '../data/usuario_repository.dart';
import '../models/notificacion.dart';
import '../models/usuario.dart';
import 'widgets/avatar_usuario.dart';
import 'widgets/pictograma_imagen.dart';

/// Botón de la barra superior: campana con el número de avisos sin leer.
class BotonBandeja extends StatelessWidget {
  const BotonBandeja({super.key, required this.alumno});

  final Usuario alumno;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return StreamBuilder<List<Notificacion>>(
      stream: NotificacionService().watchNotificacionesAlumno(alumno.id),
      builder: (context, snap) {
        final sinLeer = (snap.data ?? [])
            .where((n) => !n.estaLeidaPor(alumno.id))
            .length;
        return Tooltip(
          message: 'Mis avisos',
          child: Material(
            color: sinLeer > 0 ? p.orangeSoft : p.tabTrack,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NotificacionesPage(alumno: alumno),
                ),
              ),
              child: SizedBox(
                width: context.medida(56),
                height: context.medida(56),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      sinLeer > 0
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color: sinLeer > 0 ? p.orange : p.textDark,
                      size: 30,
                    ),
                    if (sinLeer > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$sinLeer',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// HU 36: bandeja de entrada del alumno.
class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key, required this.alumno});

  final Usuario alumno;

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  final _servicio = NotificacionService();
  final _emisores = <String, Future<Usuario?>>{};

  Future<Usuario?> _emisor(String? id) {
    if (id == null || id.isEmpty) return Future.value(null);
    return _emisores.putIfAbsent(
      id,
      () => UsuarioRepository().obtenerUsuarioPorId(id),
    );
  }

  Future<void> _abrir(Notificacion n) async {
    // Al abrirlo pasa de "No leído" a "Leído"
    _servicio.marcarComoLeida(n.idNotificacion, widget.alumno.id);
    final emisor = await _emisor(n.emisorId);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _DetalleAviso(noti: n, emisor: emisor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis avisos',
          style: TextStyle(
            color: p.primary,
            fontWeight: FontWeight.w800,
            fontSize: 26,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Notificacion>>(
          stream: _servicio.watchNotificacionesAlumno(widget.alumno.id),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(
                child: Text(
                  'No se pudieron cargar los avisos.',
                  style: TextStyle(fontSize: 20),
                ),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final lista = snap.data!;
            if (lista.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mark_email_read_outlined,
                      size: 80,
                      color: p.textSoft,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No tienes avisos.',
                      style: TextStyle(fontSize: 24, color: p.textSoft),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lista.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final n = lista[i];
                return _FilaAviso(
                  noti: n,
                  leida: n.estaLeidaPor(widget.alumno.id),
                  emisor: _emisor(n.emisorId),
                  onTap: () => _abrir(n),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FilaAviso extends StatelessWidget {
  const _FilaAviso({
    required this.noti,
    required this.leida,
    required this.emisor,
    required this.onTap,
  });

  final Notificacion noti;
  final bool leida;
  final Future<Usuario?> emisor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: leida ? p.surface : p.cardTint,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: leida ? p.divider : p.primary,
              width: leida ? 1.5 : 3,
            ),
          ),
          child: Row(
            children: [
              PictogramaImagen(
                url: noti.pictogramaUrl,
                id: noti.pictogramaId,
                consulta: noti.mensaje.isEmpty ? noti.titulo : noti.mensaje,
                size: 96,
                iconoReserva: Icons.notifications_outlined,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      noti.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: leida ? FontWeight.w600 : FontWeight.w800,
                        color: p.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        FutureBuilder<Usuario?>(
                          future: emisor,
                          builder: (_, s) => AvatarUsuario(
                            nombre: s.data?.nombre ?? noti.emisorNombre ?? '?',
                            fotoUrl: s.data?.fotoUrl,
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            noti.emisorNombre ?? 'Tu profesor',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 18, color: p.textSoft),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: leida ? p.greenSoft : p.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      leida ? Icons.drafts_outlined : Icons.mark_email_unread,
                      color: leida ? p.greenDark : Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      leida ? 'Leído' : 'No leído',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: leida ? p.greenDark : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalleAviso extends StatelessWidget {
  const _DetalleAviso({required this.noti, required this.emisor});

  final Notificacion noti;
  final Usuario? emisor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PictogramaImagen(
                url: noti.pictogramaUrl,
                id: noti.pictogramaId,
                consulta: noti.mensaje.isEmpty ? noti.titulo : noti.mensaje,
                size: 190,
                iconoReserva: Icons.notifications_outlined,
              ),
              const SizedBox(height: 16),
              Text(
                noti.titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: p.primary,
                ),
              ),
              if (noti.mensaje.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  noti.mensaje,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, color: p.textDark),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AvatarUsuario(
                    nombre: emisor?.nombre ?? noti.emisorNombre ?? '?',
                    fotoUrl: emisor?.fotoUrl,
                    size: 56,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    noti.emisorNombre ?? 'Tu profesor',
                    style: TextStyle(fontSize: 20, color: p.textSoft),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => AudioService().leerTexto(
                        '${noti.titulo}. ${noti.mensaje}',
                      ),
                      icon: const Icon(Icons.volume_up_outlined, size: 28),
                      label: const Text(
                        'Escuchar',
                        style: TextStyle(fontSize: 20),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(62),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: p.primary,
                        minimumSize: const Size.fromHeight(62),
                      ),
                      child: const Text(
                        'ENTENDIDO',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
