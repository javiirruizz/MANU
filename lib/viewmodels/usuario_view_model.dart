import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/usuario_repository.dart';
import '../models/usuario.dart';

class UsuarioViewModel extends ChangeNotifier {
  UsuarioViewModel(this._repository, {required Usuario solicitante})
    : _solicitante = solicitante {
    cargarUsuarios();
  }

  final UsuarioRepository _repository;

  Usuario _solicitante;
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
    final query = _filtroTexto.trim().toLowerCase();
    return _usuarios.where((u) {
      final cumpleRol = _filtroRol == null || u.rol == _filtroRol;
      final cumpleTexto =
          query.isEmpty ||
          u.nombre.toLowerCase().contains(query) ||
          u.nombreUsuario.toLowerCase().contains(query) ||
          (u.dni ?? '').toLowerCase().contains(query);
      return cumpleRol && cumpleTexto;
    }).toList();
  }

  void cambiarSolicitante(Usuario nuevoSolicitante) {
    _solicitante = nuevoSolicitante;
    _mensajeError = null;
    _mensajeExito =
        'Perfil activo cambiado a: ${nuevoSolicitante.nombre} (${nuevoSolicitante.rol.name})';
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
        final id = _usuarioSeleccionado!.id;
        final i = _usuarios.indexWhere((u) => u.id == id);
        _usuarioSeleccionado = i == -1 ? null : _usuarios[i];
      }
    } catch (e) {
      _mensajeError = 'Error al cargar usuarios: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// HU 02.1 - Alta de cuenta. Devuelve null si falla (ver [mensajeError]).
  Future<UsuarioCreado?> crearUsuario({
    required String nombre,
    required String nombreUsuario,
    required RolUsuario rol,
    String? dni,
    String? telefonoContacto,
    DateTime? fechaNacimiento,
  }) async {
    _mensajeError = null;
    _mensajeExito = null;
    _cargando = true;
    notifyListeners();

    try {
      final creado = await _repository.crearUsuario(
        solicitante: _solicitante,
        nombre: nombre,
        nombreUsuario: nombreUsuario,
        rol: rol,
        dni: dni,
        telefonoContacto: telefonoContacto,
        fechaNacimiento: fechaNacimiento,
      );
      _usuarios = [..._usuarios, creado.usuario];
      _mensajeExito = 'Cuenta "${creado.usuario.nombreUsuario}" creada.';
      return creado;
    } on AccesoDenegadoException catch (e) {
      _mensajeError = e.mensaje;
    } on NombreUsuarioDuplicadoException catch (e) {
      _mensajeError = e.toString();
    } on ArgumentError catch (e) {
      _mensajeError = e.message.toString();
    } on FirebaseAuthException catch (e) {
      _mensajeError = e.code == 'operation-not-allowed'
          ? 'Activa "Correo electrónico/contraseña" en Firebase Authentication.'
          : 'Error al crear la cuenta (${e.code}).';
    } catch (e) {
      _mensajeError = 'Error al crear la cuenta: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
    return null;
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
      _reemplazar(actualizado);
      _mensajeExito = 'Rol actualizado correctamente a "${nuevoRol.name}".';
      notifyListeners();
      return true;
    } on AccesoDenegadoException catch (e) {
      _mensajeError = e.mensaje;
    } catch (e) {
      _mensajeError = 'Error al cambiar rol: $e';
    }
    notifyListeners();
    return false;
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
      _reemplazar(actualizado);
      _mensajeExito = conceder
          ? 'Permiso "${permiso.nombre}" concedido.'
          : 'Permiso "${permiso.nombre}" revocado.';
      notifyListeners();
      return true;
    } on AccesoDenegadoException catch (e) {
      _mensajeError = e.mensaje;
    } catch (e) {
      _mensajeError = 'Error al actualizar permiso: $e';
    }
    notifyListeners();
    return false;
  }

  Future<bool> restablecerPermisosPorDefecto(String usuarioId) async {
    _mensajeError = null;
    _mensajeExito = null;
    try {
      final actual = await _repository.obtenerUsuarioPorId(usuarioId);
      if (actual == null) return false;
      final actualizado = await _repository.actualizarPermisos(
        solicitante: _solicitante,
        usuarioId: usuarioId,
        nuevosPermisos: PermisoUsuario.permisosPorDefecto(actual.rol),
      );
      _reemplazar(actualizado);
      _mensajeExito =
          'Permisos restablecidos a los valores por defecto del rol.';
      notifyListeners();
      return true;
    } on AccesoDenegadoException catch (e) {
      _mensajeError = e.mensaje;
    } catch (e) {
      _mensajeError = 'Error al restablecer permisos: $e';
    }
    notifyListeners();
    return false;
  }

  void _reemplazar(Usuario actualizado) {
    final i = _usuarios.indexWhere((u) => u.id == actualizado.id);
    if (i != -1) _usuarios[i] = actualizado;
    if (_usuarioSeleccionado?.id == actualizado.id) {
      _usuarioSeleccionado = actualizado;
    }
  }
}
