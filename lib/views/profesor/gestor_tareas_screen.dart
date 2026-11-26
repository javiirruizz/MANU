import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/usuario.dart';
import '../../viewmodels/auth_view_model.dart';
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
  AuthViewModel? _leerAuth(BuildContext context, {bool listen = false}) {
    try {
      return Provider.of<AuthViewModel>(context, listen: listen);
    } on ProviderNotFoundException {
      return null;
    }
  }

  bool _tieneAcceso(AuthViewModel? auth) {
    if (auth == null) return true;
    final user = auth.usuario;
    if (user == null) return false;
    if (user.rol == RolUsuario.alumno || user.rol == RolUsuario.familiar) {
      return false;
    }
    return user.tienePermiso(PermisoUsuario.gestionarTareas);
  }

  @override
  void initState() {
    super.initState();
    if (_tieneAcceso(_leerAuth(context, listen: false))) {
      // Cargar alumnos y tareas al iniciar la pantalla
      widget.viewModel.cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = _leerAuth(context, listen: true);
    if (!_tieneAcceso(auth)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Planificar tareas')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Acceso denegado: la planificación de tareas es exclusiva para el profesorado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }

    // ListenableBuilder redibuja la pantalla cada vez que el ViewModel ejecuta notifyListeners()
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        if (widget.viewModel.cargando &&
            widget.viewModel.tareas.isEmpty &&
            !widget.viewModel.subiendoMultimedia) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return GestorTareasPage(
          profesorId: widget.profesorId,
          alumnos: widget.viewModel.alumnos,
          tareas: widget.viewModel.tareas,
          fechaSeleccionada: widget.viewModel.fechaSeleccionada,
          subiendoMultimedia: widget.viewModel.subiendoMultimedia,
          onSubirVideo: () => widget.viewModel.subirVideo(),
          onSubirAudio: () => widget.viewModel.subirAudio(),
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
