import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../models/usuario.dart';

/// Guarda quién ha iniciado sesión.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repo) {
    _restaurar();
  }

  final AuthRepository _repo;

  Usuario? _usuario;
  bool _inicializando = true;
  bool _cargando = false;
  String? _error;

  Usuario? get usuario => _usuario;
  bool get inicializando => _inicializando;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> _restaurar() async {
    try {
      _usuario = await _repo.restaurarSesion();
    } catch (_) {
      _usuario = null;
    }
    _inicializando = false;
    notifyListeners();
  }

  Future<bool> iniciarSesion(String nombreUsuario, String password) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _usuario = await _repo.iniciarSesion(nombreUsuario, password);
      return true;
    } on CredencialesInvalidasException catch (e) {
      _error = e.toString();
      return false;
    } on FirebaseAuthException catch (e) {
      _error = e.code == 'too-many-requests'
          ? 'Demasiados intentos. Espera un momento.'
          : 'Error de acceso (${e.code}).';
      return false;
    } catch (e) {
      _error = 'No se pudo iniciar sesión: $e';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> cambiarPassword(String nueva) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.cambiarPassword(nueva);
      _usuario = _usuario!.copyWith(debeCambiarPassword: false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.code == 'weak-password'
          ? 'La contraseña es demasiado débil.'
          : e.code == 'requires-recent-login'
          ? 'Vuelve a iniciar sesión e inténtalo de nuevo.'
          : 'No se pudo cambiar la contraseña (${e.code}).';
      return false;
    } catch (e) {
      _error = 'No se pudo cambiar la contraseña: $e';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cerrarSesion() async {
    await _repo.cerrarSesion();
    _usuario = null;
    _error = null;
    notifyListeners();
  }
}
