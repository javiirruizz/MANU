import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/tamanos.dart';
import '../../viewmodels/theme_view_model.dart';

/// Ajustes de aspecto (colores y contraste) en un panel inferior.
/// Se abre desde "Mi espacio" → Colores.
Future<void> mostrarAjustesTema(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const Padding(
      padding: EdgeInsets.all(20.0),
      child: SelectorTemaWidget(),
    ),
  );
}

/// Elegir el estilo de colores (todos pastel) y el modo de alto contraste.
class SelectorTemaWidget extends StatelessWidget {
  const SelectorTemaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final p = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Elige tus colores',
          style: TextStyle(
            fontSize: context.letra(Letra.destacado),
            fontWeight: FontWeight.w800,
            color: p.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final tema in TemaColor.values)
              _TarjetaTema(
                tema: tema,
                elegido: !themeVM.altoContraste && themeVM.temaActual == tema,
                onTap: () {
                  final vm = context.read<ThemeViewModel>();
                  vm.toggleAltoContraste(false);
                  vm.cambiarTema(tema);
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(color: p.divider),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Alto contraste',
            style: TextStyle(
              color: p.textDark,
              fontSize: context.letra(Letra.normal),
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            'Colores fuertes y bordes negros para ver mejor',
            style: TextStyle(
              color: p.textSoft,
              fontSize: context.letra(Letra.detalle),
            ),
          ),
          value: themeVM.altoContraste,
          activeThumbColor: p.primary,
          onChanged: (value) =>
              context.read<ThemeViewModel>().toggleAltoContraste(value),
        ),
      ],
    );
  }
}

/// Tarjeta de un estilo: solo sus colores (el nombre queda para el lector
/// de pantalla).
class _TarjetaTema extends StatelessWidget {
  const _TarjetaTema({
    required this.tema,
    required this.elegido,
    required this.onTap,
  });

  final TemaColor tema;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final paleta = AppPalette.paraTema(tema);
    final colores = paleta.acentos.isNotEmpty
        ? paleta.acentos
        : [paleta.cardTint, paleta.badge, paleta.tabTrack];
    final ancho = context.medida(150);

    return Semantics(
      button: true,
      selected: elegido,
      label: 'Estilo ${tema.nombre}',
      excludeSemantics: true,
      child: Material(
        color: paleta.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: elegido ? paleta.primary : paleta.divider,
            width: elegido ? 4 : 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: SizedBox(
            width: ancho,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Muestra de colores: el principal y los pastel
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: context.medida(70),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              color: paleta.primary,
                              child: elegido
                                  ? Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: context.medida(30),
                                    )
                                  : null,
                            ),
                          ),
                          for (final c in colores)
                            Expanded(child: Container(color: c)),
                        ],
                      ),
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
