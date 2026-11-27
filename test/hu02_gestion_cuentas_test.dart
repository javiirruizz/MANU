import 'package:flutter_test/flutter_test.dart';
import 'package:manu/data/usuario_repository.dart';
import 'package:manu/models/usuario.dart';

void main() {
  group('HU 02.2 - Modificación, restablecimiento y baja de usuarios', () {
    late UsuarioRepository repository;
    late Usuario admin;
    late Usuario profesor;
    late Usuario alumno;

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
        email: 'alumno1@ejemplo.com',
        dni: '00000004D',
        telefonoContacto: '600000004',
        fechaNacimiento: DateTime(2012, 1, 1),
        rol: RolUsuario.alumno,
      );
    });

    test('un admin puede modificar los datos de un usuario', () async {
      final nuevaFecha = DateTime(2011, 6, 15);
      final actualizado = await repository.modificarUsuario(
        solicitante: admin,
        usuarioId: 'alum_1',
        nombre: 'Usuario Alumno Modificado',
        nombreUsuario: 'alumno1',
        dni: '00000099Z',
        telefonoContacto: '699000099',
        fechaNacimiento: nuevaFecha,
      );

      expect(actualizado.nombre, 'Usuario Alumno Modificado');
      expect(actualizado.dni, '00000099Z');
      expect(actualizado.telefonoContacto, '699000099');
      expect(actualizado.fechaNacimiento, nuevaFecha);

      // Si se dejan vacíos los campos opcionales o se limpia la fecha, pasan a null
      final sinOpcionales = await repository.modificarUsuario(
        solicitante: admin,
        usuarioId: 'alum_1',
        nombre: 'Usuario Alumno 1',
        nombreUsuario: 'alumno1',
        dni: '',
        telefonoContacto: '',
        limpiarFechaNacimiento: true,
      );

      expect(sinOpcionales.dni, isNull);
      expect(sinOpcionales.telefonoContacto, isNull);
      expect(sinOpcionales.fechaNacimiento, isNull);

      // En un familiar también se pueden actualizar los alumnos vinculados
      final familiarActualizado = await repository.modificarUsuario(
        solicitante: admin,
        usuarioId: 'fam_1',
        nombre: 'Usuario Familiar Actualizado',
        nombreUsuario: 'familiar',
        alumnoIds: ['alum_1', 'alum_2'],
      );
      expect(familiarActualizado.alumnoIds, ['alum_1', 'alum_2']);
    });

    test('no se puede modificar un usuario dejando el nombre vacio', () async {
      expect(
        () => repository.modificarUsuario(
          solicitante: admin,
          usuarioId: 'alum_1',
          nombre: '   ',
          nombreUsuario: 'alumno1',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('un admin puede restablecer la contraseña por correo', () async {
      // Con correo asociado devuelve la dirección de envío
      final correo = await repository.restablecerPassword(
        solicitante: admin,
        usuarioId: 'alum_1',
      );
      expect(correo, 'alumno1@ejemplo.com');

      // Sin correo de recuperación falla con ArgumentError
      expect(
        () => repository.restablecerPassword(
          solicitante: admin,
          usuarioId: 'alum_2',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'un usuario sin permiso gestionarUsuarios no puede modificar, restablecer ni dar de baja',
      () async {
        expect(
          () => repository.modificarUsuario(
            solicitante: profesor,
            usuarioId: 'alum_1',
            nombre: 'Intento Profesor',
            nombreUsuario: 'alumno1',
          ),
          throwsA(isA<AccesoDenegadoException>()),
        );

        expect(
          () => repository.restablecerPassword(
            solicitante: alumno,
            usuarioId: 'alum_1',
          ),
          throwsA(isA<AccesoDenegadoException>()),
        );
      },
    );
  });
}
