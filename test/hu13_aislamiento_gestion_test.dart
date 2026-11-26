import 'package:flutter_test/flutter_test.dart';
import 'package:manu/core/app_theme.dart';
import 'package:manu/data/tarea_repository.dart';
import 'package:manu/data/usuario_repository.dart';
import 'package:manu/main.dart';
import 'package:manu/models/usuario.dart';
import 'package:manu/viewmodels/auth_view_model.dart';
import 'package:manu/viewmodels/gestor_tareas_view_model.dart';
import 'package:manu/views/admin_home_page.dart';
import 'package:manu/views/agenda_page.dart';
import 'package:manu/views/profesor/gestor_tareas_page.dart';
import 'package:manu/views/profesor/gestor_tareas_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class _FakeAuthViewModel extends ChangeNotifier implements AuthViewModel {
  _FakeAuthViewModel(this._usuario);

  final Usuario? _usuario;

  @override
  Usuario? get usuario => _usuario;

  @override
  bool get inicializando => false;

  @override
  bool get cargando => false;

  @override
  String? get error => null;

  @override
  Future<bool> iniciarSesion(String nombreUsuario, String password) async =>
      true;

  @override
  Future<bool> cambiarPassword(String nueva) async => true;

  @override
  Future<void> cerrarSesion() async {}
}

void main() {
  const admin = Usuario(
    id: 'admin_1',
    nombreUsuario: 'admin1',
    nombre: 'Usuario Administrador 1',
    rol: RolUsuario.administrador,
  );

  const profesor = Usuario(
    id: 'profe_1',
    nombreUsuario: 'profe1',
    nombre: 'Usuario Profesor 1',
    rol: RolUsuario.profesor,
  );

  const familiar = Usuario(
    id: 'fam_1',
    nombreUsuario: 'familiar1',
    nombre: 'Usuario Familiar 1',
    rol: RolUsuario.familiar,
  );

  const alumno = Usuario(
    id: 'alum_1',
    nombreUsuario: 'alumno1',
    nombre: 'Usuario Alumno 1',
    rol: RolUsuario.alumno,
  );

  Widget envuelveApp(Widget child, {required Usuario? usuario}) {
    return ChangeNotifierProvider<AuthViewModel>.value(
      value: _FakeAuthViewModel(usuario),
      child: MaterialApp(
        theme: AppTheme.build(tema: TemaColor.azul),
        home: child,
      ),
    );
  }

  void configurarPantalla(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  group('HU 13 - Aislamiento de acciones de gestión del profesorado', () {
    testWidgets(
      'un alumno entra en su interfaz directa sin acciones de gestión',
      (tester) async {
        configurarPantalla(tester);
        await tester.pumpWidget(envuelveApp(const AuthGate(), usuario: alumno));
        await tester.pump();
        await tester.pump();

        expect(find.text('Mi Agenda'), findsOneWidget);
        expect(find.text('Mi horario'), findsOneWidget);
        expect(find.text('MENÚ'), findsOneWidget);

        // Ninguna acción de gestión debe aparecer en la agenda del alumno
        expect(find.text('Panel del profesor'), findsNothing);
        expect(find.text('Planificar tareas'), findsNothing);
        expect(find.text('Gestión de usuarios'), findsNothing);
        expect(find.text('Roles y permisos'), findsNothing);
        expect(find.text('Gestión de menú semanal'), findsNothing);
        expect(find.text('Biblioteca de pictogramas'), findsNothing);
        expect(find.text('Enviar aviso urgente'), findsNothing);
        expect(find.text('Editar'), findsNothing);
        expect(find.text('Volver al panel'), findsNothing);
        expect(
          find.byTooltip('Gestión de Roles y Permisos (HU 03)'),
          findsNothing,
        );
        expect(
          find.byTooltip('Biblioteca de Pictogramas (HU 05)'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'un profesor accede aislado a su panel de gestión y no a la agenda',
      (tester) async {
        configurarPantalla(tester);
        await tester.pumpWidget(
          envuelveApp(const AuthGate(), usuario: profesor),
        );
        await tester.pump();

        expect(find.text('Panel del profesor'), findsOneWidget);
        expect(find.text('Planificar tareas'), findsOneWidget);
        expect(find.text('Gestión de menú semanal'), findsOneWidget);
        expect(find.text('Enviar aviso urgente'), findsOneWidget);
        expect(find.text('Vista previa de la agenda'), findsOneWidget);

        expect(find.text('Mi horario'), findsNothing);
        expect(find.text('Gestión de usuarios'), findsNothing);
        expect(find.text('Roles y permisos'), findsNothing);
      },
    );

    testWidgets(
      'la vista previa de la agenda para profesor y admin no mezcla controles de gestión',
      (tester) async {
        configurarPantalla(tester);
        await tester.pumpWidget(
          envuelveApp(const AdminHomePage(), usuario: profesor),
        );
        await tester.pump();

        await tester.tap(find.text('Vista previa de la agenda'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(
          find.text(
            'Vista previa de la agenda del alumno · Tus acciones de gestión están aisladas en tu panel',
          ),
          findsOneWidget,
        );
        expect(find.text('Volver al panel'), findsOneWidget);
        expect(find.text('Editar'), findsNothing);
        expect(
          find.byTooltip('Gestión de Roles y Permisos (HU 03)'),
          findsNothing,
        );
        expect(
          find.byTooltip('Biblioteca de Pictogramas (HU 05)'),
          findsNothing,
        );

        await tester.tap(find.text('Volver al panel'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        expect(find.text('Panel del profesor'), findsOneWidget);
        expect(find.byType(AgendaPage), findsNothing);

        // Reiniciar el árbol antes de comprobar la vista directa con rol administrador
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          envuelveApp(const AgendaPage(), usuario: admin),
        );
        await tester.pump();
        await tester.pump();

        expect(
          find.text(
            'Vista previa de la agenda del alumno · Tus acciones de gestión están aisladas en tu panel',
          ),
          findsOneWidget,
        );
        expect(find.text('Editar'), findsNothing);
        expect(
          find.byTooltip('Gestión de Roles y Permisos (HU 03)'),
          findsNothing,
        );
        expect(
          find.byTooltip('Biblioteca de Pictogramas (HU 05)'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'AdminHomePage bloquea el acceso si entra un alumno o un familiar',
      (tester) async {
        configurarPantalla(tester);

        await tester.pumpWidget(
          envuelveApp(const AdminHomePage(), usuario: alumno),
        );
        await tester.pump();

        expect(find.textContaining('Acceso denegado'), findsOneWidget);
        expect(find.text('Planificar tareas'), findsNothing);
        expect(find.text('Gestión de menú semanal'), findsNothing);
        expect(find.text('Vista previa de la agenda'), findsNothing);

        await tester.pumpWidget(
          envuelveApp(const AdminHomePage(), usuario: familiar),
        );
        await tester.pump();

        expect(find.textContaining('Acceso denegado'), findsOneWidget);
        expect(find.text('Planificar tareas'), findsNothing);
        expect(find.text('Gestión de menú semanal'), findsNothing);
        expect(find.text('Vista previa de la agenda'), findsNothing);
      },
    );

    testWidgets(
      'GestorTareasScreen bloquea el acceso si entra un alumno',
      (tester) async {
        configurarPantalla(tester);
        final vm = GestorTareasViewModel(
          tareaRepo: TareaRepository(),
          usuarioRepo: UsuarioRepository(),
        );
        addTearDown(vm.dispose);

        await tester.pumpWidget(
          envuelveApp(
            GestorTareasScreen(viewModel: vm, profesorId: alumno.id),
            usuario: alumno,
          ),
        );
        await tester.pump();

        expect(find.textContaining('Acceso denegado'), findsOneWidget);
        expect(find.byType(GestorTareasPage), findsNothing);
      },
    );

    testWidgets(
      'las opciones de gestión en AdminHomePage respetan los permisos asignados',
      (tester) async {
        configurarPantalla(tester);

        await tester.pumpWidget(
          envuelveApp(const AdminHomePage(), usuario: admin),
        );
        await tester.pump();

        expect(find.text('Panel de administración'), findsOneWidget);
        expect(find.text('Biblioteca de pictogramas'), findsOneWidget);
        expect(find.text('Gestión de usuarios'), findsOneWidget);
        expect(find.text('Roles y permisos'), findsOneWidget);
        expect(find.text('Gestión de menú semanal'), findsOneWidget);
        expect(find.text('Enviar aviso urgente'), findsOneWidget);
        expect(find.text('Planificar tareas'), findsOneWidget);
        expect(find.text('Vista previa de la agenda'), findsOneWidget);

        const profesorSinMenu = Usuario(
          id: 'profe_2',
          nombreUsuario: 'profe2',
          nombre: 'Usuario Profesor 2',
          rol: RolUsuario.profesor,
          permisos: {PermisoUsuario.gestionarTareas},
        );

        await tester.pumpWidget(
          envuelveApp(const AdminHomePage(), usuario: profesorSinMenu),
        );
        await tester.pump();

        expect(find.text('Planificar tareas'), findsOneWidget);
        expect(find.text('Enviar aviso urgente'), findsOneWidget);
        expect(find.text('Gestión de menú semanal'), findsNothing);
      },
    );
  });
}
