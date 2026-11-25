import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import '../../data/notificacion_repository.dart';
import '../../data/pictograma_repository.dart';
import '../../data/usuario_repository.dart';
import '../../models/notificacion.dart';
import '../../models/pictograma.dart';
import '../../models/usuario.dart';
import 'pictograma_selector_dialog.dart';

class EnviarNotificacionDialog extends StatefulWidget {
  const EnviarNotificacionDialog({
    super.key,
    required this.tutorId,
    required this.tutorNombre,
  });

  final String tutorId;
  final String tutorNombre;

  @override
  State<EnviarNotificacionDialog> createState() =>
      _EnviarNotificacionDialogState();
}

class _EnviarNotificacionDialogState extends State<EnviarNotificacionDialog> {
  final _mensajeCtrl = TextEditingController();
  final _notiService = NotificacionService();
  final _pictoRepo = PictogramaRepository(
    firestore: FirebaseFirestore.instance,
  );

  List<Usuario> _alumnos = [];
  String? _alumnoSeleccionadoId;
  Pictograma? _pictogramaSeleccionado;
  bool _cargandoAlumnos = true;
  bool _enviando = false;

  static const _plantillasRapidas = [
    'Es hora de recoger',
    'Vamos al comedor',
    'Ven un momento con el profe',
    '¡Muy buen trabajo!',
  ];

  @override
  void initState() {
    super.initState();
    _cargarAlumnos();
  }

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarAlumnos() async {
    final lista = await UsuarioRepository().getAlumnos();
    if (!mounted) return;
    setState(() {
      _alumnos = lista;
      if (lista.isNotEmpty) {
        _alumnoSeleccionadoId = lista.first.id;
      }
      _cargandoAlumnos = false;
    });
  }

  Future<void> _seleccionarPictograma() async {
    final elegido = await showDialog<Pictograma>(
      context: context,
      builder: (_) => PictogramaSelectorDialog(
        repository: _pictoRepo,
        consultaInicial: _mensajeCtrl.text.trim(),
      ),
    );
    if (elegido != null && mounted) {
      setState(() => _pictogramaSeleccionado = elegido);
    }
  }

  Future<void> _enviar() async {
    final texto = _mensajeCtrl.text.trim();
    if (_alumnoSeleccionadoId == null || texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un alumno y escribe un mensaje.'),
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    final ahora = DateTime.now();
    final aviso = Notificacion(
      idNotificacion: '',
      idAlumnos: [_alumnoSeleccionadoId!],
      fecha: ahora,
      hora: ahora,
      titulo: 'Aviso de ${widget.tutorNombre}',
      mensaje: texto,
      pictogramaId: _pictogramaSeleccionado?.idPictograma,
      pictogramaUrl: _pictogramaSeleccionado?.urlResuelta,
      emisorId: widget.tutorId,
      emisorNombre: widget.tutorNombre,
      urgente: true,
    );

    await _notiService.guardarNotificacionEnBD(aviso);

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aviso urgente enviado al dispositivo del alumno.'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.notifications_active, color: AppColors.primary),
          SizedBox(width: 10),
          Text('Enviar aviso urgente a alumno'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: _cargandoAlumnos
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Selector de alumno destinatario
                    DropdownButtonFormField<String>(
                      initialValue: _alumnoSeleccionadoId,
                      decoration: const InputDecoration(
                        labelText: 'Alumno destinatario *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: _alumnos
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.nombre),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _alumnoSeleccionadoId = val),
                    ),
                    const SizedBox(height: 14),

                    // 2. Mensajes rápidos adaptados
                    const Text(
                      'Mensajes rápidos:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _plantillasRapidas
                          .map(
                            (plantilla) => ActionChip(
                              label: Text(plantilla),
                              onPressed: () {
                                setState(() {
                                  _mensajeCtrl.text = plantilla;
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),

                    // 3. Cuerpo del aviso
                    TextField(
                      controller: _mensajeCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Mensaje del recordatorio *',
                        hintText: 'Ej. Recoge la mochila, nos vamos al patio',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Pictograma de ARASAAC asociado
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _pictogramaSeleccionado != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      _pictogramaSeleccionado!.urlResuelta,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.image_search,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pictograma de apoyo (ARASAAC)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _pictogramaSeleccionado?.nombre ??
                                      'Ninguno seleccionado',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _seleccionarPictograma,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Elegir'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _enviando ? null : _enviar,
          icon: const Icon(Icons.send),
          label: Text(_enviando ? 'Enviando...' : 'Enviar aviso'),
        ),
      ],
    );
  }
}
