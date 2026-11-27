import 'package:material_ui/material_ui.dart';

/// HU 06: avatares de animales para el perfil (como en las webs de juegos).
/// Se guardan en `fotoUrl` como `avatar:<id>`, así no hace falta subir nada.
class AvatarAnimal {
  const AvatarAnimal(this.id, this.nombre, this.dibujo, this.fondo);

  final String id;
  final String nombre;
  final String dibujo; // emoji del animal
  final Color fondo;

  static const prefijo = 'avatar:';

  String get valor => '$prefijo$id';

  static const todos = [
    AvatarAnimal('perro', 'Perro', '🐶', Color(0xFFFFE0B2)),
    AvatarAnimal('gato', 'Gato', '🐱', Color(0xFFFFF59D)),
    AvatarAnimal('conejo', 'Conejo', '🐰', Color(0xFFF8BBD0)),
    AvatarAnimal('oso', 'Oso', '🐻', Color(0xFFD7CCC8)),
    AvatarAnimal('panda', 'Panda', '🐼', Color(0xFFC8E6C9)),
    AvatarAnimal('zorro', 'Zorro', '🦊', Color(0xFFFFCCBC)),
    AvatarAnimal('koala', 'Koala', '🐨', Color(0xFFCFD8DC)),
    AvatarAnimal('leon', 'León', '🦁', Color(0xFFFFECB3)),
    AvatarAnimal('rana', 'Rana', '🐸', Color(0xFFDCEDC8)),
    AvatarAnimal('mono', 'Mono', '🐵', Color(0xFFFFE0B2)),
    AvatarAnimal('pinguino', 'Pingüino', '🐧', Color(0xFFB3E5FC)),
    AvatarAnimal('unicornio', 'Unicornio', '🦄', Color(0xFFE1BEE7)),
  ];

  /// Devuelve el avatar guardado en [fotoUrl], o null si es una foto normal.
  static AvatarAnimal? desde(String? fotoUrl) {
    if (fotoUrl == null || !fotoUrl.startsWith(prefijo)) return null;
    final id = fotoUrl.substring(prefijo.length);
    for (final a in todos) {
      if (a.id == id) return a;
    }
    return null;
  }
}
