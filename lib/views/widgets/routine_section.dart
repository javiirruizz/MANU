import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_theme.dart'; // Importante: extensión del tema
import '../../core/tamanos.dart';
import '../../models/paso.dart';
import '../../models/tarea.dart';
import '../../models/usuario.dart';
import '../../viewmodels/agenda_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import 'barra_progreso_tarea.dart';
import 'crear_tarea_dialog.dart';
import 'menu_section.dart';
import 'pictograma_imagen.dart';
import 'reproductor_audio.dart';
import 'reproductor_video.dart';
import 'valoracion_dialog.dart';

/// Horario del día: es la parte principal de la pantalla.
///
/// Las tareas van una al lado de otra (3 o 4 por página, según el ancho) y
/// se pasa de página con < >, con los puntos o deslizando el dedo. Abajo está
/// el botón de escuchar. A la derecha, en pequeño: nueva tarea (si el
/// profesor lo permite), menú del comedor y fin del día.
class RoutineSection extends StatefulWidget {
  const RoutineSection({super.key});

  @override
  State<RoutineSection> createState() => _RoutineSectionState();
}

class _RoutineSectionState extends State<RoutineSection> {
  static const _separacion = 12.0;

  static const _vacios = {
    FiltroTareas.todas: 'Hoy no tienes tareas.',
    FiltroTareas.actuales: 'Ahora no tienes ninguna tarea.',
    FiltroTareas.pendientes: '¡No te queda nada pendiente!',
    FiltroTareas.completadas: 'Todavía no has completado ninguna tarea.',
  };

  int _pagina = 0;

  /// Filtro para el que ya se ha saltado a la página de la tarea actual.
  FiltroTareas? _filtroColocado;

  /// Al abrir la agenda se va a la página de la tarea que toca ahora;
  /// después el alumno pasa las páginas a su ritmo.
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
    final usuario = context.watch<AuthViewModel>().usuario;
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

    // El profesor decide si el alumno puede crear sus propias tareas
    final puedeCrear =
        usuario != null &&
        usuario.rol == RolUsuario.alumno &&
        usuario.tienePermiso(PermisoUsuario.crearTareasPropias);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: _contenido(vm, context),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: context.medida(190),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            // Los tres botones se reparten todo el alto
            children: [
              if (puedeCrear) ...[
                Expanded(
                  child: _BotonLateral(
                    icono: Icons.add_rounded,
                    texto: 'Nueva tarea',
                    fondo: p.badge,
                    onTap: () => mostrarCrearTarea(context, alumno: usuario),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: _BotonLateral(
                  icono: Icons.restaurant,
                  pictograma: 'comedor',
                  texto: 'Menú del comedor',
                  fondo: const Color(0xFFFFE9C7), // tono cálido
                  onTap: () => mostrarMenuComedor(context),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _BotonLateral(
                  icono: Icons.check_rounded,
                  texto: 'Día completado',
                  fondo: vm.dayCompleted ? p.greenSoft : p.cardTint,
                  colorIcono: p.green, // tick verde
                  onTap: () => mostrarValoracionDia(context, vm: vm),
                ),
              ),
            ],
          ),
        ),
      ],
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
        // Tantas tarjetas por página como quepan con un ancho cómodo (3 o 4)
        final anchoMinimo = context.medida(260);
        final porPagina =
            ((c.maxWidth + _separacion) / (anchoMinimo + _separacion))
                .floor()
                .clamp(1, 4);
        final paginas = (tareas.length / porPagina).ceil();
        final altoNavegacion = context.medida(60);

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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < porPagina; i++) ...[
                      if (i > 0) const SizedBox(width: _separacion),
                      Expanded(
                        child: i < visibles.length
                            ? _tarjeta(vm, visibles[i], inicio + i)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Abajo: <  puntos · hechas · escuchar  >
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: _Puntos(
                              total: paginas,
                              actual: pagina,
                              onTap: _irA,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${vm.completedCount} de ${vm.totalCount} hechas',
                            style: TextStyle(
                              fontSize: context.letra(Letra.detalle),
                              fontWeight: FontWeight.w700,
                              color: p.textSoft,
                            ),
                          ),
                          const SizedBox(width: 16),
                          _BotonEscuchar(
                            onTap: () =>
                                vm.readAloud(_textoParaLeer(vm, visibles)),
                          ),
                        ],
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

  /// Lee en voz alta las tareas que se ven ahora en pantalla.
  static String _textoParaLeer(AgendaViewModel vm, List<Tarea> visibles) {
    String hora(DateTime d) =>
        '${d.hour}${d.minute == 0 ? '' : ' y ${d.minute}'}';
    final partes = [
      for (final t in visibles)
        '${t.nombre}, de ${hora(t.horaInicio)} a ${hora(t.horaFinal)}'
            '${vm.esCompletada(t) ? ', ya está hecha' : ''}'
            '${vm.esActual(t) ? ', es la tarea de ahora' : ''}.',
    ];
    final quedan = vm.totalCount - vm.completedCount;
    return '${partes.join(' ')} Te quedan $quedan tareas por hacer hoy.';
  }

  Widget _tarjeta(AgendaViewModel vm, Tarea t, int indice) {
    return _TareaCard(
      key: ValueKey(t.id),
      tarea: t,
      indice: indice,
      actual: vm.esActual(t),
      completada: vm.esCompletada(t),
      onToggle: () => vm.toggleTask(t.id),
    );
  }
}

/// Botón pequeño de la columna derecha: dibujo arriba y texto debajo.
class _BotonLateral extends StatelessWidget {
  const _BotonLateral({
    required this.icono,
    this.pictograma,
    required this.texto,
    required this.fondo,
    required this.onTap,
    this.colorIcono,
  });

  final IconData icono; // símbolo, o reserva del pictograma
  final String? pictograma; // palabra que se busca en ARASAAC
  final String texto;
  final Color fondo;
  final Color? colorIcono;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: texto,
      excludeSemantics: true,
      child: Material(
        color: fondo,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            height: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pictograma de ARASAAC o, si no hay, un símbolo sencillo
                  // (un "+" o un tick) dentro de un círculo de color.
                  if (pictograma != null)
                    PictogramaImagen(
                      consulta: pictograma,
                      size: context.medida(64),
                      iconoReserva: icono,
                    )
                  else
                    Container(
                      width: context.medida(64),
                      height: context.medida(64),
                      decoration: BoxDecoration(
                        color: colorIcono ?? p.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icono,
                        color: Colors.white,
                        size: context.medida(46),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    texto,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: context.letra(Letra.detalle),
                      fontWeight: FontWeight.w800,
                      color: p.textDark,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Altavoz para escuchar las tareas que se ven en pantalla.
class _BotonEscuchar extends StatelessWidget {
  const _BotonEscuchar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: 'Escuchar mis tareas',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Escuchar',
        child: Material(
          color: p.green,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: context.medida(58),
              height: context.medida(58),
              child: Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
                size: context.medida(34),
              ),
            ),
          ),
        ),
      ),
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

/// Una tarea en vertical: dibujo arriba, hora y nombre en el centro y el
/// botón de "hecha" abajo. En los temas de varios colores cada tarjeta lleva
/// un color pastel distinto.
class _TareaCard extends StatelessWidget {
  const _TareaCard({
    super.key,
    required this.tarea,
    required this.indice,
    required this.actual,
    required this.completada,
    required this.onToggle,
  });

  final Tarea tarea;
  final int indice;
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
    // Un único paso igual al nombre es solo el pictograma de la tarea
    final mostrarPasos =
        pasosOrdenados.isNotEmpty &&
        !(pasosOrdenados.length == 1 &&
            pasosOrdenados.first.descripcion == tarea.nombre);
    final hayExtras = mostrarPasos || tieneAudio || tieneVideo || tieneEnlace;

    final fondo = completada
        ? p.background
        : (p.acentos.isNotEmpty ? p.acento(indice) : p.surface);

    return Opacity(
      opacity: completada ? 0.75 : 1,
      child: Container(
        // El borde de la tarea de ahora es más grueso: se resta del relleno
        // para que el contenido quede en el mismo sitio que en las demás
        padding: EdgeInsets.all(actual ? 12 - 2.5 : 12),
        decoration: BoxDecoration(
          color: actual && p.acentos.isEmpty ? p.cardTint : fondo,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: actual ? p.primary : p.divider,
            width: actual ? 4 : 1.5,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            // El dibujo crece con la tarjeta, dejando sitio a lo demás
            final picto = math.min(
              c.maxWidth * 0.62,
              // Mismo tamaño en todas las tarjetas: el dibujo no salta de
              // sitio ni cambia de tamaño entre la tarea de ahora y las demás
              c.maxHeight * 0.23,
            );
            final altoBoton = context.medida(58);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: PictogramaImagen(
                    url: url,
                    id: tarea.pictogramaId,
                    consulta: tarea.nombre,
                    size: picto,
                    iconoReserva: Icons.event_note_outlined,
                    opacidad: completada ? 0.5 : 1,
                  ),
                ),
                const SizedBox(height: 8),
                // Si el texto no cabe en el alto de la pantalla, se encoge un
                // poco en lugar de desbordarse (nunca crece).
                Expanded(
                  child: hayExtras
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Flexible(child: _textosAjustados(context, c)),
                            const SizedBox(height: 8),
                            // Solo si una tarea trae mucho contenido extra
                            // hace falta desplazar dentro de su tarjeta.
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (mostrarPasos)
                                      _pasos(context, pasosOrdenados),
                                    if (tieneAudio) ...[
                                      const SizedBox(height: 8),
                                      ReproductorAudioWidget(
                                        url: tarea.audioUrl!,
                                      ),
                                    ],
                                    if (tieneVideo || tieneEnlace) ...[
                                      const SizedBox(height: 8),
                                      _botonesMultimedia(
                                        context,
                                        tieneVideo,
                                        tieneEnlace,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.topCenter,
                          child: _textosAjustados(context, c),
                        ),
                ),
                const SizedBox(height: 8),
                _botonHecha(context, altoBoton),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _botonHecha(BuildContext context, double alto) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: completada ? 'Marcar como pendiente' : 'Marcar como hecha',
      excludeSemantics: true,
      child: Material(
        color: completada ? p.green : p.checkEmpty,
        borderRadius: BorderRadius.circular(alto),
        child: InkWell(
          borderRadius: BorderRadius.circular(alto),
          onTap: onToggle,
          child: SizedBox(
            height: alto,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_rounded,
                  size: alto * 0.7,
                  color: completada ? Colors.white : p.surface,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// [_textos] con el ancho de la tarjeta, encogido solo si no cabe.
  Widget _textosAjustados(BuildContext context, BoxConstraints c) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.topCenter,
    child: SizedBox(width: c.maxWidth, child: _textos(context)),
  );

  /// Debajo del dibujo: nombre, descripción y la hora. En la tarea de ahora,
  /// la hora, el tiempo que queda y la barra van juntos en un recuadro.
  Widget _textos(BuildContext context) {
    final p = context.palette;
    final hora = Text(
      '${_hora(tarea.horaInicio)} - ${_hora(tarea.horaFinal)}',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: context.letra(Letra.detalle),
        fontWeight: FontWeight.w800,
        color: p.primary,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tarea.nombre,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.letra(Letra.destacado),
            fontWeight: FontWeight.w800,
            color: completada ? p.textSoft : p.textDark,
            height: 1.1,
          ),
        ),
        if (tarea.descripcion.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            tarea.descripcion,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.letra(Letra.detalle),
              color: p.textSoft,
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (actual && !completada)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: p.badge,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // La hora y, debajo, "AHORA"
                hora,
                const SizedBox(height: 4),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: p.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'AHORA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.letra(Letra.detalle) * 0.72,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                BarraProgresoTarea(tarea: tarea),
              ],
            ),
          )
        else
          hora,
      ],
    );
  }

  Widget _pasos(BuildContext context, List<Paso> pasos) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final paso in pasos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: context.medida(13),
                    backgroundColor: p.primary,
                    child: Text(
                      '${paso.orden}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.letra(Letra.detalle) * 0.75,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      paso.descripcion,
                      style: TextStyle(
                        fontSize: context.letra(Letra.detalle) * 0.9,
                        fontWeight: FontWeight.w600,
                        color: completada ? p.textSoft : p.textDark,
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

  Widget _botonesMultimedia(
    BuildContext context,
    bool tieneVideo,
    bool tieneEnlace,
  ) {
    final p = context.palette;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        if (tieneVideo)
          IconButton.filled(
            tooltip: 'Ver vídeo',
            style: IconButton.styleFrom(backgroundColor: p.primary),
            iconSize: context.medida(30),
            onPressed: () => _mostrarVideo(context, tarea.videoUrl!),
            icon: const Icon(Icons.play_circle_fill),
          ),
        if (tieneEnlace)
          IconButton.outlined(
            tooltip: 'Abrir enlace',
            iconSize: context.medida(28),
            color: p.primary,
            onPressed: () => _abrirEnlace(context, tarea.enlaceWeb!),
            icon: const Icon(Icons.open_in_new),
          ),
      ],
    );
  }
}
