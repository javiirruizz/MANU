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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MiAgendaApp());
}

class MiAgendaApp extends StatelessWidget {
  const MiAgendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(AuthRepository())),
        ChangeNotifierProvider(
          create: (_) => AgendaViewModel(AgendaRepository()),
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
    return const AgendaPage();
  }
}
