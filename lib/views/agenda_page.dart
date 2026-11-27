import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../data/agenda_repository.dart';
import '../data/notification_service.dart';
import '../data/tarea_repository.dart';
import '../models/usuario.dart';
import '../viewmodels/agenda_view_model.dart';
import '../viewmodels/auth_view_model.dart';
import 'widgets/date_bar.dart';
import 'widgets/routine_section.dart';
import 'widgets/top_bar.dart';

/// Pantalla "Día a día" para tablet en horizontal.
/// El cuerpo es solo el horario; el menú y el fin de día están en su cabecera.
/// Todo se ajusta al alto de la pantalla, sin scroll.
class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key, this.tareaRepository});

  /// Solo para pruebas: fuente de tareas alternativa.
  final TareaRepository? tareaRepository;

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthViewModel>().usuario;
    final esVistaPreviaGestion =
        usuario != null &&
        (usuario.esAdministrador || usuario.rol == RolUsuario.profesor);

    return ChangeNotifierProvider(
      create: (ctx) => AgendaViewModel(
        alumnoId: ctx.read<AuthViewModel>().usuario?.id ?? '',
        repository: AgendaRepository(),
        tareaRepository: tareaRepository ?? TareaRepository(),
        notificaciones: NotificationService(),
      ),
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (esVistaPreviaGestion) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.palette.badge,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              color: context.palette.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Vista previa de la agenda del alumno · Tus acciones de gestión están aisladas en tu panel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: context.palette.primary,
                                ),
                              ),
                            ),
                            if (Navigator.of(context).canPop())
                              TextButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: context.palette.primary,
                                ),
                                label: Text(
                                  'Volver al panel',
                                  style: TextStyle(
                                    color: context.palette.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const TopBar(),
                    const SizedBox(height: 10),
                    const DateBar(),
                    const SizedBox(height: 12),
                    const Expanded(child: RoutineSection()),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
