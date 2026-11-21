import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Temas de color disponibles para el alumno
enum TemaColor {
  azul('Azul (Por defecto)'),
  verde('Verde calma'),
  morado('Morado sereno'),
  calido('Cálido suave');

  final String nombre;
  const TemaColor(this.nombre);
}

/// Extensión de tema que replica la estructura de AppColors para cada paleta
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color primary;
  final Color cardTint; // Equivalente a cardBlue en el tema base
  final Color chip;
  final Color tabTrack;
  final Color badge;
  final Color checkEmpty;
  final Color divider;

  final Color textDark;
  final Color textSoft;

  final Color green;
  final Color greenLight;
  final Color greenDark;
  final Color greenSoft;
  final Color selectedBg;

  final Color orange;
  final Color orangeSoft;
  final Color amber;

  // Propiedades extra para reforzar bordes en alto contraste
  final Color borderColor;
  final double borderWidth;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.primary,
    required this.cardTint,
    required this.chip,
    required this.tabTrack,
    required this.badge,
    required this.checkEmpty,
    required this.divider,
    required this.textDark,
    required this.textSoft,
    required this.green,
    required this.greenLight,
    required this.greenDark,
    required this.greenSoft,
    required this.selectedBg,
    required this.orange,
    required this.orangeSoft,
    required this.amber,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0.0,
  });

  // 1. TEMA AZUL (Paleta original de AppColors)
  static const azul = AppPalette(
    background: AppColors.background,
    surface: AppColors.surface,
    primary: AppColors.primary,
    cardTint: AppColors.cardBlue,
    chip: AppColors.chip,
    tabTrack: AppColors.tabTrack,
    badge: AppColors.badge,
    checkEmpty: AppColors.checkEmpty,
    divider: AppColors.divider,
    textDark: AppColors.textDark,
    textSoft: AppColors.textSoft,
    green: AppColors.green,
    greenLight: AppColors.greenLight,
    greenDark: AppColors.greenDark,
    greenSoft: AppColors.greenSoft,
    selectedBg: AppColors.selectedBg,
    orange: AppColors.orange,
    orangeSoft: AppColors.orangeSoft,
    amber: AppColors.amber,
  );

  // 2. TEMA VERDE (Naturaleza / Calma)
  static const verde = AppPalette(
    background: Color(0xFFF2F7F4),
    surface: Colors.white,
    primary: Color(0xFF1B6E3A),
    cardTint: Color(0xFFDFEFE5),
    chip: Color(0xFFEAF3ED),
    tabTrack: Color(0xFFE3EFE8),
    badge: Color(0xFFCDE5D6),
    checkEmpty: Color(0xFFC5DFCE),
    divider: Color(0xFFDCE8E0),
    textDark: Color(0xFF16291E),
    textSoft: Color(0xFF435B4D),
    green: AppColors.green,
    greenLight: AppColors.greenLight,
    greenDark: AppColors.greenDark,
    greenSoft: AppColors.greenSoft,
    selectedBg: Color(0xFFD9F2E1),
    orange: AppColors.orange,
    orangeSoft: AppColors.orangeSoft,
    amber: AppColors.amber,
  );

  // 3. TEMA MORADO (Lavanda / Sereno)
  static const morado = AppPalette(
    background: Color(0xFFF5F3F8),
    surface: Colors.white,
    primary: Color(0xFF5B359C),
    cardTint: Color(0xFFE8E1F5),
    chip: Color(0xFFF0ECF7),
    tabTrack: Color(0xFFE9E4F3),
    badge: Color(0xFFDAD0EE),
    checkEmpty: Color(0xFFD2C7E8),
    divider: Color(0xFFE3DDF0),
    textDark: Color(0xFF211833),
    textSoft: Color(0xFF524766),
    green: AppColors.green,
    greenLight: AppColors.greenLight,
    greenDark: AppColors.greenDark,
    greenSoft: AppColors.greenSoft,
    selectedBg: Color(0xFFEDE7F8),
    orange: AppColors.orange,
    orangeSoft: AppColors.orangeSoft,
    amber: AppColors.amber,
  );

  // 4. TEMA CÁLIDO (Crema suave / Reduce fatiga de luz azul)
  static const calido = AppPalette(
    background: Color(0xFFF8F5F0),
    surface: Color(0xFFFFFDF9),
    primary: Color(0xFFA84A10),
    cardTint: Color(0xFFF3E6D8),
    chip: Color(0xFFF5EDE3),
    tabTrack: Color(0xFFEFE5D9),
    badge: Color(0xFFEBD7C3),
    checkEmpty: Color(0xFFE3CCB5),
    divider: Color(0xFFE8DDD0),
    textDark: Color(0xFF2E2118),
    textSoft: Color(0xFF614E40),
    green: AppColors.green,
    greenLight: AppColors.greenLight,
    greenDark: AppColors.greenDark,
    greenSoft: AppColors.greenSoft,
    selectedBg: Color(0xFFF5E6D3),
    orange: Color(0xFFD46A1E),
    orangeSoft: AppColors.orangeSoft,
    amber: AppColors.amber,
  );

  // 5. MODO ALTO CONTRASTE (Máxima legibilidad WCAG AAA)
  static const altoContraste = AppPalette(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF002B5C), // Azul marino muy oscuro (>14:1 contraste)
    cardTint: Color(0xFFF0F4F8),
    chip: Color(0xFFFFFFFF),
    tabTrack: Color(0xFFE6ECF2),
    badge: Color(0xFFFFEB3B), // Amarillo vivo con texto negro
    checkEmpty: Color(0xFF000000),
    divider: Color(0xFF000000),
    textDark: Color(0xFF000000), // Negro puro
    textSoft: Color(0xFF000000), // Sin grises tenues en alto contraste
    green: Color(0xFF005A1E),
    greenLight: Color(0xFF81C784),
    greenDark: Color(0xFF003D14),
    greenSoft: Color(0xFFD8F3DC),
    selectedBg: Color(0xFFFFF59D),
    orange: Color(0xFF8F3900),
    orangeSoft: Color(0xFFFFE0B2),
    amber: Color(0xFFFFD600),
    borderColor: Color(0xFF000000),
    borderWidth: 2.0,
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? primary,
    Color? cardTint,
    Color? chip,
    Color? tabTrack,
    Color? badge,
    Color? checkEmpty,
    Color? divider,
    Color? textDark,
    Color? textSoft,
    Color? green,
    Color? greenLight,
    Color? greenDark,
    Color? greenSoft,
    Color? selectedBg,
    Color? orange,
    Color? orangeSoft,
    Color? amber,
    Color? borderColor,
    double? borderWidth,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      primary: primary ?? this.primary,
      cardTint: cardTint ?? this.cardTint,
      chip: chip ?? this.chip,
      tabTrack: tabTrack ?? this.tabTrack,
      badge: badge ?? this.badge,
      checkEmpty: checkEmpty ?? this.checkEmpty,
      divider: divider ?? this.divider,
      textDark: textDark ?? this.textDark,
      textSoft: textSoft ?? this.textSoft,
      green: green ?? this.green,
      greenLight: greenLight ?? this.greenLight,
      greenDark: greenDark ?? this.greenDark,
      greenSoft: greenSoft ?? this.greenSoft,
      selectedBg: selectedBg ?? this.selectedBg,
      orange: orange ?? this.orange,
      orangeSoft: orangeSoft ?? this.orangeSoft,
      amber: amber ?? this.amber,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      cardTint: Color.lerp(cardTint, other.cardTint, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      tabTrack: Color.lerp(tabTrack, other.tabTrack, t)!,
      badge: Color.lerp(badge, other.badge, t)!,
      checkEmpty: Color.lerp(checkEmpty, other.checkEmpty, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textDark: Color.lerp(textDark, other.textDark, t)!,
      textSoft: Color.lerp(textSoft, other.textSoft, t)!,
      green: Color.lerp(green, other.green, t)!,
      greenLight: Color.lerp(greenLight, other.greenLight, t)!,
      greenDark: Color.lerp(greenDark, other.greenDark, t)!,
      greenSoft: Color.lerp(greenSoft, other.greenSoft, t)!,
      selectedBg: Color.lerp(selectedBg, other.selectedBg, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      orangeSoft: Color.lerp(orangeSoft, other.orangeSoft, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      borderWidth: t < 0.5 ? borderWidth : other.borderWidth,
    );
  }
}

/// Generador del ThemeData completo de la aplicación
class AppTheme {
  AppTheme._();

  /// Mantiene compatibilidad con main.dart hasta que conectemos el ViewModel
  static ThemeData get light => build(tema: TemaColor.azul);

  static ThemeData build({
    required TemaColor tema,
    bool altoContraste = false,
  }) {
    final AppPalette palette = altoContraste
        ? AppPalette.altoContraste
        : switch (tema) {
            TemaColor.azul => AppPalette.azul,
            TemaColor.verde => AppPalette.verde,
            TemaColor.morado => AppPalette.morado,
            TemaColor.calido => AppPalette.calido,
          };

    final colorScheme = ColorScheme.light(
      primary: palette.primary,
      onPrimary: Colors.white,
      secondary: palette.green,
      onSecondary: Colors.white,
      surface: palette.surface,
      onSurface: palette.textDark,
      error: const Color(0xFFB00020),
      onError: Colors.white,
      outline: altoContraste ? Colors.black : palette.divider,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      dividerColor: palette.divider,
      extensions: [palette],

      // Estilo global de tarjetas (añade borde negro grueso en alto contraste)
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: altoContraste ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: altoContraste
              ? BorderSide(color: palette.borderColor, width: palette.borderWidth)
              : BorderSide.none,
        ),
      ),

      // Estilo global de botones principales
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          textStyle: TextStyle(
            fontWeight: altoContraste ? FontWeight.w800 : FontWeight.w600,
          ),
          side: altoContraste
              ? const BorderSide(color: Colors.black, width: 2)
              : BorderSide.none,
        ),
      ),

      // Tipografía adaptada
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: palette.textDark,
          fontWeight: altoContraste ? FontWeight.w600 : FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: palette.textDark,
          fontWeight: altoContraste ? FontWeight.w500 : FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: palette.textSoft,
          fontWeight: altoContraste ? FontWeight.w600 : FontWeight.normal,
        ),
        titleMedium: TextStyle(
          color: palette.textDark,
          fontWeight: altoContraste ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}

/// Extensión de BuildContext para acceder rápido desde cualquier widget
extension AppThemeContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.azul;
}