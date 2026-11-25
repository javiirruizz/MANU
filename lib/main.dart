import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'data/auth_repository.dart';
import 'firebase_options.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/theme_view_model.dart';
import 'views/admin_home_page.dart';
import 'views/agenda_page.dart';
import 'views/cambiar_password_page.dart';
import 'views/familiar/familiar_home_page.dart';
import 'views/login_page.dart';
import 'models/usuario.dart';

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
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(AuthRepository()),
        ), //[cite: 13]
        ChangeNotifierProvider(
          create: (_) => ThemeViewModel(),
        ), // Inyectamos el gestor de temas
      ],
      // Usamos Consumer para que MaterialApp escuche los cambios y se redibuje al instante
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVM, child) {
          return MaterialApp(
            title: 'Mi Agenda',
            debugShowCheckedModeBanner: false, //[cite: 13]
            // Conectamos el constructor dinámico en lugar de AppTheme.light
            theme: AppTheme.build(
              tema: themeVM.temaActual,
              altoContraste: themeVM.altoContraste,
            ),
            home: const AuthGate(), //[cite: 13]
          );
        },
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
    if (usuario.esAdministrador || usuario.rol == RolUsuario.profesor) {
      return const AdminHomePage();
    }
    if (usuario.rol == RolUsuario.familiar) {
      return const FamiliarHomePage();
    }
    return AgendaPage();
  }
}
