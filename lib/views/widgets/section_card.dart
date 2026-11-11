import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

/// Tarjeta blanca con cabecera (icono, título y etiqueta opcional).
/// Con [expand] = true (por defecto) el [child] ocupa todo el espacio restante;
/// con false, la tarjeta solo ocupa lo que necesita su contenido.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.badge,
    this.expand = true,
  });

  final IconData icon;
  final String title;
  final String? badge;
  final Widget child;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.badge,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          if (expand) Expanded(child: child) else child,
        ],
      ),
    );
  }
}
