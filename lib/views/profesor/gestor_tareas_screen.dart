import 'package:flutter/material.dart';
import '../../viewmodels/gestor_tareas_view_model.dart';
import 'gestor_tareas_page.dart';

class GestorTareasScreen extends StatefulWidget {
  const GestorTareasScreen({
    super.key,
    required this.viewModel,
    required this.profesorId,
  });

  final GestorTareasViewModel viewModel;
  final String profesorId;

  @override
  State<GestorTareasScreen> createState() => _GestorTareasScreenState();
}

class _GestorTareasScreenState extends State<GestorTareasScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar alumnos y tareas al iniciar la pantalla
    widget.viewModel.cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder redibuja la pantalla cada vez que el ViewModel ejecuta notifyListeners()
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        if (widget.viewModel.cargando && widget.viewModel.tareas.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return GestorTareasPage(
          profesorId: widget.profesorId,
          alumnos: widget.viewModel.alumnos,
          tareas: widget.viewModel.tareas,
          fechaSeleccionada: widget.viewModel.fechaSeleccionada,
          onGuardarTarea: (nuevaTarea, tipo, frecuencia) async {
            await widget.viewModel.crearTarea(
              nuevaTarea: nuevaTarea,
              tipo: tipo,
              frecuencia: frecuencia,
            );
          },
          onActualizarTarea: (tareaActualizada) async {
            await widget.viewModel.actualizarTarea(tareaActualizada);
          },
          onEliminarTarea: (tareaId) async {
            await widget.viewModel.eliminarTarea(tareaId);
          },

          onFechaCambiada: (nuevaFecha) async {
            await widget.viewModel.cambiarFecha(nuevaFecha);
          },          
        );
      },
    );
  }
}