import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart'; // Importante
import '../../data/menu_repository.dart';
import '../../models/menu.dart';
import '../../viewmodels/auth_view_model.dart';
import 'gestion_menu_dialog.dart';
import 'pictograma_imagen.dart';
import 'section_card.dart';

/// Menú del comedor: tiempo real con Firestore, vista diaria/semanal y pictogramas.
class MenuSection extends StatefulWidget {
  const MenuSection({super.key, this.comedorId = 'comedor_principal'});

  final String comedorId;

  @override
  State<MenuSection> createState() => _MenuSectionState();
}

class _MenuSectionState extends State<MenuSection> {
  final _repo = MenuRepository();
  bool _verSemana = false;

  static const _nombresDias = [
    '',
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  DateTime get _lunesActual {
    final hoy = DateTime.now();
    return DateTime(
      hoy.year,
      hoy.month,
      hoy.day,
    ).subtract(Duration(days: hoy.weekday - 1));
  }

  bool _puedeEditar(BuildContext context) {
    final usuario = context.watch<AuthViewModel>().usuario;
    if (usuario == null) return false;
    final rolTexto = usuario.rol.toString().toLowerCase();
    return rolTexto.contains('profesor') || rolTexto.contains('admin');
  }

  void _abrirGestion() {
    showDialog(
      context: context,
      builder: (_) =>
          GestionMenuDialog(repository: _repo, comedorId: widget.comedorId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esGestor = _puedeEditar(context);

    return SectionCard(
      icon: Icons.restaurant,
      title: _verSemana ? 'MENÚ SEMANAL' : 'MENÚ',
      badge: _verSemana ? 'Semana' : 'Hoy',
      expand: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _verSemana = !_verSemana),
                icon: Icon(
                  _verSemana ? Icons.today : Icons.calendar_view_week,
                  size: 18,
                  color: context.palette.primary, // Cambio dinámico
                ),
                label: Text(
                  _verSemana ? 'Ver hoy' : 'Ver semana',
                  style: TextStyle(
                    color: context.palette.primary,
                  ), // Cambio dinámico
                ),
              ),
              if (esGestor)
                ElevatedButton.icon(
                  onPressed: _abrirGestion,
                  icon: const Icon(Icons.edit_calendar, size: 16),
                  label: const Text('Editar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.primary, // Cambio dinámico
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!_verSemana)
            StreamBuilder<Menu?>(
              stream: _repo.watchMenuDeHoy(widget.comedorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final menu = snapshot.data;
                if (menu == null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No hay menú publicado para hoy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.palette.textSoft,
                      ), // Cambio dinámico sin const
                    ),
                  );
                }
                return _MenuDiaColumn(menu: menu);
              },
            )
          else
            StreamBuilder<List<Menu>>(
              stream: _repo.watchMenusSemana(widget.comedorId, _lunesActual),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final menus = snapshot.data ?? [];
                if (menus.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No hay menús publicados esta semana.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.palette.textSoft,
                      ), // Cambio dinámico sin const
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final m in menus) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 6),
                        child: Text(
                          '${_nombresDias[m.fecha.weekday]} ${m.fecha.day}/${m.fecha.month}',
                          style: TextStyle(
                            // Sin const
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: context.palette.primary, // Cambio dinámico
                          ),
                        ),
                      ),
                      _MenuDiaColumn(menu: m),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MenuDiaColumn extends StatelessWidget {
  const _MenuDiaColumn({required this.menu});

  final Menu menu;

  @override
  Widget build(BuildContext context) {
    final items = [
      (label: '1º PLATO', plato: menu.primerPlato, icon: Icons.soup_kitchen),
      (label: '2º PLATO', plato: menu.segundoPlato, icon: Icons.dinner_dining),
      (label: 'POSTRE', plato: menu.postre, icon: Icons.icecream),
    ].where((item) => item.plato.nombre.isNotEmpty).toList();

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _MealTile(
            label: items[i].label,
            plato: items[i].plato,
            iconoReserva: items[i].icon,
          ),
        ],
      ],
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({
    required this.label,
    required this.plato,
    required this.iconoReserva,
  });

  final String label;
  final PlatoMenu plato;
  final IconData iconoReserva;

  @override
  Widget build(BuildContext context) {
    final tieneUrlManual =
        plato.pictogramaUrl != null && plato.pictogramaUrl!.isNotEmpty;

    return Semantics(
      label: '$label: ${plato.nombre}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.palette.cardTint, // Cambio dinámico (antes cardBlue)
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            if (tieneUrlManual)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  plato.pictogramaUrl!,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => PictogramaImagen(
                    consulta: plato.nombre,
                    size: 76,
                    iconoReserva: iconoReserva,
                  ),
                ),
              )
            else
              PictogramaImagen(
                consulta: plato.nombre,
                size: 76,
                iconoReserva: iconoReserva,
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      // Sin const
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.palette.primary, // Cambio dinámico
                    ),
                  ),
                  Text(
                    plato.nombre,
                    style: TextStyle(
                      // Sin const
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: context.palette.textDark, // Añadido color
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
