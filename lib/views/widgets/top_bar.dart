import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/pictograma_repository.dart';
import '../../data/usuario_repository.dart';
import '../../models/pictograma.dart';
import 'gestion_roles_dialog.dart';
import 'pictograma_selector_dialog.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_view_model.dart';

/// Barra superior: logo, pestañas y accesos rápidos.
class TopBar extends StatelessWidget {
  const TopBar({super.key, this.selectedIndex = 0});

  final int selectedIndex;

  static const _tabs = [
    'Día a día',
    'Mes y festivos',
    'Fin de semana',
    'Mis datos',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Text(
            'Mi Agenda',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.tabTrack,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: _TabItem(
                        label: _tabs[i],
                        selected: i == selectedIndex,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          _SquareButton(
            icon: Icons.admin_panel_settings_outlined,
            tooltip: 'Gestión de Roles y Permisos (HU 03)',
            background: AppColors.tabTrack,
            color: AppColors.primary,
            onTap: () async {
              final usuario = context.read<AuthViewModel>().usuario;
              if (usuario == null) return;
              await showDialog(
                context: context,
                builder: (_) => GestionRolesDialog(
                  repository: UsuarioRepository(),
                  solicitante: usuario,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _SquareButton(
            icon: Icons.photo_library_outlined,
            tooltip: 'Biblioteca de Pictogramas (HU 05)',
            background: AppColors.badge,
            color: AppColors.primary,
            onTap: () async {
              final seleccionado = await showDialog<Pictograma>(
                context: context,
                builder: (_) => PictogramaSelectorDialog(
                  repository: PictogramaRepository(),
                ),
              );
              if (seleccionado != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Pictograma seleccionado: ${seleccionado.nombre}',
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          const _SquareButton(
            icon: Icons.volume_up_outlined,
            tooltip: 'Voz',
            background: AppColors.greenLight,
            color: AppColors.greenDark,
          ),
          const SizedBox(width: 8),
          const _SquareButton(
            icon: Icons.settings_outlined,
            tooltip: 'Ajustes',
          ),
          const SizedBox(width: 8),
          const _SquareButton(icon: Icons.person_outline, tooltip: 'Perfil'),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    // TODO: navegar a las otras pantallas cuando existan.
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.tooltip,
    this.background = AppColors.tabTrack,
    this.color = AppColors.textDark,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color background;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap ?? () {},
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: color),
          ),
        ),
      ),
    );
  }
}
