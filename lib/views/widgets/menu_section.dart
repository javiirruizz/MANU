import 'package:material_ui/material_ui.dart';

import '../../core/app_theme.dart'; // Importante
import '../../core/tamanos.dart';
import '../../data/menu_repository.dart';
import '../../models/menu.dart';
import 'pictograma_imagen.dart';
import 'section_card.dart';

/// Menú del comedor: tiempo real con Firestore y pictogramas.
/// El menú de hoy ocupa todo el hueco disponible (sin scroll); el semanal
/// se abre en una ventana aparte.
class MenuSection extends StatefulWidget {
  const MenuSection({
    super.key,
    this.comedorId = 'comedor_principal',
    this.repository,
  });

  final String comedorId;

  /// Solo para pruebas: fuente de menús alternativa.
  final MenuRepository? repository;

  @override
  State<MenuSection> createState() => _MenuSectionState();
}

class _MenuSectionState extends State<MenuSection> {
  late final _repo = widget.repository ?? MenuRepository();
  late final Stream<Menu?> _hoy = _repo.watchMenuDeHoy(widget.comedorId);

  void _verSemana() {
    showDialog<void>(
      context: context,
      builder: (_) =>
          _MenuSemanaDialog(repo: _repo, comedorId: widget.comedorId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SectionCard(
      icon: Icons.restaurant,
      title: 'MENÚ',
      badge: 'Hoy',
      accion: TextButton.icon(
        onPressed: _verSemana,
        icon: Icon(
          Icons.calendar_view_week,
          size: context.medida(26),
          color: p.primary,
        ),
        label: Text(
          'Semana',
          style: TextStyle(
            fontSize: context.letra(Letra.detalle),
            fontWeight: FontWeight.w700,
            color: p.primary,
          ),
        ),
      ),
      child: StreamBuilder<Menu?>(
        stream: _hoy,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final menu = snapshot.data;
          if (menu == null) {
            return Center(
              child: Text(
                'Hoy no hay menú publicado.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.letra(Letra.normal),
                  color: p.textSoft,
                ),
              ),
            );
          }
          final items = _platos(menu);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                Expanded(
                  child: _MealTile(
                    label: items[i].label,
                    plato: items[i].plato,
                    iconoReserva: items[i].icon,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

typedef _Plato = ({String label, PlatoMenu plato, IconData icon});

List<_Plato> _platos(Menu menu) => [
  (label: '1º PLATO', plato: menu.primerPlato, icon: Icons.soup_kitchen),
  (label: '2º PLATO', plato: menu.segundoPlato, icon: Icons.dinner_dining),
  (label: 'POSTRE', plato: menu.postre, icon: Icons.icecream),
].where((item) => item.plato.nombre.isNotEmpty).toList();

/// Un plato: pictograma grande y nombre. Se adapta al alto que le toque.
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
    final p = context.palette;
    final tieneUrlManual =
        plato.pictogramaUrl != null && plato.pictogramaUrl!.isNotEmpty;

    return Semantics(
      label: '$label: ${plato.nombre}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: p.cardTint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            // El pictograma ocupa el alto de la tarjeta (con un tope)
            final lado = c.maxHeight.clamp(40.0, context.medida(130));
            final picto = tieneUrlManual
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      plato.pictogramaUrl!,
                      width: lado,
                      height: lado,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => PictogramaImagen(
                        consulta: plato.nombre,
                        size: lado,
                        iconoReserva: iconoReserva,
                      ),
                    ),
                  )
                : PictogramaImagen(
                    consulta: plato.nombre,
                    size: lado,
                    iconoReserva: iconoReserva,
                  );
            return Row(
              children: [
                picto,
                const SizedBox(width: 12),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: (c.maxWidth - lado - 12).clamp(40, 2000),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: context.letra(Letra.detalle),
                              fontWeight: FontWeight.w800,
                              color: p.primary,
                            ),
                          ),
                          Text(
                            plato.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: context.letra(Letra.normal),
                              color: p.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Menú de la semana en una ventana: un día por columna.
class _MenuSemanaDialog extends StatelessWidget {
  const _MenuSemanaDialog({required this.repo, required this.comedorId});

  final MenuRepository repo;
  final String comedorId;

  static const _nombresDias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hoy = DateTime.now();
    final lunes = DateTime(hoy.year, hoy.month, hoy.day - (hoy.weekday - 1));
    final tam = MediaQuery.sizeOf(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: tam.width * 0.9,
        height: tam.height * 0.85,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.restaurant,
                    color: p.primary,
                    size: context.medida(34),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Menú de la semana',
                      style: TextStyle(
                        fontSize: context.letra(Letra.destacado),
                        fontWeight: FontWeight.w800,
                        color: p.textDark,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: Text(
                      'Cerrar',
                      style: TextStyle(fontSize: context.letra(Letra.normal)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: StreamBuilder<List<Menu>>(
                  stream: repo.watchMenusSemana(comedorId, lunes),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final porDia = {
                      for (final m in snapshot.data ?? const <Menu>[])
                        m.fecha.weekday: m,
                    };
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var d = 1; d <= 5; d++) ...[
                          if (d > 1) const SizedBox(width: 10),
                          Expanded(
                            child: _DiaSemana(
                              titulo:
                                  '${_nombresDias[d - 1]} ${lunes.add(Duration(days: d - 1)).day}',
                              esHoy: d == hoy.weekday,
                              menu: porDia[d],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiaSemana extends StatelessWidget {
  const _DiaSemana({
    required this.titulo,
    required this.esHoy,
    required this.menu,
  });

  final String titulo;
  final bool esHoy;
  final Menu? menu;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final m = menu;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: esHoy ? p.cardTint : p.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esHoy ? p.primary : p.divider,
          width: esHoy ? 3 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.letra(Letra.normal),
              fontWeight: FontWeight.w800,
              color: p.primary,
            ),
          ),
          const SizedBox(height: 8),
          if (m == null)
            Expanded(
              child: Center(
                child: Text(
                  'Sin menú',
                  style: TextStyle(
                    fontSize: context.letra(Letra.detalle),
                    color: p.textSoft,
                  ),
                ),
              ),
            )
          else
            for (final item in _platos(m))
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final lado =
                          (c.maxHeight - context.letra(Letra.detalle) * 2.6)
                              .clamp(24.0, context.medida(110));
                      return Column(
                        children: [
                          PictogramaImagen(
                            consulta: item.plato.nombre,
                            size: lado,
                            iconoReserva: item.icon,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.plato.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: context.letra(Letra.detalle),
                              fontWeight: FontWeight.w700,
                              color: p.textDark,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Botón con dibujo para ver qué hay de comer hoy (abre el menú en una ventana).
class BotonMenuComedor extends StatelessWidget {
  const BotonMenuComedor({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final alto = context.medida(60);
    return Semantics(
      button: true,
      label: 'Ver el menú del comedor',
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFFFFE9C7), // tono cálido, fácil de reconocer
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => mostrarMenuComedor(context),
          child: SizedBox(
            height: alto,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PictogramaImagen(
                    consulta: 'comer',
                    size: alto - 14,
                    iconoReserva: Icons.restaurant,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Menú del comedor',
                    style: TextStyle(
                      fontSize: context.letra(Letra.normal),
                      fontWeight: FontWeight.w800,
                      color: p.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ventana con el menú de hoy (y desde ahí, el de la semana).
Future<void> mostrarMenuComedor(BuildContext context) {
  final tam = MediaQuery.sizeOf(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: (tam.width * 0.5).clamp(420.0, 900.0),
        height: tam.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(child: MenuSection()),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton.icon(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close),
                label: Text(
                  'Cerrar',
                  style: TextStyle(fontSize: ctx.letra(Letra.normal)),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(ctx.medida(60)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
