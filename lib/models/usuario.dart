import 'package:cloud_firestore/cloud_firestore.dart';

enum RolUsuario { familiar, administrador, profesor, alumno }

class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.dni,
    required this.telefonoContacto,
    required this.fechaNacimiento,
    required this.rol,
    this.puedeEditarPerfil = false,
    this.preferenciaVisualizacion = '',
    this.preferenciaEnvios = '',
    this.comedorId,
  });

  final String id;
  final String nombre;
  final String dni;
  final String telefonoContacto;
  final DateTime fechaNacimiento;
  final RolUsuario rol;
  final bool puedeEditarPerfil;
  final String preferenciaVisualizacion;
  final String preferenciaEnvios;
  final String? comedorId;

  int get edad {
    final hoy = DateTime.now();
    var e = hoy.year - fechaNacimiento.year;
    if (hoy.month < fechaNacimiento.month ||
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day)) {
      e--;
    }
    return e;
  }

  factory Usuario.fromMap(String id, Map<String, dynamic> m) => Usuario(
    id: id,
    nombre: m['nombre'] ?? '',
    dni: m['dni'] ?? '',
    telefonoContacto: m['telefonoContacto'] ?? '',
    fechaNacimiento: (m['fechaNacimiento'] as Timestamp).toDate(),
    rol: RolUsuario.values.byName(m['rol']),
    puedeEditarPerfil: m['puedeEditarPerfil'] ?? false,
    preferenciaVisualizacion: m['preferenciaVisualizacion'] ?? '',
    preferenciaEnvios: m['preferenciaEnvios'] ?? '',
    comedorId: m['comedorId'],
  );

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'dni': dni,
    'telefonoContacto': telefonoContacto,
    'fechaNacimiento': Timestamp.fromDate(fechaNacimiento),
    'rol': rol.name,
    'puedeEditarPerfil': puedeEditarPerfil,
    'preferenciaVisualizacion': preferenciaVisualizacion,
    'preferenciaEnvios': preferenciaEnvios,
    'comedorId': comedorId,
  };
}
