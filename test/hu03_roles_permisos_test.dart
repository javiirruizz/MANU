import 'package:flutter_test/flutter_test.dart';
import 'package:manu/data/usuario_repository.dart';
import 'package:manu/models/usuario.dart';

void main() {
  group('HU 03 - Gestión de roles y permisos mediante control de accesos', () {
    late UsuarioRepository repository;
    late Usuario admin;
    late Usuario profesor;
    late Usuario alumno;
    late Usuario familiar;

    setUp(() {
      repository = UsuarioRepository();

      admin = Usuario(
        id: 'admin_1',
        nombre: 'Carlos Delgado',
        dni: '12345678A',
        telefonoContacto: '600112233',
        fechaNacimiento: DateTime(1985, 3, 14),
        rol: RolUsuario.administrador,
      );

      profesor = Usuario(
        id: 'profe_1',
        nombre: 'María Morales',
        dni: '87654321B',
        telefonoContacto: '611223344',
        fechaNacimiento: DateTime(1990, 7, 22),
        rol: RolUsuario.profesor,
      );

      alumno = Usuario(
        id: 'alum_1',
        nombre: 'Lucas Gómez',
        dni: '98765432D',
        telefonoContacto: '633445566',
        fechaNacimiento: DateTime(2012, 5, 18),
        rol: RolUsuario.alumno,
      );

      familiar = Usuario(
        id: 'fam_1',
        nombre: 'Laura Sánchez',
        dni: '45678912C',
        telefonoContacto: '622334455',
        fechaNacimiento: DateTime(1988, 11, 5),
        rol: RolUsuario.familiar,
      );
    });

    test(
      'Prueba de aceptación 1: Un administrador puede asignar y modificar el rol de un usuario y sus permisos se actualizan en consecuencia',
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
      'Prueba de aceptación 2: Un administrador puede conceder o revocar permisos específicos de forma granular a un usuario',
      () async {
        // Inicialmente el profesor no gestiona pictogramas
        expect(
          profesor.permisos.contains(PermisoUsuario.gestionarPictogramas),
          isFalse,
        );

        // El administrador le concede explícitamente el permiso de gestionar pictogramas
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

        // El administrador le revoca el permiso de gestionar el menú escolar
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
      'Prueba de aceptación 3: Un usuario sin rol de administrador intenta modificar roles o permisos y el sistema bloquea la acción denegando el acceso',
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
      'Prueba de aceptación 4: Control de accesos en acciones del sistema para garantizar la privacidad y control por perfil',
      () {
        // Un administrador puede ejecutar cualquier acción
        expect(
          () => repository.verificarAcceso(
            usuario: admin,
            permisoRequerido: PermisoUsuario.gestionarUsuarios,
          ),
          returnsNormally,
        );

        // Un profesor tiene acceso a gestionar tareas, pero no a gestionar usuarios
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

        // Un familiar tiene acceso a autorizaciones, pero no a modificar el menú escolar
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

        // Un alumno tiene acceso a marcar tareas, pero no a ver el panel de seguimiento psicopedagógico
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
      'Prueba de aceptación 5: Protección del sistema impidiendo retirar el rol al único administrador existente',
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
      'Retrocompatibilidad y serialización de permisos en Usuario',
      () {
        // Usuario serializado a mapa incluye lista de permisos
        final map = profesor.toMap();
        expect(map['rol'], 'profesor');
        expect(map['permisos'], isA<List>());
        expect(map['permisos'], contains('gestionarTareas'));

        // Deserialización sin campo permisos adopta los valores por defecto del rol
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
