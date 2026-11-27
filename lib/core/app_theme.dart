import 'package:material_ui/material_ui.dart';

/// Temas de color disponibles para el alumno (todos en tonos pastel)
enum TemaColor {
  azul('Azul'),
  verde('Verde calma'),
  morado('Morado sereno'),
  calido('Cálido suave'),
  arcoiris('Arcoíris'),
  atardecer('Atardecer'),
  oceano('Océano');

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

  /// Colores pastel para dar un color distinto a cada tarjeta (temas de
  /// varios colores, como Arcoíris). Vacío = todas con [cardTint].
  final List<Color> acentos;

  /// Color de fondo para la tarjeta número [i].
  Color acento(int i) =>
      acentos.isEmpty ? cardTint : acentos[i % acentos.length];

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
    this.acentos = const [],
  });

  // Todas las paletas son de tonos pastel: fondos suaves y un color
  // principal de intensidad media, con contraste suficiente para el texto
  // grande en blanco de los botones.

  // 1. TEMA AZUL (por defecto)
  static const azul = AppPalette(
    background: Color(0xFFF7FAFE),
    surface: Colors.white,
    primary: Color(0xFF5B97D1),
    cardTint: Color(0xFFEAF3FC),
    chip: Color(0xFFF1F7FD),
    tabTrack: Color(0xFFEEF5FC),
    badge: Color(0xFFE2EEFA),
    checkEmpty: Color(0xFFE1ECF6),
    divider: Color(0xFFE8EFF6),
    textDark: Color(0xFF243140),
    textSoft: Color(0xFF56677A),
    green: Color(0xFF5DBB7E),
    greenLight: Color(0xFFCDEFD8),
    greenDark: Color(0xFF37875A),
    greenSoft: Color(0xFFEAF8EE),
    selectedBg: Color(0xFFEEF9F1),
    orange: Color(0xFFE8A06A),
    orangeSoft: Color(0xFFFEF1E6),
    amber: Color(0xFFF6CF5A),
  );

  // 2. TEMA VERDE (calma)
  static const verde = AppPalette(
    background: Color(0xFFF6FBF8),
    surface: Colors.white,
    primary: Color(0xFF4E9E74),
    cardTint: Color(0xFFE8F6EE),
    chip: Color(0xFFF0F9F3),
    tabTrack: Color(0xFFECF7F0),
    badge: Color(0xFFDFF1E6),
    checkEmpty: Color(0xFFDCEEE3),
    divider: Color(0xFFE6F2EA),
    textDark: Color(0xFF213429),
    textSoft: Color(0xFF52695B),
    green: Color(0xFF5DBB7E),
    greenLight: Color(0xFFCDEFD8),
    greenDark: Color(0xFF37875A),
    greenSoft: Color(0xFFEAF8EE),
    selectedBg: Color(0xFFE6F6EB),
    orange: Color(0xFFE8A06A),
    orangeSoft: Color(0xFFFEF1E6),
    amber: Color(0xFFF6CF5A),
  );

  // 3. TEMA MORADO (lavanda)
  static const morado = AppPalette(
    background: Color(0xFFFAF8FD),
    surface: Colors.white,
    primary: Color(0xFF9078C8),
    cardTint: Color(0xFFF1EBFA),
    chip: Color(0xFFF6F2FC),
    tabTrack: Color(0xFFF3EEFA),
    badge: Color(0xFFEAE2F8),
    checkEmpty: Color(0xFFE6DEF4),
    divider: Color(0xFFEEE8F7),
    textDark: Color(0xFF2C223E),
    textSoft: Color(0xFF5F5473),
    green: Color(0xFF5DBB7E),
    greenLight: Color(0xFFCDEFD8),
    greenDark: Color(0xFF37875A),
    greenSoft: Color(0xFFEAF8EE),
    selectedBg: Color(0xFFF4EFFB),
    orange: Color(0xFFE8A06A),
    orangeSoft: Color(0xFFFEF1E6),
    amber: Color(0xFFF6CF5A),
  );

  // 4. TEMA CÁLIDO (crema y melocotón)
  static const calido = AppPalette(
    background: Color(0xFFFEFAF5),
    surface: Colors.white,
    primary: Color(0xFFCC8156),
    cardTint: Color(0xFFFBEFE4),
    chip: Color(0xFFFCF5EE),
    tabTrack: Color(0xFFFAF1E8),
    badge: Color(0xFFF7E7D9),
    checkEmpty: Color(0xFFF3E3D4),
    divider: Color(0xFFF5EBE1),
    textDark: Color(0xFF38291F),
    textSoft: Color(0xFF6B584A),
    green: Color(0xFF5DBB7E),
    greenLight: Color(0xFFCDEFD8),
    greenDark: Color(0xFF37875A),
    greenSoft: Color(0xFFEAF8EE),
    selectedBg: Color(0xFFFBF1E7),
    orange: Color(0xFFE0955F),
    orangeSoft: Color(0xFFFEF1E6),
    amber: Color(0xFFF6CF5A),
  );

  // 5. ARCOÍRIS: cada tarjeta de un color pastel distinto
  static const arcoiris = AppPalette(
    background: Color(0xFFFEFCF9),
    surface: Colors.white,
    primary: Color(0xFF9486D3),
    cardTint: Color(0xFFF3F0FC),
    chip: Color(0xFFF8F6FD),
    tabTrack: Color(0xFFF5F2FB),
    badge: Color(0xFFEEE9FA),
    checkEmpty: Color(0xFFE7E3F3),
    divider: Color(0xFFEFECF5),
    textDark: Color(0xFF2B283D),
    textSoft: Color(0xFF5E5975),
    green: Color(0xFF5DBB7E),
    greenLight: Color(0xFFCDEFD8),
    greenDark: Color(0xFF37875A),
    greenSoft: Color(0xFFEAF8EE),
    selectedBg: Color(0xFFF5F2FC),
    orange: Color(0xFFE8A06A),
    orangeSoft: Color(0xFFFEF1E6),
    amber: Color(0xFFF6CF5A),
    acentos: [
      Color(0xFFFFEBF0), // rosa
      Color(0xFFFFF1E2), // melocotón
      Color(0xFFFFF9DC), // amarillo
      Color(0xFFE8F8EF), // menta
      Color(0xFFE7F3FD), // cielo
      Color(0xFFF2ECFB), // lila
    ],
  );

  // 6. ATARDECER: rosas, melocotón y lila
  static const atardecer = AppPalette(
    background: Color(0xFFFEFAF9),
    surface: Colors.white,
    primary: Color(0xFFD07A8F),
    cardTint: Color(0xFFFCEEF1),
    chip: Color(0xFFFDF5F6),
    tabTrack: Color(0xFFFCF1F3),
    badge: Color(0xFFFAE6EA),
    checkEmpty: Color(0xFFF5E2E6),
    divider: Color(0xFFF7ECEE),
    textDark: Color(0xFF3A2830),
    textSoft: Color(0xFF6F5660),
    green: Color(0xFF5DBB7E),
    greenLight: Color(0xFFCDEFD8),
    greenDark: Color(0xFF37875A),
    greenSoft: Color(0xFFEAF8EE),
    selectedBg: Color(0xFFFDF3F5),
    orange: Color(0xFFE8A06A),
    orangeSoft: Color(0xFFFEF1E6),
    amber: Color(0xFFF6CF5A),
    acentos: [
      Color(0xFFFFEBEF), // rosa
      Color(0xFFFFF0E6), // melocotón
      Color(0xFFFFF7E3), // vainilla
      Color(0xFFF8EDF8), // lila
    ],
  );

  // 7. OCÉANO: aguamarina, azul y menta
  static const oceano = AppPalette(
    background: Color(0xFFF6FBFC),
    surface: Colors.white,
    primary: Color(0xFF4A9DAE),
    cardTint: Color(0xFFE7F5F7),
    chip: Color(0xFFF0F9FA),
    tabTrack: Color(0xFFEBF6F8),
    badge: Color(0xFFDFF1F4),
    checkEmpty: Color(0xFFDCEDF0),
    divider: Color(0xFFE5F1F3),
    textDark: Color(0xFF1F3338),
    textSoft: Color(0xFF4E666C),
    green: Color(0xFF5DBB7E),
    greenLight: Color(0xFFCDEFD8),
    greenDark: Color(0xFF37875A),
    greenSoft: Color(0xFFEAF8EE),
    selectedBg: Color(0xFFEAF8F6),
    orange: Color(0xFFE8A06A),
    orangeSoft: Color(0xFFFEF1E6),
    amber: Color(0xFFF6CF5A),
    acentos: [
      Color(0xFFE4F7F9), // aguamarina
      Color(0xFFE7F1FD), // azul cielo
      Color(0xFFE9F8F0), // menta
      Color(0xFFEEEEFC), // lavanda
    ],
  );

  /// Paleta de cada tema.
  static AppPalette paraTema(TemaColor tema) => switch (tema) {
    TemaColor.azul => azul,
    TemaColor.verde => verde,
    TemaColor.morado => morado,
    TemaColor.calido => calido,
    TemaColor.arcoiris => arcoiris,
    TemaColor.atardecer => atardecer,
    TemaColor.oceano => oceano,
  };

  // MODO ALTO CONTRASTE (Máxima legibilidad WCAG AAA)
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
    List<Color>? acentos,
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
      acentos: acentos ?? this.acentos,
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
      acentos: t < 0.5 ? acentos : other.acentos,
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
        : AppPalette.paraTema(tema);

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
              ? BorderSide(
                  color: palette.borderColor,
                  width: palette.borderWidth,
                )
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
