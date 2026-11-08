import 'package:flutter/material.dart';

import '../../data/pictograma_repository.dart';
import '../../viewmodels/pictograma_view_model.dart';

class PictogramaSelectorDialog extends StatefulWidget {
  const PictogramaSelectorDialog({
    super.key,
    required this.repository,
    this.consultaInicial = '',
  });

  final PictogramaRepository repository;
  final String consultaInicial;

  @override
  State<PictogramaSelectorDialog> createState() =>
      _PictogramaSelectorDialogState();
}

class _PictogramaSelectorDialogState extends State<PictogramaSelectorDialog> {
  late final PictogramaViewModel _vm;
  late final TextEditingController _searchCtrl;
  final TextEditingController _etiquetaCtrl = TextEditingController();
  final TextEditingController _archivoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = PictogramaViewModel(widget.repository);
    _searchCtrl = TextEditingController(text: widget.consultaInicial);
    if (widget.consultaInicial.isNotEmpty) {
      _vm.buscar(widget.consultaInicial);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _etiquetaCtrl.dispose();
    _archivoCtrl.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _vm,
      builder: (context, _) {
        return AlertDialog(
          title: const Text('Biblioteca de Pictogramas (ARASAAC)'),
          content: SizedBox(
            width: 600,
            height: 450,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Buscador por etiqueta textual
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por descripción o etiqueta textual',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _vm.buscar,
                ),
                const SizedBox(height: 12),

                // Sección para subir nuevo pictograma PNG
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _etiquetaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Etiqueta (ej. Excursión)',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _archivoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Archivo (ej. icono.png)',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final ok = await _vm.subirNuevoPictograma(
                          nombreArchivo: _archivoCtrl.text,
                          etiquetaTextual: _etiquetaCtrl.text,
                        );
                        if (ok) {
                          _etiquetaCtrl.clear();
                          _archivoCtrl.clear();
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Subir PNG'),
                    ),
                  ],
                ),

                // Mensaje de bloqueo si se intenta subir PDF u otro formato
                if (_vm.mensajeError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _vm.mensajeError,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Cuadrícula de resultados
                Expanded(
                  child: _vm.cargando
                      ? const Center(child: CircularProgressIndicator())
                      : _vm.resultados.isEmpty
                          ? const Center(
                              child: Text('No se encontraron pictogramas.'),
                            )
                          : GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: _vm.resultados.length,
                              itemBuilder: (context, index) {
                                final p = _vm.resultados[index];
                                return InkWell(
                                  onTap: () => Navigator.of(context).pop(p),
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Image.network(
                                              p.urlResuelta,
                                              errorBuilder:
                                                  (context, error, stackTrace) =>
                                                      const Icon(
                                                Icons.image_outlined,
                                                size: 48,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            p.nombre,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}

