import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/usuario.dart';

class CredencialesInvalidasException implements Exception {
  const CredencialesInvalidasException();
  @override
  String toString() => 'Nombre de usuario o contraseña incorrectos.';
}

class CuentaNoActivaException implements Exception {
  const CuentaNoActivaException(this.estado);
  final EstadoCuenta estado;

  @override
  String toString() => estado == EstadoCuenta.suspendida
      ? 'Acceso denegado: tu cuenta está suspendida. Contacta con el centro.'
      : 'Acceso denegado: esta cuenta ha sido dada de baja.';
}

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const dominio = 'miagenda.app';

  /// Email interno para cuentas sin correo real.
  static String emailDe(String nombreUsuario) =>
      '${nombreUsuario.trim().toLowerCase()}@$dominio';

  /// Busca con qué email está registrada la cuenta. Si no hay entrada
  /// (cuentas antiguas), usa el email interno.
  Future<String> _emailParaLogin(String nu) async {
    try {
      final doc = await _db.collection('nombresUsuario').doc(nu).get();
      final email = doc.data()?['email'] as String?;
      if (email != null && email.isNotEmpty) return email;
    } catch (_) {}
    return emailDe(nu);
  }

  Future<Usuario> iniciarSesion(String nombreUsuario, String password) async {
    final nu = nombreUsuario.trim().toLowerCase();

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: await _emailParaLogin(nu),
        password: password,
      );
      final doc = await _db.collection('usuarios').doc(cred.user!.uid).get();
      if (!doc.exists || doc.data() == null) {
        await _auth.signOut();
        throw const CredencialesInvalidasException();
      }
      final usuario = Usuario.fromMap(doc.id, doc.data()!);
      if (usuario.estado != EstadoCuenta.activa) {
        await _auth.signOut();
        throw CuentaNoActivaException(usuario.estado);
      }
      return usuario;
    } on FirebaseAuthException catch (e) {
      const malos = {
        'invalid-credential',
        'user-not-found',
        'wrong-password',
        'invalid-email',
      };
      if (malos.contains(e.code)) throw const CredencialesInvalidasException();
      rethrow;
    }
  }

  Future<Usuario?> restaurarSesion() async {
    final user = await _auth.authStateChanges().first;
    if (user == null) return null;
    final doc = await _db.collection('usuarios').doc(user.uid).get();
    if (!doc.exists || doc.data() == null) {
      await _auth.signOut();
      return null;
    }
    final usuario = Usuario.fromMap(doc.id, doc.data()!);
    if (usuario.estado != EstadoCuenta.activa) {
      await _auth.signOut();
      return null;
    }
    return usuario;
  }

  Future<void> cerrarSesion() => _auth.signOut();

  /// Cambio de contraseña obligatorio en el primer acceso.
  Future<void> cambiarPassword(String nueva) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'No hay ningún usuario autenticado para cambiar la contraseña.',
      );
    }
    await user.updatePassword(nueva);
    await _db.collection('usuarios').doc(user.uid).update({
      'debeCambiarPassword': false,
    });
  }
}
