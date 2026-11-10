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

class UsuarioRepository {
  UsuarioRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // Lista todos los usuarios y permite filtrar por rol.
  Future<List<Usuario>> listarUsuarios({RolUsuario? filtroRol}) async {
    Query<Map<String, dynamic>> query = _db.collection('usuarios');
    if (filtroRol != null) {
      query = query.where('rol', isEqualTo: filtroRol.name);
    }
    final snap = await query.get();
    return snap.docs.map((d) => Usuario.fromMap(d.id, d.data())).toList();
  }

  Future<Usuario?> obtenerUsuarioPorId(String id) async {
    final doc = await _db.collection('usuarios').doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Usuario.fromMap(doc.id, doc.data()!);
  }

  // Lanza AccesoDenegadoException si no tiene permiso
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

  // ---------------------------------------------------------------------
  // HU 02.1 - Alta de nuevas cuentas
  // ---------------------------------------------------------------------

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
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789';
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
    String? telefonoContacto,
    DateTime? fechaNacimiento,
  }) async {
    // Prueba 3: un alumno (u otro rol sin permiso) queda bloqueado
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

    final password = _generarPasswordTemporal();

    // La cuenta se crea en la app secundaria para no cerrar la sesión del admin
    final auth = FirebaseAuth.instanceFor(app: await _appSecundaria());
    final UserCredential cred;
    try {
      cred = await auth.createUserWithEmailAndPassword(
        email: AuthRepository.emailDe(nu),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Prueba 2: nombre de usuario repetido
      if (e.code == 'email-already-in-use') {
        throw NombreUsuarioDuplicadoException(nu);
      }
      rethrow;
    }

    final usuario = Usuario(
      id: cred.user!.uid,
      nombreUsuario: nu,
      nombre: nombre.trim(),
      rol: rol,
      dni: (dni == null || dni.trim().isEmpty) ? null : dni.trim(),
      telefonoContacto:
          (telefonoContacto == null || telefonoContacto.trim().isEmpty)
          ? null
          : telefonoContacto.trim(),
      fechaNacimiento: fechaNacimiento,
      debeCambiarPassword: true,
    );

    try {
      // Prueba 1: queda registrada en la BD (usa la sesión del admin)
      await _db.collection('usuarios').doc(usuario.id).set(usuario.toMap());
    } catch (_) {
      await cred.user!.delete(); // evita cuentas "huérfanas" sin ficha
      rethrow;
    } finally {
      await auth.signOut();
    }

    return UsuarioCreado(usuario, password);
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

    // No se puede quitar al único admin
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
    await _db.collection('usuarios').doc(usuarioId).update(actualizado.toMap());
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
    await _db.collection('usuarios').doc(usuarioId).update(actualizado.toMap());
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
