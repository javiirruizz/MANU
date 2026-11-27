import 'package:material_ui/material_ui.dart';

import '../../core/app_theme.dart';
import '../../core/tamanos.dart';

/// Tarjeta con cabecera (icono, título y etiqueta opcional).
/// Con [expand] = true (por defecto) el [child] ocupa todo el espacio restante;
/// con false, la tarjeta solo ocupa lo que necesita su contenido.
/// [accion] es un widget opcional a la derecha de la cabecera.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.badge,
    this.accion,
    this.expand = true,
  });

  final IconData icon;
  final String title;
  final String? badge;
  final Widget? accion;
  final Widget child;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: p.primary, size: context.medida(30)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.letra(Letra.normal),
                    fontWeight: FontWeight.w800,
                    color: p.textDark,
                  ),
                ),
              ),
              ?accion,
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: p.badge,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: context.letra(Letra.detalle),
                      fontWeight: FontWeight.w700,
                      color: p.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: p.divider),
          const SizedBox(height: 10),
          if (expand) Expanded(child: child) else child,
        ],
      ),
    );
  }
}
