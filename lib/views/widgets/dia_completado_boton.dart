import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/tamanos.dart';
import '../../viewmodels/agenda_view_model.dart';
import 'valoracion_dialog.dart';

/// Botón de fin de día: abre la ventana de satisfacción (emoción + estrellas).
/// Sustituye al antiguo cuadro "¿Cómo me siento?".
class DiaCompletadoBoton extends StatelessWidget {
  const DiaCompletadoBoton({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgendaViewModel>();
    final p = context.palette;
    final hecho = vm.dayCompleted;

    return FilledButton.icon(
      onPressed: () => mostrarValoracionDia(context, vm: vm),
      icon: Icon(
        hecho ? Icons.check_circle : Icons.check_circle_outline,
        size: context.medida(34),
      ),
      label: Text(
        hecho ? '¡DÍA COMPLETADO! ✓' : '¡DÍA COMPLETADO!',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: context.letra(Letra.normal),
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: hecho ? p.green : p.primary,
        foregroundColor: Colors.white,
        minimumSize: Size.fromHeight(context.medida(84)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
