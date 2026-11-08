import 'package:cloud_firestore/cloud_firestore.dart';

enum RolUsuario { familiar, administrador, profesor, alumno }

/// Permisos granulares de acceso en la plataforma educativa.
enum PermisoUsuario {
  gestionarUsuarios(
    nombre: 'Gestión de usuarios',
    descripcion: 'Alta, baja y modificación de cuentas de usuario.',
  ),
  gestionarRolesYPermisos(
    nombre: 'Gestión de roles y permisos',
    descripcion: 'Control de accesos, asignación de perfiles y permisos en el sistema.',
  ),
  gestionarAulas(
    nombre: 'Gestión de aulas',
    descripcion: 'Asignación de alumnos a aulas y organización de espacios escolares.',
  ),
  gestionarPictogramas(
    nombre: 'Gestión de pictogramas',
    descripcion: 'Subir, catalogar y organizar la biblioteca de imágenes y apoyos visuales.',
  ),
  gestionarTareas(
    nombre: 'Planificación de tareas',
    descripcion: 'Crear, programar y asignar tareas escolares individuales o grupales.',
  ),
  gestionarMenu(
    nombre: 'Gestión del menú escolar',
    descripcion: 'Publicar, actualizar y consultar los menús del comedor escolar.',
  ),
  verSeguimiento(
    nombre: 'Panel de seguimiento',
    descripcion: 'Consultar progreso académico, historial de emociones e incidencias.',
  ),
  gestionarPlanesB(
    nombre: 'Gestión de Planes B',
    descripcion: 'Configurar incidencias logísticas y alternativas ante imprevistos.',
  ),
  marcarTareas(
    nombre: 'Progreso y cierre de tareas',
    descripcion: 'Marcar tareas y pasos completados y registrar emociones.',
  ),
  gestionarTiempoLibre(
    nombre: 'Mi tiempo libre',
    descripcion: 'Gestionar actividades de ocio, galería fotográfica y red de amigos.',
  ),
  autorizarActividades(
    nombre: 'Autorizaciones y consentimientos',
    descripcion: 'Firma de autorizaciones de ocio y consentimientos RGPD/LOPDGDD.',
  );

  const PermisoUsuario({
    required this.nombre,
    required this.descripcion,
  });

  final String nombre;
  final String descripcion;

  /// Retorna el conjunto de permisos predeterminados para un rol.
  static Set<PermisoUsuario> permisosPorDefecto(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.administrador:
        return PermisoUsuario.values.toSet();
      case RolUsuario.profesor:
        return {
          PermisoUsuario.gestionarTareas,
          PermisoUsuario.gestionarMenu,
          PermisoUsuario.verSeguimiento,
          PermisoUsuario.gestionarPlanesB,
          PermisoUsuario.marcarTareas,
        };
      case RolUsuario.familiar:
        return {
          PermisoUsuario.verSeguimiento,
          PermisoUsuario.gestionarPlanesB,
          PermisoUsuario.autorizarActividades,
        };
      case RolUsuario.alumno:
        return {
          PermisoUsuario.marcarTareas,
          PermisoUsuario.gestionarTiempoLibre,
        };
    }
  }
}

class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.dni,
    required this.telefonoContacto,
    required this.fechaNacimiento,
    required this.rol,
    Set<PermisoUsuario>? permisos,
    this.puedeEditarPerfil = false,
    this.preferenciaVisualizacion = '',
    this.preferenciaEnvios = '',
    this.comedorId,
  }) : _permisos = permisos;

  final String id;
  final String nombre;
  final String dni;
  final String telefonoContacto;
  final DateTime fechaNacimiento;
  final RolUsuario rol;
  final Set<PermisoUsuario>? _permisos;
  final bool puedeEditarPerfil;
  final String preferenciaVisualizacion;
  final String preferenciaEnvios;
  final String? comedorId;

  /// Permisos asignados al usuario. Si no se especificaron de forma manual,
  /// se toman los permisos por defecto correspondientes a su rol.
  Set<PermisoUsuario> get permisos =>
      _permisos != null
          ? Set.unmodifiable(_permisos)
          : PermisoUsuario.permisosPorDefecto(rol);

  /// Indica si el usuario tiene rol de administrador.
  bool get esAdministrador => rol == RolUsuario.administrador;

  /// Comprueba si el usuario tiene concedido un permiso específico.
  /// Si es administrador, tiene acceso irrestricto de forma predeterminada.
  bool tienePermiso(PermisoUsuario permiso) {
    if (esAdministrador) return true;
    return permisos.contains(permiso);
  }

  int get edad {
    final hoy = DateTime.now();
    var e = hoy.year - fechaNacimiento.year;
    if (hoy.month < fechaNacimiento.month ||
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day)) {
      e--;
    }
    return e;
  }

  Usuario copyWith({
    String? id,
    String? nombre,
    String? dni,
    String? telefonoContacto,
    DateTime? fechaNacimiento,
    RolUsuario? rol,
    Set<PermisoUsuario>? permisos,
    bool? puedeEditarPerfil,
    String? preferenciaVisualizacion,
    String? preferenciaEnvios,
    String? comedorId,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      dni: dni ?? this.dni,
      telefonoContacto: telefonoContacto ?? this.telefonoContacto,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      rol: rol ?? this.rol,
      permisos: permisos ?? _permisos,
      puedeEditarPerfil: puedeEditarPerfil ?? this.puedeEditarPerfil,
      preferenciaVisualizacion:
          preferenciaVisualizacion ?? this.preferenciaVisualizacion,
      preferenciaEnvios: preferenciaEnvios ?? this.preferenciaEnvios,
      comedorId: comedorId ?? this.comedorId,
    );
  }

  factory Usuario.fromMap(String id, Map<String, dynamic> m) {
    DateTime parseFecha(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime(2000, 1, 1);
      return DateTime(2000, 1, 1);
    }

    final rol = RolUsuario.values.byName(m['rol'] ?? 'alumno');

    Set<PermisoUsuario>? permisos;
    if (m['permisos'] is List) {
      permisos = (m['permisos'] as List)
          .map((p) {
            try {
              return PermisoUsuario.values.byName(p.toString());
            } catch (_) {
              return null;
            }
          })
          .whereType<PermisoUsuario>()
          .toSet();
    }

    return Usuario(
      id: id,
      nombre: m['nombre'] ?? '',
      dni: m['dni'] ?? '',
      telefonoContacto: m['telefonoContacto'] ?? '',
      fechaNacimiento: parseFecha(m['fechaNacimiento']),
      rol: rol,
      permisos: permisos,
      puedeEditarPerfil: m['puedeEditarPerfil'] ?? false,
      preferenciaVisualizacion: m['preferenciaVisualizacion'] ?? '',
      preferenciaEnvios: m['preferenciaEnvios'] ?? '',
      comedorId: m['comedorId'],
    );
  }

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'dni': dni,
    'telefonoContacto': telefonoContacto,
    'fechaNacimiento': Timestamp.fromDate(fechaNacimiento),
    'rol': rol.name,
    'permisos': permisos.map((p) => p.name).toList(),
    'puedeEditarPerfil': puedeEditarPerfil,
    'preferenciaVisualizacion': preferenciaVisualizacion,
    'preferenciaEnvios': preferenciaEnvios,
    'comedorId': comedorId,
  };
}
