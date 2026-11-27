import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Tamaños de letra uniformes de la agenda del alumno.
///
/// Solo hay cuatro niveles, pensados para una tablet de 1280x800. En pantallas
/// más grandes todo crece en proporción (hasta un 60 % más), así la pantalla
/// se aprovecha sin tener que hacer scroll.
class Letra {
  Letra._();

  static const double detalle = 22; // textos secundarios (hora, descripción)
  static const double normal = 26; // botones, etiquetas, platos del menú
  static const double destacado = 32; // nombres de tareas, títulos de sección
  static const double titulo = 38; // títulos principales

  /// Factor de escala según el tamaño de pantalla (1.0 en 1280x800).
  static double escala(BuildContext context) {
    final s = MediaQuery.sizeOf(context);
    return math.min(s.width / 1280, s.height / 800).clamp(0.8, 1.6);
  }
}

extension LetraContext on BuildContext {
  /// Tamaño [base] (uno de los de [Letra]) ajustado a la pantalla.
  double letra(double base) => base * Letra.escala(this);

  /// Medida de diseño (iconos, pictogramas, botones) ajustada a la pantalla.
  double medida(double base) => base * Letra.escala(this);
}
