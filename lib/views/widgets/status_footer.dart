import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

/// Pie de página con el estado de la conexión.
class StatusFooter extends StatelessWidget {
  const StatusFooter({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: mostrar el estado real de la conexión.
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: AppColors.green),
          SizedBox(width: 8),
          Text('Modo tablet especial · Conectado', style: TextStyle(fontSize: 12)),
          Spacer(),
          Text('PFTVA / Hospitalarias', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
