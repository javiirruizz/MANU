import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/app_theme.dart';
import 'data/tarea_repository.dart';
import 'data/usuario_repository.dart';
import 'firebase_options.dart';
import 'viewmodels/gestor_tareas_view_model.dart';
import 'views/profesor/gestor_tareas_screen.dart';

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
    // Instanciamos los repositorios y el ViewModel de tareas
    final tareaRepo = TareaRepository();
    final usuarioRepo = UsuarioRepository();
    final gestorTareasVM = GestorTareasViewModel(
      tareaRepo: tareaRepo,
      usuarioRepo: usuarioRepo,
    );

    return MaterialApp(
      title: 'Mi Agenda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Cargamos GestorTareasScreen que conecta el ViewModel y la Base de Datos
      home: GestorTareasScreen(
        viewModel: gestorTareasVM,
        profesorId: 'profesor_demo',
      ),
    );
  }
}