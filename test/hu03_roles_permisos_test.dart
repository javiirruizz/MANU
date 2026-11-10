import 'package:flutter_test/flutter_test.dart';
import 'package:manu/data/usuario_repository.dart';
import 'package:manu/models/usuario.dart';

void main() {
  group('HU 03 - Roles y permisos', () {
    late UsuarioRepository repository;
    late Usuario admin;
    late Usuario profesor;
    late Usuario alumno;
    late Usuario familiar;

    setUp(() {
      repository = UsuarioRepository();

      admin = Usuario(
        id: 'admin_1',
        nombreUsuario: 'admin',
        nombre: 'Usuario Administrador',
        dni: '00000001A',
        telefonoContacto: '600000001',
        fechaNacimiento: DateTime(1985, 1, 1),
        rol: RolUsuario.administrador,
      );

      profesor = Usuario(
        id: 'profe_1',
        nombreUsuario: 'profesor',
        nombre: 'Usuario Profesor',
        dni: '00000002B',
        telefonoContacto: '600000002',
        fechaNacimiento: DateTime(1990, 1, 1),
        rol: RolUsuario.profesor,
      );

      alumno = Usuario(
        id: 'alum_1',
        nombreUsuario: 'alumno1',
        nombre: 'Usuario Alumno 1',
        dni: '00000004D',
        telefonoContacto: '600000004',
        fechaNacimiento: DateTime(2012, 1, 1),
        rol: RolUsuario.alumno,
      );

      familiar = Usuario(
        id: 'fam_1',
        nombreUsuario: 'familiar',
        nombre: 'Usuario Familiar',
        dni: '00000003C',
        telefonoContacto: '600000003',
        fechaNacimiento: DateTime(1988, 1, 1),
        rol: RolUsuario.familiar,
      );
    });

    test(
      'un admin puede cambiar el rol de un usuario',
      () async {
        // Alumno inicialmente solo puede marcar tareas y gestionar tiempo libre
        expect(alumno.rol, RolUsuario.alumno);
        expect(alumno.tienePermiso(PermisoUsuario.gestionarTareas), isFalse);

        // El administrador promociona al usuario a profesor
        final usuarioPromocionado = await repository.cambiarRol(
          solicitante: admin,
          usuarioId: 'alum_1',
          nuevoRol: RolUsuario.profesor,
        );

        expect(usuarioPromocionado.rol, RolUsuario.profesor);
        expect(
          usuarioPromocionado.tienePermiso(PermisoUsuario.gestionarTareas),
          isTrue,
        );
        expect(
          usuarioPromocionado.tienePermiso(PermisoUsuario.gestionarMenu),
          isTrue,
        );
      },
    );

    test(
      'un admin puede conceder o revocar permisos individuales',
      () async {
        // Inicialmente el profesor no gestiona pictogramas
        expect(
          profesor.permisos.contains(PermisoUsuario.gestionarPictogramas),
          isFalse,
        );

        // El administrador le concede el permiso de gestionar pictogramas
        final profesorConPermiso = await repository.concederPermiso(
          solicitante: admin,
          usuarioId: 'profe_1',
          permiso: PermisoUsuario.gestionarPictogramas,
        );

        expect(
          profesorConPermiso.permisos.contains(
            PermisoUsuario.gestionarPictogramas,
          ),
          isTrue,
        );

        // El administrador le revoca el permiso del menú
        final profesorSinMenu = await repository.revocarPermiso(
          solicitante: admin,
          usuarioId: 'profe_1',
          permiso: PermisoUsuario.gestionarMenu,
        );

        expect(
          profesorSinMenu.permisos.contains(PermisoUsuario.gestionarMenu),
          isFalse,
        );
      },
    );

    test(
      'un usuario sin rol admin no puede modificar roles ni permisos',
      () async {
        // Un alumno intenta cambiarse el rol a administrador
        expect(
          () => repository.cambiarRol(
            solicitante: alumno,
            usuarioId: 'alum_1',
            nuevoRol: RolUsuario.administrador,
          ),
          throwsA(isA<AccesoDenegadoException>()),
        );

        // Un profesor intenta modificar permisos de otro usuario
        expect(
          () => repository.concederPermiso(
            solicitante: profesor,
            usuarioId: 'alum_1',
            permiso: PermisoUsuario.gestionarUsuarios,
          ),
          throwsA(isA<AccesoDenegadoException>()),
        );
      },
    );

    test(
      'verificar acceso según el rol de cada usuario',
      () {
        // Admin puede hacer cualquier cosa
        expect(
          () => repository.verificarAcceso(
            usuario: admin,
            permisoRequerido: PermisoUsuario.gestionarUsuarios,
          ),
          returnsNormally,
        );

        // Profesor puede gestionar tareas pero no usuarios
        expect(
          () => repository.verificarAcceso(
            usuario: profesor,
            permisoRequerido: PermisoUsuario.gestionarTareas,
          ),
          returnsNormally,
        );
        expect(
          () => repository.verificarAcceso(
            usuario: profesor,
            permisoRequerido: PermisoUsuario.gestionarUsuarios,
          ),
          throwsA(isA<AccesoDenegadoException>()),
        );

        // Familiar puede autorizar pero no modificar menú
        expect(
          () => repository.verificarAcceso(
            usuario: familiar,
            permisoRequerido: PermisoUsuario.autorizarActividades,
          ),
          returnsNormally,
        );
        expect(
          () => repository.verificarAcceso(
            usuario: familiar,
            permisoRequerido: PermisoUsuario.gestionarMenu,
          ),
          throwsA(isA<AccesoDenegadoException>()),
        );

        // Alumno puede marcar tareas pero no ver seguimiento
        expect(
          () => repository.verificarAcceso(
            usuario: alumno,
            permisoRequerido: PermisoUsuario.marcarTareas,
          ),
          returnsNormally,
        );
        expect(
          () => repository.verificarAcceso(
            usuario: alumno,
            permisoRequerido: PermisoUsuario.verSeguimiento,
          ),
          throwsA(isA<AccesoDenegadoException>()),
        );
      },
    );

    test(
      'no se puede quitar el rol al único administrador',
      () async {
        // Intentar cambiar el rol del único administrador debe ser bloqueado por seguridad
        expect(
          () => repository.cambiarRol(
            solicitante: admin,
            usuarioId: 'admin_1',
            nuevoRol: RolUsuario.alumno,
          ),
          throwsA(isA<AccesoDenegadoException>()),
        );
      },
    );

    test(
      'serialización y deserialización de permisos',
      () {
        // Usuario serializado a mapa incluye lista de permisos
        final map = profesor.toMap();
        expect(map['rol'], 'profesor');
        expect(map['permisos'], isA<List>());
        expect(map['permisos'], contains('gestionarTareas'));

        // Sin campo permisos en el mapa se usan los del rol
        final mapSinPermisos = {
          'nombre': 'Estudiante Nuevo',
          'dni': '11223344K',
          'telefonoContacto': '655443322',
          'fechaNacimiento': '2014-02-10T00:00:00.000',
          'rol': 'alumno',
        };

        final usuarioRestaurado = Usuario.fromMap(
          'nuevo_1',
          mapSinPermisos,
        );
        expect(usuarioRestaurado.rol, RolUsuario.alumno);
        expect(
          usuarioRestaurado.tienePermiso(PermisoUsuario.marcarTareas),
          isTrue,
        );
        expect(
          usuarioRestaurado.tienePermiso(PermisoUsuario.gestionarUsuarios),
          isFalse,
        );
      },
    );
  });
}
