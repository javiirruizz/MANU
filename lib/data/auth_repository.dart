import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/usuario.dart';

class CredencialesInvalidasException implements Exception {
  const CredencialesInvalidasException();
  @override
  String toString() => 'Nombre de usuario o contraseña incorrectos.';
}

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const dominio = 'miagenda.app';

  /// El usuario escribe "lucas.gomez"; Firebase Auth recibe un email interno.
  static String emailDe(String nombreUsuario) =>
      '${nombreUsuario.trim().toLowerCase()}@$dominio';

  Future<Usuario> iniciarSesion(String nombreUsuario, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: emailDe(nombreUsuario),
        password: password,
      );
      final doc = await _db.collection('usuarios').doc(cred.user!.uid).get();
      if (!doc.exists || doc.data() == null) {
        await _auth.signOut();
        throw const CredencialesInvalidasException();
      }
      return Usuario.fromMap(doc.id, doc.data()!);
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

  /// Recupera la sesión si el usuario ya había iniciado sesión antes.
  Future<Usuario?> restaurarSesion() async {
    final user = await _auth.authStateChanges().first;
    if (user == null) return null;
    final doc = await _db.collection('usuarios').doc(user.uid).get();
    if (!doc.exists || doc.data() == null) {
      await _auth.signOut();
      return null;
    }
    return Usuario.fromMap(doc.id, doc.data()!);
  }

  Future<void> cerrarSesion() => _auth.signOut();

  /// Cambio de contraseña obligatorio en el primer acceso.
  Future<void> cambiarPassword(String nueva) async {
    final user = _auth.currentUser!;
    await user.updatePassword(nueva);
    await _db.collection('usuarios').doc(user.uid).update({
      'debeCambiarPassword': false,
    });
  }
}
