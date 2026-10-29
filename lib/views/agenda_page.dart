import 'package:flutter/material.dart';
import 'widgets/date_bar.dart';
import 'widgets/menu_section.dart';
import 'widgets/mood_section.dart';
import 'widgets/routine_section.dart';
import 'widgets/status_footer.dart';
import 'widgets/top_bar.dart';

/// Pantalla "Día a día" para tablet en horizontal.
class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            children: [
              const TopBar(),
              const SizedBox(height: 10),
              const DateBar(),
              const SizedBox(height: 12),
              const Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 7, child: RoutineSection()),
                    SizedBox(width: 12),
                    Expanded(flex: 5, child: MenuSection()),
                    SizedBox(width: 12),
                    Expanded(flex: 4, child: MoodSection()),
                  ],
                ),
              ),
              const StatusFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
