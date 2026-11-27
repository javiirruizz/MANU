import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/tamanos.dart';
import '../../data/notificacion_repository.dart';
import '../../models/notificacion.dart';
import '../../models/usuario.dart';
import '../../viewmodels/auth_view_model.dart';
import '../notificaciones_page.dart';
import 'avatar_usuario.dart';
import 'confirmar_salida.dart';
import 'perfil_dialog.dart';
import 'selector_tema_widget.dart';

/// Botón de la barra superior: avatar y nombre del alumno, con un globito
/// rojo si tiene avisos sin leer. Al pulsarlo se abre "Mi espacio", donde
/// están juntos el avatar, los avisos, los colores, los datos y salir.
class BotonPerfil extends StatelessWidget {
  const BotonPerfil({super.key, required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final esAlumno = usuario.rol == RolUsuario.alumno;
    final nombre = usuario.nombre.trim().split(' ').first;

    Widget boton(int sinLeer) => Semantics(
      button: true,
      label: sinLeer > 0
          ? 'Mi espacio. Tienes $sinLeer avisos sin leer'
          : 'Mi espacio',
      excludeSemantics: true,
      child: Material(
        color: p.tabTrack,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: () => mostrarMenuPerfil(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 18, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AvatarUsuario(
                      nombre: usuario.nombre,
                      fotoUrl: usuario.fotoUrl,
                      size: context.medida(52),
                    ),
                    if (sinLeer > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: _Globito(numero: sinLeer),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Text(
                  nombre,
                  style: TextStyle(
                    fontSize: context.letra(Letra.normal),
                    fontWeight: FontWeight.w800,
                    color: p.textDark,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.expand_more,
                  color: p.textSoft,
                  size: context.medida(28),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!esAlumno) return boton(0);
    return StreamBuilder<List<Notificacion>>(
      stream: NotificacionService().watchNotificacionesAlumno(usuario.id),
      builder: (context, snap) => boton(
        (snap.data ?? []).where((n) => !n.estaLeidaPor(usuario.id)).length,
      ),
    );
  }
}

class _Globito extends StatelessWidget {
  const _Globito({required this.numero});

  final int numero;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        '$numero',
        style: TextStyle(
          color: Colors.white,
          fontSize: context.letra(Letra.detalle) * 0.75,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// "Mi espacio": todas las opciones personales en un mismo sitio.
Future<void> mostrarMenuPerfil(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _MenuPerfil(),
  );
}

class _MenuPerfil extends StatelessWidget {
  const _MenuPerfil();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final usuario = context.watch<AuthViewModel>().usuario;
    if (usuario == null) return const SizedBox.shrink();
    final esAlumno = usuario.rol == RolUsuario.alumno;

    // Cierra este menú y abre la opción elegida
    void abrir(Future<void> Function(BuildContext) accion) {
      final ctx = Navigator.of(context).context;
      Navigator.of(context).pop();
      accion(ctx);
    }

    final opciones = <_Opcion>[
      _Opcion(
        icono: Icons.face_retouching_natural,
        texto: 'Mi avatar',
        color: const Color(0xFFFFE0B2),
        onTap: () => abrir(mostrarPerfil),
      ),
      if (esAlumno)
        _Opcion(
          icono: Icons.notifications_active_outlined,
          texto: 'Mis avisos',
          color: const Color(0xFFFFF59D),
          onTap: () => abrir(
            (c) => Navigator.of(c).push(
              MaterialPageRoute(
                builder: (_) => NotificacionesPage(alumno: usuario),
              ),
            ),
          ),
        ),
      _Opcion(
        icono: Icons.palette_outlined,
        texto: 'Colores',
        color: const Color(0xFFE1BEE7),
        onTap: () => abrir(mostrarAjustesTema),
      ),
      _Opcion(
        icono: Icons.badge_outlined,
        texto: 'Mis datos',
        color: const Color(0xFFC8E6C9),
        onTap: () => abrir(mostrarMisDatos),
      ),
      _Opcion(
        icono: Icons.logout,
        texto: 'Salir',
        color: const Color(0xFFFFCDD2),
        onTap: () => abrir(confirmarCerrarSesion),
      ),
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.medida(720)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AvatarUsuario(
                    nombre: usuario.nombre,
                    fotoUrl: usuario.fotoUrl,
                    size: context.medida(84),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mi espacio',
                          style: TextStyle(
                            fontSize: context.letra(Letra.detalle),
                            color: p.textSoft,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          usuario.nombre,
                          style: TextStyle(
                            fontSize: context.letra(Letra.destacado),
                            fontWeight: FontWeight.w800,
                            color: p.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    iconSize: context.medida(36),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: p.textSoft),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 14,
                children: [for (final o in opciones) _BotonOpcion(opcion: o)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Opcion {
  const _Opcion({
    required this.icono,
    required this.texto,
    required this.color,
    required this.onTap,
  });

  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback onTap;
}

/// Botón grande y cuadrado: dibujo arriba, palabra debajo.
class _BotonOpcion extends StatelessWidget {
  const _BotonOpcion({required this.opcion});

  final _Opcion opcion;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lado = context.medida(150);
    return Semantics(
      button: true,
      label: opcion.texto,
      excludeSemantics: true,
      child: Material(
        color: p.cardTint,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: opcion.onTap,
          child: SizedBox(
            width: lado,
            height: lado,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: lado * 0.5,
                  height: lado * 0.5,
                  decoration: BoxDecoration(
                    color: opcion.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    opcion.icono,
                    size: lado * 0.28,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  opcion.texto,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.letra(Letra.normal),
                    fontWeight: FontWeight.w800,
                    color: p.textDark,
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

/// "Mis datos": información básica del usuario, solo para ver.
Future<void> mostrarMisDatos(BuildContext context) {
  final usuario = context.read<AuthViewModel>().usuario;
  if (usuario == null) return Future.value();
  final p = context.palette;
  final nac = usuario.fechaNacimiento;

  final filas = <(IconData, String, String)>[
    (Icons.person_outline, 'Me llamo', usuario.nombre),
    (Icons.account_circle_outlined, 'Mi usuario', usuario.nombreUsuario),
    if (nac != null)
      (
        Icons.cake_outlined,
        'Mi cumpleaños',
        '${nac.day}/${nac.month}/${nac.year}',
      ),
    if ((usuario.telefonoContacto ?? '').isNotEmpty)
      (Icons.phone_outlined, 'Teléfono de casa', usuario.telefonoContacto!),
    if ((usuario.email ?? '').isNotEmpty)
      (Icons.mail_outline, 'Correo', usuario.email!),
  ];

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.badge_outlined, color: p.primary, size: ctx.medida(36)),
          const SizedBox(width: 10),
          Text(
            'Mis datos',
            style: TextStyle(
              fontSize: ctx.letra(Letra.destacado),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: ctx.medida(520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (icono, etiqueta, valor) in filas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(icono, color: p.primary, size: ctx.medida(30)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            etiqueta,
                            style: TextStyle(
                              fontSize: ctx.letra(Letra.detalle),
                              color: p.textSoft,
                            ),
                          ),
                          Text(
                            valor,
                            style: TextStyle(
                              fontSize: ctx.letra(Letra.normal),
                              fontWeight: FontWeight.w800,
                              color: p.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'Vale',
            style: TextStyle(fontSize: ctx.letra(Letra.normal)),
          ),
        ),
      ],
    ),
  );
}
