import 'package:flutter/foundation.dart';

import '../data/tarea_repository.dart';
import '../data/usuario_repository.dart';
import '../data/storage_repositoty.dart';
import '../models/tarea.dart';
import '../models/usuario.dart';
import '../views/profesor/gestor_tareas_page.dart';

class GestorTareasViewModel extends ChangeNotifier {
  final TareaRepository _tareaRepo;
  final StorageRepository _storageRepo = StorageRepository();
  final UsuarioRepository _usuarioRepo;

  GestorTareasViewModel({
    required TareaRepository tareaRepo,
    required UsuarioRepository usuarioRepo,
  })  : _tareaRepo = tareaRepo,
        _usuarioRepo = usuarioRepo;

  List<Usuario> _alumnos = [];
  List<Tarea> _tareas = [];
  DateTime _fechaSeleccionada = DateTime.now();
  bool _cargando = false;
  bool _subiendoMultimedia = false;

  List<Usuario> get alumnos => _alumnos;
  List<Tarea> get tareas => _tareas;
  DateTime get fechaSeleccionada => _fechaSeleccionada;
  bool get cargando => _cargando;
  bool get subiendoMultimedia => _subiendoMultimedia;

  void _actualizarIUCargando() {
    _cargando = true;
    notifyListeners();
  }

  void _actualizarIUTieneInformacion() {
    _cargando = false;
    notifyListeners();
  }

  void _actualizarIUSubiendoMultimedia(bool estado) {
    _subiendoMultimedia = estado;
    notifyListeners();
  }

  Future<void> adjuntarVideoATarea(String tareaId) async {
    _actualizarIUSubiendoMultimedia(true);
    try {
      String? url = await _storageRepo.seleccionarYSubirVideo();
      if (url != null) {
        await _tareaRepo.actualizarRecursosMultimedia(tareaId, videoUrl: url);
        // Recargamos la lista para que la interfaz muestre el cambio de inmediato
        _tareas = await _tareaRepo.getTareasPorFecha(_fechaSeleccionada); 
      }
    } catch (e) {
      debugPrint("Error al adjuntar vídeo: $e");
    } finally {
      _actualizarIUSubiendoMultimedia(false);
    }
  }

  Future<void> adjuntarAudioATarea(String tareaId) async {
    _actualizarIUSubiendoMultimedia(true);
    try {
      String? url = await _storageRepo.seleccionarYSubirAudio();
      if (url != null) {
        await _tareaRepo.actualizarRecursosMultimedia(tareaId, audioUrl: url);
        _tareas = await _tareaRepo.getTareasPorFecha(_fechaSeleccionada);
      }
    } catch (e) {
      debugPrint("Error al adjuntar audio: $e");
    } finally {
      _actualizarIUSubiendoMultimedia(false);
    }
  }

  Future<void> adjuntarEnlaceWeb(String tareaId, String url) async {
    _actualizarIUSubiendoMultimedia(true);
    try {
      await _tareaRepo.actualizarRecursosMultimedia(tareaId, enlaceWeb: url);
      _tareas = await _tareaRepo.getTareasPorFecha(_fechaSeleccionada);
    } catch (e) {
      debugPrint("Error al adjuntar enlace: $e");
    } finally {
      _actualizarIUSubiendoMultimedia(false);
    }
  }

  Future<void> cargarDatos() async {
    _actualizarIUCargando();

    final resultados = await Future.wait<dynamic>([
      _usuarioRepo.getAlumnos(),
      _tareaRepo.getTareasPorFecha(_fechaSeleccionada),
    ]);

    _alumnos = resultados[0] as List<Usuario>;
    _tareas = resultados[1] as List<Tarea>;

    _actualizarIUTieneInformacion();
  }

  Future<void> cambiarFecha(DateTime nuevaFecha) async {
    _fechaSeleccionada = nuevaFecha;
    _actualizarIUCargando();

    _tareas = await _tareaRepo.getTareasPorFecha(nuevaFecha);
    _actualizarIUTieneInformacion();
  }

  Future<bool> crearTarea({
    required Tarea nuevaTarea,
    required TipoAsignacion tipo,
    FrecuenciaRecurrencia? frecuencia,
  }) async {
    try {
      _actualizarIUCargando();

      if (tipo == TipoAsignacion.recurrente && frecuencia != null) {
        final tareasRecurrentes = _generarRecurrencias(nuevaTarea, frecuencia);
        await _tareaRepo.guardarTareasBatch(tareasRecurrentes);
      } else {
        await _tareaRepo.guardarTarea(nuevaTarea);
      }

      _tareas = await _tareaRepo.getTareasPorFecha(_fechaSeleccionada);
      return true;
    } catch (e) {
      return false;
    } finally {
      _actualizarIUTieneInformacion();
    }
  }

  Future<bool> actualizarTarea(Tarea tarea) async {
    try {
      _actualizarIUCargando();
      await _tareaRepo.actualizarTarea(tarea);
      _tareas = await _tareaRepo.getTareasPorFecha(_fechaSeleccionada);
      return true;
    } catch (e) {
      return false;
    } finally {
      _actualizarIUTieneInformacion();
    }
  }

  Future<bool> eliminarTarea(String tareaId) async {
    try {
      _actualizarIUCargando();
      await _tareaRepo.eliminarTarea(tareaId);
      _tareas = await _tareaRepo.getTareasPorFecha(_fechaSeleccionada);
      return true;
    } catch (e) {
      return false;
    } finally {
      _actualizarIUTieneInformacion();
    }
  }

  List<Tarea> _generarRecurrencias(Tarea base, FrecuenciaRecurrencia frecuencia) {
    final List<Tarea> resultado = [];

    final int anioFinCurso = base.fecha.month >= 9 
        ? base.fecha.year + 1 
        : base.fecha.year;

    final DateTime finCurso = DateTime(anioFinCurso, 6, 30, 23, 59, 59);
    DateTime fechaCursor = base.fecha;

    while (!fechaCursor.isAfter(finCurso)) {
      final esFinDeSemana = fechaCursor.weekday == DateTime.saturday || fechaCursor.weekday == DateTime.sunday;

      if (!(frecuencia == FrecuenciaRecurrencia.diasLectivos && esFinDeSemana)) {
        final nuevaInicio = DateTime(
          fechaCursor.year,
          fechaCursor.month,
          fechaCursor.day,
          base.horaInicio.hour,
          base.horaInicio.minute,
        );

        final nuevaFin = DateTime(
          fechaCursor.year,
          fechaCursor.month,
          fechaCursor.day,
          base.horaFinal.hour,
          base.horaFinal.minute,
        );

        resultado.add(base.copyWith(
          fecha: fechaCursor,
          horaInicio: nuevaInicio,
          horaFinal: nuevaFin,
        ));
      }

      switch (frecuencia) {
        case FrecuenciaRecurrencia.semanal:
          fechaCursor = fechaCursor.add(const Duration(days: 7));
          break;
        case FrecuenciaRecurrencia.diario:
        case FrecuenciaRecurrencia.diasLectivos:
          fechaCursor = fechaCursor.add(const Duration(days: 1));
          break;
      }
    }

    return resultado;
  }

Future<String?> subirVideo() async {
  _actualizarIUSubiendoMultimedia(true);
  try {
    return await _storageRepo.seleccionarYSubirVideo();
  } finally {
    _actualizarIUSubiendoMultimedia(false);
  }
}

Future<String?> subirAudio() async {
  _actualizarIUSubiendoMultimedia(true);
  try {
    return await _storageRepo.seleccionarYSubirAudio();
  } finally {
    _actualizarIUSubiendoMultimedia(false);
  }
}
}