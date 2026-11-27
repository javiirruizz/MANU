import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_theme.dart'; // Importante: extensión del tema
import '../../core/tamanos.dart';
import '../../models/paso.dart';
import '../../models/tarea.dart';
import '../../viewmodels/agenda_view_model.dart';
import 'barra_progreso_pausable.dart';
import 'pictograma_imagen.dart';
import 'reproductor_audio.dart';
import 'reproductor_video.dart';
import 'valoracion_dialog.dart';

/// Horario del día: es la parte principal de la pantalla.
/// Las tareas se ven por "diapositivas" (dos por página si caben) y se pasa
/// de una a otra con los botones < > o deslizando el dedo.
class RoutineSection extends StatefulWidget {
  const RoutineSection({super.key});

  @override
  State<RoutineSection> createState() => _RoutineSectionState();
}

class _RoutineSectionState extends State<RoutineSection> {
  static const _separacion = 12.0;

  static const _etiquetas = {
    FiltroTareas.todas: 'Todas',
    FiltroTareas.actuales: 'Actuales',
    FiltroTareas.pendientes: 'Pendientes',
    FiltroTareas.completadas: 'Completadas',
  };

  static const _vacios = {
    FiltroTareas.todas: 'Hoy no tienes tareas.',
    FiltroTareas.actuales: 'Ahora no tienes ninguna tarea.',
    FiltroTareas.pendientes: '¡No te queda nada pendiente!',
    FiltroTareas.completadas: 'Todavía no has completado ninguna tarea.',
  };

  int _pagina = 0;

  /// Filtro para el que ya se ha saltado a la página de la tarea actual.
  FiltroTareas? _filtroColocado;

  /// Al abrir la agenda (o cambiar de filtro) se va a la página de la tarea
  /// que toca ahora; después el alumno pasa las páginas a su ritmo.
  void _colocar(List<Tarea> tareas, AgendaViewModel vm, int porPagina) {
    if (_filtroColocado == vm.filtro || tareas.isEmpty) return;
    _filtroColocado = vm.filtro;
    var i = tareas.indexWhere(vm.esActual);
    if (i == -1) i = tareas.indexWhere(vm.esProxima);
    _pagina = i == -1 ? 0 : i ~/ porPagina;
  }

  void _irA(int pagina) => setState(() => _pagina = pagina);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgendaViewModel>();
    final p = context.palette;

    // Si algo no se ha podido guardar, se avisa (antes fallaba en silencio)
    final aviso = vm.consumirAviso();
    if (aviso != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              aviso,
              style: TextStyle(fontSize: context.letra(Letra.detalle)),
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: p.primary, size: context.medida(36)),
              const SizedBox(width: 10),
              Text(
                'Mi horario',
                style: TextStyle(
                  fontSize: context.letra(Letra.destacado),
                  fontWeight: FontWeight.w800,
                  color: p.textDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      for (final f in FiltroTareas.values) ...[
                        ChoiceChip(
                          label: Text(_etiquetas[f]!),
                          labelStyle: TextStyle(
                            fontSize: context.letra(Letra.detalle),
                            fontWeight: FontWeight.w700,
                            color: vm.filtro == f ? Colors.white : p.textDark,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          selected: vm.filtro == f,
                          selectedColor: p.primary,
                          showCheckmark: false,
                          onSelected: (_) => vm.setFiltro(f),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: p.badge,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${vm.completedCount}/${vm.totalCount}',
                  style: TextStyle(
                    fontSize: context.letra(Letra.normal),
                    fontWeight: FontWeight.w800,
                    color: p.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: _contenido(vm, context)),
        ],
      ),
    );
  }

  Widget _contenido(AgendaViewModel vm, BuildContext context) {
    final p = context.palette;
    if (vm.error != null && vm.totalCount == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              vm.error!,
              style: TextStyle(
                fontSize: context.letra(Letra.normal),
                color: p.textSoft,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: vm.clearError,
              child: Text(
                'Reintentar',
                style: TextStyle(fontSize: context.letra(Letra.normal)),
              ),
            ),
          ],
        ),
      );
    }

    final tareas = vm.tasks;
    if (tareas.isEmpty) {
      return Center(
        child: Text(
          _vacios[vm.filtro]!,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.letra(Letra.normal),
            color: p.textSoft,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        // Dos tareas por página si caben con un alto cómodo; si no, una.
        final altoMinimo = context.medida(170);
        final altoNavegacion = context.medida(56);
        final altoTareas = c.maxHeight - altoNavegacion - 10;
        final porPagina = altoTareas >= altoMinimo * 2 + _separacion ? 2 : 1;
        final paginas = (tareas.length / porPagina).ceil();

        _colocar(tareas, vm, porPagina);
        final pagina = _pagina.clamp(0, paginas - 1);
        final inicio = pagina * porPagina;
        final visibles = tareas.sublist(
          inicio,
          math.min(inicio + porPagina, tareas.length),
        );

        return GestureDetector(
          // Deslizar el dedo también pasa de página
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v < -200 && pagina < paginas - 1) _irA(pagina + 1);
            if (v > 200 && pagina > 0) _irA(pagina - 1);
          },
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < porPagina; i++) ...[
                      if (i > 0) const SizedBox(height: _separacion),
                      Expanded(
                        // La tarea con barra de progreso o pasos, algo más alta
                        flex:
                            i < visibles.length && _tieneExtras(vm, visibles[i])
                            ? 4
                            : 3,
                        child: i < visibles.length
                            ? _tarjeta(vm, visibles[i])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Navegación abajo: < puntos >
              SizedBox(
                height: altoNavegacion,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Flecha(
                      icono: Icons.chevron_left,
                      etiqueta: 'Tareas anteriores',
                      onTap: pagina > 0 ? () => _irA(pagina - 1) : null,
                    ),
                    Expanded(
                      child: _Puntos(
                        total: paginas,
                        actual: pagina,
                        onTap: _irA,
                      ),
                    ),
                    _Flecha(
                      icono: Icons.chevron_right,
                      etiqueta: 'Tareas siguientes',
                      onTap: pagina < paginas - 1
                          ? () => _irA(pagina + 1)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Si la tarjeta muestra algo además de la fila principal.
  static bool _tieneExtras(AgendaViewModel vm, Tarea t) {
    bool lleno(String? s) => s != null && s.isNotEmpty;
    final barra = vm.esActual(t) && !vm.esCompletada(t);
    final pasos =
        t.pasos.isNotEmpty &&
        !(t.creadaPor == 'ejemplo' &&
            t.pasos.length == 1 &&
            t.pasos.first.descripcion == t.nombre);
    return barra ||
        pasos ||
        lleno(t.audioUrl) ||
        lleno(t.videoUrl) ||
        lleno(t.enlaceWeb);
  }

  Widget _tarjeta(AgendaViewModel vm, Tarea t) {
    return _TareaCard(
      key: ValueKey(t.id),
      tarea: t,
      actual: vm.esActual(t),
      completada: vm.esCompletada(t),
      onToggle: () async {
        final yaHecha = vm.esCompletada(t);
        final ok = await vm.toggleTask(t.id);
        // HU 22: al terminar la tarea se abre el panel de emoción
        if (ok && !yaHecha && mounted) {
          mostrarValoracion(context, vm: vm, tarea: t);
        }
      },
    );
  }
}

/// Botón < o > para pasar de página (abajo, junto a los puntos).
class _Flecha extends StatelessWidget {
  const _Flecha({required this.icono, required this.etiqueta, this.onTap});

  final IconData icono;
  final String etiqueta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final activa = onTap != null;
    return Semantics(
      button: true,
      enabled: activa,
      label: etiqueta,
      excludeSemantics: true,
      child: Material(
        color: p.tabTrack,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            width: context.medida(110),
            child: Icon(
              icono,
              size: context.medida(48),
              color: activa ? p.primary : p.textSoft.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}

/// Puntitos que indican en qué página estamos (se pueden pulsar).
class _Puntos extends StatelessWidget {
  const _Puntos({
    required this.total,
    required this.actual,
    required this.onTap,
  });

  final int total;
  final int actual;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lado = context.medida(16);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: i == actual ? lado * 2.2 : lado,
              height: lado,
              decoration: BoxDecoration(
                color: i == actual ? p.primary : p.divider,
                borderRadius: BorderRadius.circular(lado),
              ),
            ),
          ),
      ],
    );
  }
}

class _TareaCard extends StatelessWidget {
  const _TareaCard({
    super.key,
    required this.tarea,
    required this.actual,
    required this.completada,
    required this.onToggle,
  });

  final Tarea tarea;
  final bool actual;
  final bool completada;
  final VoidCallback onToggle;

  static String _hora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _mostrarVideo(BuildContext context, String videoUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.videocam, color: context.palette.primary, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tarea.nombre,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 650,
          child: SingleChildScrollView(
            child: ReproductorVideoWidget(url: videoUrl),
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(),
            icon: const Icon(Icons.close),
            label: const Text('Cerrar', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirEnlace(BuildContext context, String rawUrl) async {
    final urlFormateada =
        rawUrl.startsWith('http://') || rawUrl.startsWith('https://')
        ? rawUrl
        : 'https://$rawUrl';
    final uri = Uri.tryParse(urlFormateada);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final url = tarea.pictogramas.isNotEmpty
        ? tarea.pictogramas.first.urlResuelta
        : null;

    final tieneAudio = tarea.audioUrl != null && tarea.audioUrl!.isNotEmpty;
    final tieneVideo = tarea.videoUrl != null && tarea.videoUrl!.isNotEmpty;
    final tieneEnlace = tarea.enlaceWeb != null && tarea.enlaceWeb!.isNotEmpty;
    final pasosOrdenados = List.of(tarea.pasos)
      ..sort((a, b) => a.orden.compareTo(b.orden));
    final mostrarPasos =
        pasosOrdenados.isNotEmpty &&
        !(tarea.creadaPor == 'ejemplo' &&
            pasosOrdenados.length == 1 &&
            pasosOrdenados.first.descripcion == tarea.nombre);
    final mostrarBarra = actual && !completada;
    final hayExtras =
        mostrarPasos || tieneAudio || tieneVideo || tieneEnlace || mostrarBarra;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: actual
            ? p.cardTint
            : completada
            ? p.background
            : p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: actual ? p.primary : p.divider,
          width: actual ? 4 : 1.5,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          // La fila principal ocupa toda la tarjeta, o la mitad si hay extras
          // Con extras (barra de progreso, pasos...) se les reserva lo justo
          final altoFila = hayExtras
              ? math.max(c.maxHeight * 0.55, c.maxHeight - context.medida(84))
              : c.maxHeight;
          final picto = math.min(altoFila, context.medida(130));
          final check = math.min(altoFila, context.medida(96));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: altoFila,
                child: Row(
                  children: [
                    PictogramaImagen(
                      url: url,
                      id: tarea.pictogramaId,
                      consulta: tarea.nombre,
                      size: picto,
                      iconoReserva: Icons.event_note_outlined,
                      opacidad: completada ? 0.5 : 1,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, cc) => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: cc.maxWidth,
                            child: _textos(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      button: true,
                      label: completada
                          ? 'Marcar como pendiente'
                          : 'Marcar como hecha',
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onToggle,
                        child: Container(
                          width: check,
                          height: check,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: completada ? p.green : p.checkEmpty,
                          ),
                          child: Icon(
                            Icons.check,
                            color: completada ? Colors.white : p.surface,
                            size: check * 0.62,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (hayExtras) ...[
                const SizedBox(height: 8),
                // Solo si una tarea trae mucho contenido extra hace falta
                // desplazar dentro de su tarjeta.
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (mostrarBarra) BarraProgresoPausable(tarea: tarea),
                        if (mostrarPasos) _pasos(context, pasosOrdenados),
                        if (tieneAudio) ...[
                          const SizedBox(height: 8),
                          ReproductorAudioWidget(url: tarea.audioUrl!),
                        ],
                        if (tieneVideo || tieneEnlace) ...[
                          const SizedBox(height: 8),
                          _botonesMultimedia(context, tieneVideo, tieneEnlace),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _textos(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${_hora(tarea.horaInicio)} - ${_hora(tarea.horaFinal)}',
              style: TextStyle(
                fontSize: context.letra(Letra.normal),
                fontWeight: FontWeight.w800,
                color: p.primary,
              ),
            ),
            if (actual) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: p.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'AHORA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.letra(Letra.detalle),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        Text(
          tarea.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: context.letra(Letra.titulo),
            fontWeight: FontWeight.w800,
            color: completada ? p.textSoft : p.textDark,
          ),
        ),
        if (tarea.descripcion.isNotEmpty)
          Text(
            tarea.descripcion,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.letra(Letra.detalle),
              color: p.textSoft,
            ),
          ),
      ],
    );
  }

  Widget _pasos(BuildContext context, List<Paso> pasos) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.divider),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final paso in pasos)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: context.medida(15),
                  backgroundColor: p.primary,
                  child: Text(
                    '${paso.orden}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.letra(Letra.detalle) * 0.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  paso.descripcion,
                  style: TextStyle(
                    fontSize: context.letra(Letra.detalle),
                    fontWeight: FontWeight.w600,
                    color: completada ? p.textSoft : p.textDark,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _botonesMultimedia(
    BuildContext context,
    bool tieneVideo,
    bool tieneEnlace,
  ) {
    final p = context.palette;
    final estilo = TextStyle(
      fontSize: context.letra(Letra.detalle),
      fontWeight: FontWeight.w700,
    );
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (tieneVideo)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => _mostrarVideo(context, tarea.videoUrl!),
            icon: Icon(Icons.play_circle_fill, size: context.medida(28)),
            label: Text('Ver vídeo', style: estilo),
          ),
        if (tieneEnlace)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: p.primary,
              side: BorderSide(color: p.primary, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => _abrirEnlace(context, tarea.enlaceWeb!),
            icon: Icon(Icons.open_in_new, size: context.medida(26)),
            label: Text('Abrir enlace', style: estilo),
          ),
      ],
    );
  }
}
