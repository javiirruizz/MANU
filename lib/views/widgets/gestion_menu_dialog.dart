import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import '../../data/menu_repository.dart';
import '../../data/pictograma_repository.dart';
import '../../models/menu.dart';
import '../../models/pictograma.dart';
import 'pictograma_selector_dialog.dart';

class GestionMenuDialog extends StatefulWidget {
  const GestionMenuDialog({
    super.key,
    required this.repository,
    this.comedorId = 'comedor_principal',
  });

  final MenuRepository repository;
  final String comedorId;

  @override
  State<GestionMenuDialog> createState() => _GestionMenuDialogState();
}

class _GestionMenuDialogState extends State<GestionMenuDialog> {
  static const _diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
  ];

  late DateTime _lunesActual;
  int _diaSeleccionado = 0; // 0 = Lunes ... 4 = Viernes
  bool _guardando = false;

  final _p1Ctrl = TextEditingController();
  final _p2Ctrl = TextEditingController();
  final _postreCtrl = TextEditingController();

  Pictograma? _picto1;
  Pictograma? _picto2;
  Pictograma? _pictoPostre;

  final _pictoRepo = PictogramaRepository(
    firestore: FirebaseFirestore.instance,
  );

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _lunesActual = DateTime(
      hoy.year,
      hoy.month,
      hoy.day,
    ).subtract(Duration(days: hoy.weekday - 1));
    if (hoy.weekday >= 1 && hoy.weekday <= 5) {
      _diaSeleccionado = hoy.weekday - 1;
    }
    _cargarDia(_diaSeleccionado);
  }

  @override
  void dispose() {
    _p1Ctrl.dispose();
    _p2Ctrl.dispose();
    _postreCtrl.dispose();
    super.dispose();
  }

  DateTime get _fechaSeleccionada =>
      _lunesActual.add(Duration(days: _diaSeleccionado));

  Future<void> _cargarDia(int index) async {
    setState(() {
      _diaSeleccionado = index;
    });

    final fecha = _fechaSeleccionada;
    final lista = await widget.repository.getMenus(
      widget.comedorId,
      desde: fecha,
      hasta: fecha.add(const Duration(days: 1)),
    );

    if (!mounted) return;

    if (lista.isNotEmpty) {
      final m = lista.first;
      setState(() {
        _p1Ctrl.text = m.primerPlato.nombre;
        _p2Ctrl.text = m.segundoPlato.nombre;
        _postreCtrl.text = m.postre.nombre;
        _picto1 = m.primerPlato.pictogramaId != null
            ? Pictograma(
                idPictograma: m.primerPlato.pictogramaId!,
                nombre: m.primerPlato.nombre,
                imagenUrl: m.primerPlato.pictogramaUrl,
              )
            : null;
        _picto2 = m.segundoPlato.pictogramaId != null
            ? Pictograma(
                idPictograma: m.segundoPlato.pictogramaId!,
                nombre: m.segundoPlato.nombre,
                imagenUrl: m.segundoPlato.pictogramaUrl,
              )
            : null;
        _pictoPostre = m.postre.pictogramaId != null
            ? Pictograma(
                idPictograma: m.postre.pictogramaId!,
                nombre: m.postre.nombre,
                imagenUrl: m.postre.pictogramaUrl,
              )
            : null;
      });
    } else {
      setState(() {
        _p1Ctrl.clear();
        _p2Ctrl.clear();
        _postreCtrl.clear();
        _picto1 = null;
        _picto2 = null;
        _pictoPostre = null;
      });
    }
  }

  Future<Pictograma?> _elegirPictograma(String textoInicial) async {
    return showDialog<Pictograma>(
      context: context,
      builder: (_) => PictogramaSelectorDialog(
        repository: _pictoRepo,
        consultaInicial: textoInicial,
      ),
    );
  }

  Future<void> _guardar() async {
    if (_p1Ctrl.text.trim().isEmpty &&
        _p2Ctrl.text.trim().isEmpty &&
        _postreCtrl.text.trim().isEmpty) {
      return;
    }

    setState(() => _guardando = true);

    final menu = Menu(
      id: widget.repository.buildDocId(widget.comedorId, _fechaSeleccionada),
      comedorId: widget.comedorId,
      fecha: _fechaSeleccionada,
      primerPlato: PlatoMenu(
        nombre: _p1Ctrl.text.trim(),
        pictogramaId: _picto1?.idPictograma,
        pictogramaUrl: _picto1?.urlResuelta,
      ),
      segundoPlato: PlatoMenu(
        nombre: _p2Ctrl.text.trim(),
        pictogramaId: _picto2?.idPictograma,
        pictogramaUrl: _picto2?.urlResuelta,
      ),
      postre: PlatoMenu(
        nombre: _postreCtrl.text.trim(),
        pictogramaId: _pictoPostre?.idPictograma,
        pictogramaUrl: _pictoPostre?.urlResuelta,
      ),
    );

    await widget.repository.guardarMenuDia(menu);

    if (!mounted) return;
    setState(() => _guardando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menú del ${_diasSemana[_diaSeleccionado]} guardado'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  Widget _campoPlato({
    required String etiqueta,
    required TextEditingController controller,
    required Pictograma? pictograma,
    required ValueChanged<Pictograma?> onPictogramaChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: etiqueta,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () async {
            final elegido = await _elegirPictograma(controller.text);
            if (elegido != null) onPictogramaChanged(elegido);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.cardBlue,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: pictograma != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.network(
                      pictograma.urlResuelta,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.image, color: AppColors.primary),
                    ),
                  )
                : const Tooltip(
                    message: 'Asociar pictograma',
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gestión del Menú Semanal'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selector de día de la semana (Lunes a Viernes)
              Wrap(
                spacing: 6,
                children: List.generate(_diasSemana.length, (i) {
                  final fechaDia = _lunesActual.add(Duration(days: i));
                  return ChoiceChip(
                    label: Text('${_diasSemana[i]} ${fechaDia.day}'),
                    selected: _diaSeleccionado == i,
                    onSelected: (_) => _cargarDia(i),
                  );
                }),
              ),
              const SizedBox(height: 16),
              _campoPlato(
                etiqueta: 'Primer plato',
                controller: _p1Ctrl,
                pictograma: _picto1,
                onPictogramaChanged: (p) => setState(() => _picto1 = p),
              ),
              const SizedBox(height: 12),
              _campoPlato(
                etiqueta: 'Segundo plato',
                controller: _p2Ctrl,
                pictograma: _picto2,
                onPictogramaChanged: (p) => setState(() => _picto2 = p),
              ),
              const SizedBox(height: 12),
              _campoPlato(
                etiqueta: 'Postre',
                controller: _postreCtrl,
                pictograma: _pictoPostre,
                onPictogramaChanged: (p) => setState(() => _pictoPostre = p),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        ElevatedButton.icon(
          onPressed: _guardando ? null : _guardar,
          icon: const Icon(Icons.save),
          label: Text(_guardando ? 'Guardando...' : 'Guardar día'),
        ),
      ],
    );
  }
}
