import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'data/agenda_repository.dart';
import 'data/auth_repository.dart';
import 'firebase_options.dart';
import 'viewmodels/agenda_view_model.dart';
import 'viewmodels/auth_view_model.dart';
import 'views/admin_home_page.dart';
import 'views/agenda_page.dart';
import 'views/cambiar_password_page.dart';
import 'views/login_page.dart';

import 'data/notification_service.dart';
import 'data/tarea_repository.dart';
import 'data/usuario_repository.dart';
import 'viewmodels/gestor_tareas_view_model.dart';
import 'views/profesor/gestor_tareas_screen.dart';
import 'models/usuario.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final notificaciones = NotificationService();
  await notificaciones.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(MiAgendaApp(notificaciones: notificaciones));
}

class MiAgendaApp extends StatelessWidget {
  const MiAgendaApp({super.key, required this.notificaciones});

  final NotificationService notificaciones;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(AuthRepository())),
        ChangeNotifierProxyProvider<AuthViewModel, AgendaViewModel>(
          create: (_) => AgendaViewModel(
            AgendaRepository(),
            TareaRepository(),
            notificaciones,
          ),
          update: (_, auth, agenda) {
            final u = auth.usuario;
            final alumnoId = (u != null && u.rol == RolUsuario.alumno)
                ? u.id
                : null;
            Future.microtask(() => agenda!.setAlumno(alumnoId));
            return agenda!;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Mi Agenda',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}

/// Decide qué pantalla mostrar según el estado de la sesión.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    if (auth.inicializando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final usuario = auth.usuario;
    if (usuario == null) return const LoginPage();
    if (usuario.debeCambiarPassword) return const CambiarPasswordPage();
    if (usuario.esAdministrador) return const AdminHomePage();
    if (usuario.esAdministrador) {
      return const AdminHomePage();
    }

    if (usuario.rol == RolUsuario.profesor) {
      return GestorTareasScreen(
        profesorId: usuario.id,
        viewModel: GestorTareasViewModel(
          tareaRepo: TareaRepository(),
          usuarioRepo: UsuarioRepository(),
        ),
      );
    }

    return const AgendaPage();
  }
}
