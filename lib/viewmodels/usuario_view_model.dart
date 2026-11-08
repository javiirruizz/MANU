import 'package:flutter/foundation.dart';

import '../data/usuario_repository.dart';
import '../models/usuario.dart';

class UsuarioViewModel extends ChangeNotifier {
  UsuarioViewModel(this._repository, {Usuario? solicitanteInicial}) {
    _solicitante = solicitanteInicial ??
        Usuario(
          id: 'admin_1',
          nombre: 'Carlos Delgado (Admin)',
          dni: '12345678A',
          telefonoContacto: '600112233',
          fechaNacimiento: DateTime(1985, 3, 14),
          rol: RolUsuario.administrador,
        );
    cargarUsuarios();
  }

  final UsuarioRepository _repository;

  late Usuario _solicitante;
  List<Usuario> _usuarios = [];
  Usuario? _usuarioSeleccionado;
  RolUsuario? _filtroRol;
  String _filtroTexto = '';
  bool _cargando = false;
  String? _mensajeError;
  String? _mensajeExito;

  Usuario get solicitante => _solicitante;
  List<Usuario> get usuarios => List.unmodifiable(_usuariosFiltrados);
  Usuario? get usuarioSeleccionado => _usuarioSeleccionado;
  RolUsuario? get filtroRol => _filtroRol;
  String get filtroTexto => _filtroTexto;
  bool get cargando => _cargando;
  String? get mensajeError => _mensajeError;
  String? get mensajeExito => _mensajeExito;

  List<Usuario> get _usuariosFiltrados {
    return _usuarios.where((u) {
      final cumpleRol = _filtroRol == null || u.rol == _filtroRol;
      final query = _filtroTexto.trim().toLowerCase();
      final cumpleTexto = query.isEmpty ||
          u.nombre.toLowerCase().contains(query) ||
          u.dni.toLowerCase().contains(query);
      return cumpleRol && cumpleTexto;
    }).toList();
  }

  void cambiarSolicitante(Usuario nuevoSolicitante) {
    _solicitante = nuevoSolicitante;
    _mensajeError = null;
    _mensajeExito = 'Perfil activo cambiado a: ${nuevoSolicitante.nombre} (${nuevoSolicitante.rol.name})';
    notifyListeners();
  }

  void limpiarMensajes() {
    _mensajeError = null;
    _mensajeExito = null;
    notifyListeners();
  }

  void filtrarPorRol(RolUsuario? rol) {
    _filtroRol = rol;
    notifyListeners();
  }

  void filtrarPorTexto(String texto) {
    _filtroTexto = texto;
    notifyListeners();
  }

  void seleccionarUsuario(Usuario? usuario) {
    _usuarioSeleccionado = usuario;
    _mensajeError = null;
    _mensajeExito = null;
    notifyListeners();
  }

  Future<void> cargarUsuarios() async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      _usuarios = await _repository.listarUsuarios();
      if (_usuarioSeleccionado != null) {
        _usuarioSeleccionado = _usuarios.firstWhere(
          (u) => u.id == _usuarioSeleccionado!.id,
          orElse: () => _usuarios.first,
        );
      } else if (_usuarios.isNotEmpty) {
        _usuarioSeleccionado = _usuarios.first;
      }
    } catch (e) {
      _mensajeError = 'Error al cargar usuarios: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> cambiarRol(String usuarioId, RolUsuario nuevoRol) async {
    _mensajeError = null;
    _mensajeExito = null;

    try {
      final actualizado = await _repository.cambiarRol(
        solicitante: _solicitante,
        usuarioId: usuarioId,
        nuevoRol: nuevoRol,
      );

      final index = _usuarios.indexWhere((u) => u.id == usuarioId);
      if (index != -1) {
        _usuarios[index] = actualizado;
      }
      if (_usuarioSeleccionado?.id == usuarioId) {
        _usuarioSeleccionado = actualizado;
      }
      _mensajeExito = 'Rol actualizado correctamente a "${nuevoRol.name}".';
      notifyListeners();
      return true;
    } on AccesoDenegadoException catch (e) {
      _mensajeError = e.mensaje;
      notifyListeners();
      return false;
    } catch (e) {
      _mensajeError = 'Error al cambiar rol: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> togglePermiso(
    String usuarioId,
    PermisoUsuario permiso,
    bool conceder,
  ) async {
    _mensajeError = null;
    _mensajeExito = null;

    try {
      final actualizado = conceder
          ? await _repository.concederPermiso(
              solicitante: _solicitante,
              usuarioId: usuarioId,
              permiso: permiso,
            )
          : await _repository.revocarPermiso(
              solicitante: _solicitante,
              usuarioId: usuarioId,
              permiso: permiso,
            );

      final index = _usuarios.indexWhere((u) => u.id == usuarioId);
      if (index != -1) {
        _usuarios[index] = actualizado;
      }
      if (_usuarioSeleccionado?.id == usuarioId) {
        _usuarioSeleccionado = actualizado;
      }
      _mensajeExito = conceder
          ? 'Permiso "${permiso.nombre}" concedido.'
          : 'Permiso "${permiso.nombre}" revocado.';
      notifyListeners();
      return true;
    } on AccesoDenegadoException catch (e) {
      _mensajeError = e.mensaje;
      notifyListeners();
      return false;
    } catch (e) {
      _mensajeError = 'Error al actualizar permiso: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> restablecerPermisosPorDefecto(String usuarioId) async {
    _mensajeError = null;
    _mensajeExito = null;

    try {
      final actual = await _repository.obtenerUsuarioPorId(usuarioId);
      if (actual == null) return false;

      final permisosDefecto = PermisoUsuario.permisosPorDefecto(actual.rol);
      final actualizado = await _repository.actualizarPermisos(
        solicitante: _solicitante,
        usuarioId: usuarioId,
        nuevosPermisos: permisosDefecto,
      );

      final index = _usuarios.indexWhere((u) => u.id == usuarioId);
      if (index != -1) {
        _usuarios[index] = actualizado;
      }
      if (_usuarioSeleccionado?.id == usuarioId) {
        _usuarioSeleccionado = actualizado;
      }
      _mensajeExito = 'Permisos restablecidos a los valores por defecto del rol.';
      notifyListeners();
      return true;
    } on AccesoDenegadoException catch (e) {
      _mensajeError = e.mensaje;
      notifyListeners();
      return false;
    } catch (e) {
      _mensajeError = 'Error al restablecer permisos: $e';
      notifyListeners();
      return false;
    }
  }
}
