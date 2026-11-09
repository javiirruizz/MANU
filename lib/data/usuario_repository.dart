import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/usuario.dart';

class AccesoDenegadoException implements Exception {
  const AccesoDenegadoException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

class UsuarioRepository {
  UsuarioRepository({FirebaseFirestore? firestore}) : _db = firestore;

  final FirebaseFirestore? _db;

  // Usuarios de prueba
  static final List<Usuario> _usuariosIniciales = [
    Usuario(
      id: 'admin_1',
      nombre: 'Carlos Delgado',
      dni: '12345678A',
      telefonoContacto: '600112233',
      fechaNacimiento: DateTime(1985, 3, 14),
      rol: RolUsuario.administrador,
      puedeEditarPerfil: true,
    ),
    Usuario(
      id: 'profe_1',
      nombre: 'María Morales',
      dni: '87654321B',
      telefonoContacto: '611223344',
      fechaNacimiento: DateTime(1990, 7, 22),
      rol: RolUsuario.profesor,
      puedeEditarPerfil: true,
    ),
    Usuario(
      id: 'fam_1',
      nombre: 'Laura Sánchez',
      dni: '45678912C',
      telefonoContacto: '622334455',
      fechaNacimiento: DateTime(1988, 11, 5),
      rol: RolUsuario.familiar,
      puedeEditarPerfil: false,
    ),
    Usuario(
      id: 'alum_1',
      nombre: 'Lucas Gómez',
      dni: '98765432D',
      telefonoContacto: '633445566',
      fechaNacimiento: DateTime(2012, 5, 18),
      rol: RolUsuario.alumno,
      puedeEditarPerfil: false,
    ),
    Usuario(
      id: 'alum_2',
      nombre: 'Sofía Ruiz',
      dni: '54321678E',
      telefonoContacto: '644556677',
      fechaNacimiento: DateTime(2013, 9, 30),
      rol: RolUsuario.alumno,
      puedeEditarPerfil: false,
    ),
  ];

  final List<Usuario> _usuariosLocales = List.of(_usuariosIniciales);

  Future<void> precargarUsuariosEnBD() async {
    final db = _db;
    if (db == null) return;

    final snap = await db.collection('usuarios').limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = db.batch();
    for (final u in _usuariosIniciales) {
      final ref = db.collection('usuarios').doc(u.id);
      batch.set(ref, u.toMap());
    }
    await batch.commit();
  }

  // Lista todos los usuarios registrados y permite filtrar por rol.
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
            .map((doc) => Usuario.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList();
      }
    }

    if (filtroRol != null) {
      return _usuariosLocales.where((u) => u.rol == filtroRol).toList();
    }
    return List.unmodifiable(_usuariosLocales);
  }

  // Métodos de alumnos y profesores
  Future<List<Usuario>> getAlumnos() async {
    return listarUsuarios(filtroRol: RolUsuario.alumno);
  }

  Future<List<Usuario>> getProfesores() async {
    return listarUsuarios(filtroRol: RolUsuario.profesor);
  }

  Stream<List<Usuario>> streamAlumnos() {
    final db = _db;
    if (db == null) return const Stream.empty();
    return db
        .collection('usuarios')
        .where('rol', isEqualTo: RolUsuario.alumno.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Usuario.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Obtiene un usuario específico por su identificador.
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

  Future<Usuario?> getUsuarioPorId(String id) => obtenerUsuarioPorId(id);

  // Lanza AccesoDenegado si no tiene permiso
  void verificarAcceso({
    required Usuario usuario,
    required PermisoUsuario permisoRequerido,
    String? accion,
  }) {
    if (!usuario.tienePermiso(permisoRequerido)) {
      final detalle = accion != null ? ' para realizar: $accion' : '';
      throw AccesoDenegadoException(
        'Acceso denegado: El usuario "${usuario.nombre}" con rol "${usuario.rol.name}" '
        'no tiene el permiso "${permisoRequerido.nombre}"$detalle.',
      );
    }
  }

  bool puedeEjecutarAccion({
    required Usuario usuario,
    required PermisoUsuario permisoRequerido,
  }) {
    return usuario.tienePermiso(permisoRequerido);
  }

  /// Modifica el rol de un usuario existente.
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

    final usuarioActual = await obtenerUsuarioPorId(usuarioId);
    if (usuarioActual == null) {
      throw ArgumentError('Usuario con id $usuarioId no encontrado.');
    }

    if (usuarioActual.rol == RolUsuario.administrador &&
        nuevoRol != RolUsuario.administrador) {
      final todos = await listarUsuarios();
      final numAdmins =
          todos.where((u) => u.rol == RolUsuario.administrador).length;
      if (numAdmins <= 1) {
        throw const AccesoDenegadoException(
          'Operación no permitida: Debe existir al menos un administrador activo en el sistema.',
        );
      }
    }

    final nuevosPermisos = resetearPermisos
        ? PermisoUsuario.permisosPorDefecto(nuevoRol)
        : usuarioActual.permisos;

    final usuarioActualizado = usuarioActual.copyWith(
      rol: nuevoRol,
      permisos: nuevosPermisos,
    );

    final index = _usuariosLocales.indexWhere((u) => u.id == usuarioId);
    if (index != -1) {
      _usuariosLocales[index] = usuarioActualizado;
    } else {
      _usuariosLocales.add(usuarioActualizado);
    }

    final db = _db;
    if (db != null) {
      await db
          .collection('usuarios')
          .doc(usuarioId)
          .update(usuarioActualizado.toMap());
    }

    return usuarioActualizado;
  }

  /// Modifica de forma granular el conjunto de permisos de un usuario.
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

    final usuarioActual = await obtenerUsuarioPorId(usuarioId);
    if (usuarioActual == null) {
      throw ArgumentError('Usuario con id $usuarioId no encontrado.');
    }

    final usuarioActualizado = usuarioActual.copyWith(
      permisos: Set.unmodifiable(nuevosPermisos),
    );

    final index = _usuariosLocales.indexWhere((u) => u.id == usuarioId);
    if (index != -1) {
      _usuariosLocales[index] = usuarioActualizado;
    } else {
      _usuariosLocales.add(usuarioActualizado);
    }

    final db = _db;
    if (db != null) {
      await db
          .collection('usuarios')
          .doc(usuarioId)
          .update(usuarioActualizado.toMap());
    }

    return usuarioActualizado;
  }

  /// Concede un permiso específico a un usuario.
  Future<Usuario> concederPermiso({
    required Usuario solicitante,
    required String usuarioId,
    required PermisoUsuario permiso,
  }) async {
    final usuarioActual = await obtenerUsuarioPorId(usuarioId);
    if (usuarioActual == null) {
      throw ArgumentError('Usuario con id $usuarioId no encontrado.');
    }

    final nuevos = {...usuarioActual.permisos, permiso};
    return actualizarPermisos(
      solicitante: solicitante,
      usuarioId: usuarioId,
      nuevosPermisos: nuevos,
    );
  }

  /// Revoca un permiso específico a un usuario.
  Future<Usuario> revocarPermiso({
    required Usuario solicitante,
    required String usuarioId,
    required PermisoUsuario permiso,
  }) async {
    final usuarioActual = await obtenerUsuarioPorId(usuarioId);
    if (usuarioActual == null) {
      throw ArgumentError('Usuario con id $usuarioId no encontrado.');
    }

    final nuevos = usuarioActual.permisos.where((p) => p != permiso).toSet();
    return actualizarPermisos(
      solicitante: solicitante,
      usuarioId: usuarioId,
      nuevosPermisos: nuevos,
    );
  }
}