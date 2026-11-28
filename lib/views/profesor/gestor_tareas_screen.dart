import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/menu_repository.dart';
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
  bool _tieneAcceso(Usuario? user) {
    if (user == null) return false;
    if (user.rol == RolUsuario.alumno || user.rol == RolUsuario.familiar) {
      return false;
    }
    return user.tienePermiso(PermisoUsuario.gestionarTareas);
  }

  final _menuRepo = MenuRepository();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().usuario;
    if (_tieneAcceso(user)) {
      // Cargar alumnos y tareas al iniciar la pantalla
      widget.viewModel.cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = context.watch<AuthViewModel>().usuario;

    if (!_tieneAcceso(user)) {
      return Scaffold(
        backgroundColor: p.background,
        appBar: AppBar(
          title: Text(
            'Planificar tareas',
            style: TextStyle(color: p.primary, fontWeight: FontWeight.w800),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 64, color: p.orange),
                      const SizedBox(height: 16),
                      Text(
                        'Acceso denegado',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: p.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'La planificación de tareas es exclusiva para el profesorado.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 19, color: p.textSoft),
                      ),
                    ],
                  ),
                ),
              ),
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
          return Scaffold(
            backgroundColor: p.background,
            body: Center(child: CircularProgressIndicator(color: p.primary)),
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
          onObtenerMenusSemana: (comedorId, lunes) => _menuRepo.getMenus(
            comedorId,
            desde: lunes,
            hasta: lunes.add(const Duration(days: 7)),
          ),
        );
      },
    );
  }
}
