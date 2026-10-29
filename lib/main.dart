import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'data/agenda_repository.dart';
import 'viewmodels/agenda_view_model.dart';
import 'views/agenda_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MiAgendaApp());
}

class MiAgendaApp extends StatelessWidget {
  const MiAgendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AgendaViewModel(AgendaRepository()),
      child: MaterialApp(
        title: 'Mi Agenda',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AgendaPage(),
      ),
    );
  }
}