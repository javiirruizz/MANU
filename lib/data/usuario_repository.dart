import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/usuario.dart';
import 'auth_repository.dart';

class AccesoDenegadoException implements Exception {
  const AccesoDenegadoException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

class NombreUsuarioDuplicadoException implements Exception {
  const NombreUsuarioDuplicadoException(this.nombreUsuario);
  final String nombreUsuario;

  @override
  String toString() => 'El nombre de usuario "$nombreUsuario" ya está en uso.';
}

class UsuarioCreado {
  const UsuarioCreado(this.usuario, this.passwordTemporal);
  final Usuario usuario;
  final String passwordTemporal;
}

class CorreoEnUsoException implements Exception {
  const CorreoEnUsoException(this.correo);
  final String correo;

  @override
  String toString() => 'El correo "$correo" ya está asociado a otra cuenta.';
}

class UsuarioRepository {
  UsuarioRepository({FirebaseFirestore? firestore})
    : _db =
          firestore ??
          (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  final FirebaseFirestore? _db;

  static final List<Usuario> _usuariosIniciales = [
    const Usuario(
      id: 'admin_1',
      nombreUsuario: 'admin',
      nombre: 'Usuario Administrador',
      dni: '00000001A',
      telefonoContacto: '600000001',
      rol: RolUsuario.administrador,
      puedeEditarPerfil: true,
    ),
    const Usuario(
      id: 'profe_1',
      nombreUsuario: 'profesor',
      nombre: 'Usuario Profesor',
      dni: '00000002B',
      telefonoContacto: '600000002',
      rol: RolUsuario.profesor,
      puedeEditarPerfil: true,
    ),
    const Usuario(
      id: 'fam_1',
      nombreUsuario: 'familiar',
      nombre: 'Usuario Familiar',
      dni: '00000003C',
      telefonoContacto: '600000003',
      rol: RolUsuario.familiar,
      puedeEditarPerfil: false,
      alumnoIds: ['alum_1'],
    ),
    const Usuario(
      id: 'alum_1',
      nombreUsuario: 'alumno1',
      nombre: 'Usuario Alumno 1',
      dni: '00000004D',
      telefonoContacto: '600000004',
      rol: RolUsuario.alumno,
      puedeEditarPerfil: false,
    ),
    const Usuario(
      id: 'alum_2',
      nombreUsuario: 'alumno2',
      nombre: 'Usuario Alumno 2',
      dni: '00000005E',
      telefonoContacto: '600000005',
      rol: RolUsuario.alumno,
      puedeEditarPerfil: false,
    ),
  ];

  final List<Usuario> _usuariosLocales = List.of(_usuariosIniciales);

  Future<List<Usuario>> getAlumnos() =>
      listarUsuarios(filtroRol: RolUsuario.alumno);

  Future<List<Usuario>> listarUsuarios({RolUsuario? filtroRol}) async {
    final db = _db;
    if (db != null) {
      Query query = db.collection('usuarios');
      if (filtroRol != null) {
        query = query.where('rol', isEqualTo: filtroRol.name);
      }
      final snap = await query.get();
      if (snap.docs.isNotEmpty) {
        return snap.docs
            .map(
              (d) => Usuario.fromMap(
                d.id,
                Map<String, dynamic>.from(d.data() as Map),
              ),
            )
            .toList();
      }
    }
    if (filtroRol != null) {
      return _usuariosLocales.where((u) => u.rol == filtroRol).toList();
    }
    return List.unmodifiable(_usuariosLocales);
  }

  Future<Usuario?> obtenerUsuarioPorId(String id) async {
    final db = _db;
    if (db != null) {
      final doc = await db.collection('usuarios').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return Usuario.fromMap(doc.id, doc.data()!);
      }
    }
    try {
      return _usuariosLocales.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  void verificarAcceso({
    required Usuario usuario,
    required PermisoUsuario permisoRequerido,
    String? accion,
  }) {
    if (!usuario.tienePermiso(permisoRequerido)) {
      final detalle = accion != null ? ' para realizar: $accion' : '';
      throw AccesoDenegadoException(
        'Acceso denegado: el usuario "${usuario.nombre}" con rol '
        '"${usuario.rol.name}" no tiene el permiso '
        '"${permisoRequerido.nombre}"$detalle.',
      );
    }
  }

  bool puedeEjecutarAccion({
    required Usuario usuario,
    required PermisoUsuario permisoRequerido,
  }) => usuario.tienePermiso(permisoRequerido);

  Future<FirebaseApp> _appSecundaria() async {
    try {
      return Firebase.app('secundaria');
    } catch (_) {
      return Firebase.initializeApp(
        name: 'secundaria',
        options: Firebase.app().options,
      );
    }
  }

  String _generarPasswordTemporal([int longitud = 8]) {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(
      longitud,
      (_) => chars[r.nextInt(chars.length)],
    ).join();
  }

  Future<UsuarioCreado> crearUsuario({
    required Usuario solicitante,
    required String nombre,
    required String nombreUsuario,
    required RolUsuario rol,
    String? dni,
    String? email,
    String? telefonoContacto,
    DateTime? fechaNacimiento,
    List<String> alumnoIds = const [],
  }) async {
    verificarAcceso(
      usuario: solicitante,
      permisoRequerido: PermisoUsuario.gestionarUsuarios,
      accion: 'dar de alta una cuenta',
    );

    final nu = nombreUsuario.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9._-]{3,30}$').hasMatch(nu)) {
      throw ArgumentError(
        'El nombre de usuario debe tener entre 3 y 30 caracteres: '
        'letras sin tildes, números, punto, guion o guion bajo.',
      );
    }

    final correo = (email == null || email.trim().isEmpty)
        ? null
        : email.trim().toLowerCase();
    if (correo != null &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
      throw ArgumentError('El correo no tiene un formato válido.');
    }

    final db = _db;
    if (db != null) {
      final existe = await db.collection('nombresUsuario').doc(nu).get();
      if (existe.exists) throw NombreUsuarioDuplicadoException(nu);
    }

    final emailAuth = correo ?? AuthRepository.emailDe(nu);
    final password = _generarPasswordTemporal();

    final auth = FirebaseAuth.instanceFor(app: await _appSecundaria());
    final UserCredential cred;
    try {
      cred = await auth.createUserWithEmailAndPassword(
        email: emailAuth,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw correo != null
            ? CorreoEnUsoException(correo)
            : NombreUsuarioDuplicadoException(nu);
      }
      rethrow;
    }

    final usuario = Usuario(
      id: cred.user!.uid,
      nombreUsuario: nu,
      nombre: nombre.trim(),
      rol: rol,
      email: correo,
      dni: (dni == null || dni.trim().isEmpty) ? null : dni.trim(),
      telefonoContacto:
          (telefonoContacto == null || telefonoContacto.trim().isEmpty)
          ? null
          : telefonoContacto.trim(),
      fechaNacimiento: fechaNacimiento,
      debeCambiarPassword: true,
      alumnoIds: rol == RolUsuario.familiar ? alumnoIds : const [],
    );

    try {
      _usuariosLocales.add(usuario);
      await db?.collection('usuarios').doc(usuario.id).set(usuario.toMap());
      await db?.collection('nombresUsuario').doc(nu).set({
        'email': emailAuth,
        'uid': usuario.id,
      });
    } catch (_) {
      await cred.user!.delete();
      rethrow;
    } finally {
      await auth.signOut();
    }

    return UsuarioCreado(usuario, password);
  }

  Future<Usuario> modificarUsuario({
    required Usuario solicitante,
    required String usuarioId,
    required String nombre,
    required String nombreUsuario,
    String? dni,
    String? telefonoContacto,
    DateTime? fechaNacimiento,
    List<String>? alumnoIds,
  }) async {
    verificarAcceso(
      usuario: solicitante,
      permisoRequerido: PermisoUsuario.gestionarUsuarios,
      accion: 'modificar datos de usuario',
    );

    final actual = await obtenerUsuarioPorId(usuarioId);
    if (actual == null) {
      throw ArgumentError('Usuario con id $usuarioId no encontrado.');
    }

    final nombreLimpio = nombre.trim();
    if (nombreLimpio.isEmpty) {
      throw ArgumentError('El nombre no puede estar vacío.');
    }

    final nu = nombreUsuario.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9._-]{3,30}$').hasMatch(nu)) {
      throw ArgumentError(
        'El nombre de usuario debe tener entre 3 y 30 caracteres: '
        'letras sin tildes, números, punto, guion o guion bajo.',
      );
    }

    // Comprobar que el nuevo nombre de usuario no pertenezca a otra cuenta
    if (nu != actual.nombreUsuario.toLowerCase()) {
      final todos = await listarUsuarios();
      final duplicado = todos.any(
        (u) => u.id != usuarioId && u.nombreUsuario.toLowerCase() == nu,
      );
      if (duplicado) {
        throw NombreUsuarioDuplicadoException(nu);
      }
    }

    final actualizado = actual.copyWith(
      nombre: nombreLimpio,
      nombreUsuario: nu,
      dni: (dni == null || dni.trim().isEmpty) ? null : dni.trim(),
      telefonoContacto:
          (telefonoContacto == null || telefonoContacto.trim().isEmpty)
          ? null
          : telefonoContacto.trim(),
      fechaNacimiento: fechaNacimiento ?? actual.fechaNacimiento,
      alumnoIds: actual.rol == RolUsuario.familiar
          ? (alumnoIds ?? actual.alumnoIds)
          : const [],
    );

    final idx = _usuariosLocales.indexWhere((u) => u.id == usuarioId);
    if (idx != -1) {
      _usuariosLocales[idx] = actualizado;
    } else {
      _usuariosLocales.add(actualizado);
    }

    await _db
        ?.collection('usuarios')
        .doc(usuarioId)
        .update(actualizado.toMap());

    return actualizado;
  }

  /// Genera una contraseña temporal de un solo uso y fuerza el cambio en el próximo acceso.
  /// Envía el enlace de restablecimiento al correo real del usuario.
  /// Devuelve el correo de destino.
  Future<String> restablecerPassword({
    required Usuario solicitante,
    required String usuarioId,
  }) async {
    verificarAcceso(
      usuario: solicitante,
      permisoRequerido: PermisoUsuario.gestionarUsuarios,
      accion: 'restablecer contraseña de usuario',
    );

    final actual = await obtenerUsuarioPorId(usuarioId);
    if (actual == null) {
      throw ArgumentError('Usuario con id $usuarioId no encontrado.');
    }

    final correo = actual.email;
    if (correo == null || correo.isEmpty) {
      throw ArgumentError(
        'Esta cuenta no tiene correo de recuperación asociado.',
      );
    }

    if (_db != null) {
      final auth = FirebaseAuth.instance;
      await auth.setLanguageCode('es');
      try {
        await auth.sendPasswordResetEmail(email: correo);
      } on FirebaseAuthException catch (e) {
        throw ArgumentError('No se pudo enviar el correo (${e.code}).');
      }
    }
    return correo;
  }

  Future<void> eliminarUsuario({
    required Usuario solicitante,
    required String usuarioId,
  }) async {
    verificarAcceso(
      usuario: solicitante,
      permisoRequerido: PermisoUsuario.gestionarUsuarios,
      accion: 'dar de baja una cuenta',
    );

    if (solicitante.id == usuarioId) {
      throw const AccesoDenegadoException(
        'No puedes dar de baja tu propia cuenta mientras tienes la sesión iniciada.',
      );
    }

    final actual = await obtenerUsuarioPorId(usuarioId);
    if (actual == null) {
      throw ArgumentError('Usuario con id $usuarioId no encontrado.');
    }

    if (actual.rol == RolUsuario.administrador) {
      final todos = await listarUsuarios();
      final numAdmins = todos
          .where((u) => u.rol == RolUsuario.administrador)
          .length;
      if (numAdmins <= 1) {
        throw const AccesoDenegadoException(
          'Operación no permitida: debe existir al menos un administrador.',
        );
      }
    }

    await _db
        ?.collection('nombresUsuario')
        .doc(actual.nombreUsuario.toLowerCase())
        .delete();

    _usuariosLocales.removeWhere((u) => u.id == usuarioId);
    await _db?.collection('usuarios').doc(usuarioId).delete();
  }

  // ---------------------------------------------------------------------
  // Roles y permisos
  // ---------------------------------------------------------------------

  Future<Usuario> cambiarRol({
    required Usuario solicitante,
    required String usuarioId,
    required RolUsuario nuevoRol,
    bool resetearPermisos = true,
  }) async {
    verificarAcceso(
      usuario: solicitante,
      permisoRequerido: PermisoUsuario.gestionarRolesYPermisos,
      accion: 'modificar rol de usuario',
    );

    final actual = await obtenerUsuarioPorId(usuarioId);
    if (actual == null) {
      throw ArgumentError('Usuario con id $usuarioId no encontrado.');
    }

    if (actual.rol == RolUsuario.administrador &&
        nuevoRol != RolUsuario.administrador) {
      final todos = await listarUsuarios();
      final numAdmins = todos
          .where((u) => u.rol == RolUsuario.administrador)
          .length;
      if (numAdmins <= 1) {
        throw const AccesoDenegadoException(
          'Operación no permitida: debe existir al menos un administrador.',
        );
      }
    }

    final nuevosPermisos = resetearPermisos
        ? PermisoUsuario.permisosPorDefecto(nuevoRol)
        : actual.permisos;

    final actualizado = actual.copyWith(
      rol: nuevoRol,
      permisos: nuevosPermisos,
    );
    final idx = _usuariosLocales.indexWhere((u) => u.id == usuarioId);
    if (idx != -1) {
      _usuariosLocales[idx] = actualizado;
    } else {
      _usuariosLocales.add(actualizado);
    }
    await _db
        ?.collection('usuarios')
        .doc(usuarioId)
        .update(actualizado.toMap());
    return actualizado;
  }

  Future<Usuario> actualizarPermisos({
    required Usuario solicitante,
    required String usuarioId,
    required Set<PermisoUsuario> nuevosPermisos,
  }) async {
    verificarAcceso(
      usuario: solicitante,
      permisoRequerido: PermisoUsuario.gestionarRolesYPermisos,
      accion: 'modificar permisos de usuario',
    );

    final actual = await obtenerUsuarioPorId(usuarioId);
    if (actual == null) {
      throw ArgumentError('Usuario con id $usuarioId no encontrado.');
    }

    final actualizado = actual.copyWith(
      permisos: Set.unmodifiable(nuevosPermisos),
    );
    final idx = _usuariosLocales.indexWhere((u) => u.id == usuarioId);
    if (idx != -1) {
      _usuariosLocales[idx] = actualizado;
    } else {
      _usuariosLocales.add(actualizado);
    }
    await _db
        ?.collection('usuarios')
        .doc(usuarioId)
        .update(actualizado.toMap());
    return actualizado;
  }

  Future<Usuario> concederPermiso({
    required Usuario solicitante,
    required String usuarioId,
    required PermisoUsuario permiso,
  }) async {
    final actual = await obtenerUsuarioPorId(usuarioId);
    if (actual == null) {
      throw ArgumentError('Usuario con id $usuarioId no encontrado.');
    }
    return actualizarPermisos(
      solicitante: solicitante,
      usuarioId: usuarioId,
      nuevosPermisos: {...actual.permisos, permiso},
    );
  }

  Future<Usuario> revocarPermiso({
    required Usuario solicitante,
    required String usuarioId,
    required PermisoUsuario permiso,
  }) async {
    final actual = await obtenerUsuarioPorId(usuarioId);
    if (actual == null) {
      throw ArgumentError('Usuario con id $usuarioId no encontrado.');
    }
    return actualizarPermisos(
      solicitante: solicitante,
      usuarioId: usuarioId,
      nuevosPermisos: actual.permisos.where((p) => p != permiso).toSet(),
    );
  }
}
