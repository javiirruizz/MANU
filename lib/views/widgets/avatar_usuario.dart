import 'package:material_ui/material_ui.dart';

import '../../core/app_theme.dart';

/// Foto de perfil redonda. Si no hay foto, muestra la inicial del nombre.
/// Se usa en todas las vistas para que un cambio de foto se vea en todas (HU 06).
class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario({
    super.key,
    required this.nombre,
    this.fotoUrl,
    this.size = 48,
  });

  final String nombre;
  final String? fotoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final inicial = nombre.trim().isEmpty ? '?' : nombre.trim()[0].toUpperCase();
    final letra = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.palette.badge,
        shape: BoxShape.circle,
      ),
      child: Text(
        inicial,
        style: TextStyle(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w800,
          color: context.palette.primary,
        ),
      ),
    );

    final url = fotoUrl;
    if (url == null || url.isEmpty) return letra;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: context.palette.divider, width: 1.5),
      ),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => letra,
      ),
    );
  }
}
