import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../viewmodels/theme_view_model.dart';

/// Ajustes de aspecto (colores y contraste) en un panel inferior.
/// Se abre desde el botón de Ajustes de la barra superior.
Future<void> mostrarAjustesTema(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const Padding(
      padding: EdgeInsets.all(16.0),
      child: SelectorTemaWidget(),
    ),
  );
}

class SelectorTemaWidget extends StatelessWidget {
  const SelectorTemaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha los cambios del ViewModel
    final themeVM = context.watch<ThemeViewModel>();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personalizar aspecto',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Selector de círculos de colores
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: TemaColor.values.map((tema) {
                final isSelected = themeVM.temaActual == tema;
                return GestureDetector(
                  onTap: () => context.read<ThemeViewModel>().cambiarTema(tema),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: isSelected ? 3.0 : 0.0,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: _getColorForTema(tema),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(),
            ),

            // Interruptor de Alto Contraste
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Modo Alto Contraste',
                style: TextStyle(
                  color: context
                      .palette
                      .textDark, // Usando la extensión de app_theme.dart
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Mejora la lectura con bordes oscuros',
                style: TextStyle(color: context.palette.textSoft),
              ),
              value: themeVM.altoContraste,
              activeThumbColor: context.palette.primary,
              onChanged: (value) =>
                  context.read<ThemeViewModel>().toggleAltoContraste(value),
            ),
          ],
        ),
      ),
    );
  }

  // Extrae el color principal de cada paleta para pintar los círculos
  Color _getColorForTema(TemaColor tema) {
    switch (tema) {
      case TemaColor.azul:
        return AppPalette.azul.primary;
      case TemaColor.verde:
        return AppPalette.verde.primary;
      case TemaColor.morado:
        return AppPalette.morado.primary;
      case TemaColor.calido:
        return AppPalette.calido.primary;
    }
  }
}
