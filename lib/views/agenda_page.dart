import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/agenda_repository.dart';
import '../data/notification_service.dart';
import '../data/tarea_repository.dart';
import '../viewmodels/agenda_view_model.dart';
import '../viewmodels/auth_view_model.dart';
import 'widgets/date_bar.dart';
import 'widgets/menu_section.dart';
import 'widgets/mood_section.dart';
import 'widgets/routine_section.dart';
import 'widgets/top_bar.dart';
import 'widgets/selector_tema_widget.dart';

/// Pantalla "Día a día" para tablet en horizontal.
/// El horario ocupa la columna grande; menú y estado de ánimo, la pequeña.
class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  void _mostrarAjustesTema(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const Padding(
        padding: EdgeInsets.all(16.0),
        child: SelectorTemaWidget(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AgendaViewModel(
        alumnoId: ctx.read<AuthViewModel>().usuario!.id,
        repository: AgendaRepository(),
        tareaRepository: TareaRepository(),
        notificaciones: NotificationService(),
      ),
      child: Builder(
        builder: (context) {
          return Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () => _mostrarAjustesTema(context),
              tooltip: 'Personalizar aspecto',
              child: const Icon(Icons.palette),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const TopBar(),
                    const SizedBox(height: 10),
                    const DateBar(),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: const [
                          Expanded(flex: 8, child: RoutineSection()),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  MenuSection(),
                                  SizedBox(height: 12),
                                  MoodSection(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}