import 'package:flutter/foundation.dart';

import '../data/pictograma_repository.dart';
import '../models/pictograma.dart';
import '../models/tarea.dart';

class PictogramaViewModel extends ChangeNotifier {
  PictogramaViewModel(this._repository) {
    buscar('');
  }

  final PictogramaRepository _repository;

  List<Pictograma> _resultados = [];
  String _mensajeError = '';
  bool _cargando = false;

  List<Pictograma> get resultados => List.unmodifiable(_resultados);
  String get mensajeError => _mensajeError;
  bool get cargando => _cargando;

  /// Busca pictogramas en la biblioteca usando la etiqueta o descripción de la tarea.
  Future<void> buscar(String etiqueta) async {
    _cargando = true;
    _mensajeError = '';
    notifyListeners();

    try {
      _resultados = await _repository.buscarPorEtiqueta(etiqueta);
    } catch (e) {
      _mensajeError = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Sube un pictograma validando que sea PNG.
  /// Devuelve `true` si se guardó correctamente o `false` si fue bloqueado.
  Future<bool> subirNuevoPictograma({
    required String nombreArchivo,
    required String etiquetaTextual,
    String? imagenUrl,
  }) async {
    _mensajeError = '';
    try {
      await _repository.subirPictograma(
        nombreArchivo: nombreArchivo,
        etiquetaTextual: etiquetaTextual,
        imagenUrl: imagenUrl,
      );
      await buscar(''); // Refrescar resultados
      return true;
    } on FormatoNoAdmitidoException catch (e) {
      _mensajeError = e.mensaje;
      notifyListeners();
      return false;
    } catch (e) {
      _mensajeError = 'Error al subir el pictograma: $e';
      notifyListeners();
      return false;
    }
  }

  /// Asigna el pictograma seleccionado a la tarea indicada.
  Future<Tarea> asignarATarea(Tarea tarea, Pictograma pictograma) async {
    return _repository.asignarPictogramaATarea(
      tarea: tarea,
      pictograma: pictograma,
    );
  }
}

