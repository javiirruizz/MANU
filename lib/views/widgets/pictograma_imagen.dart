import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/arasaac_service.dart';

/// Muestra un pictograma dentro de un recuadro blanco.
///
/// Se resuelve en este orden:
///  1. [url] (imagen directa, p. ej. un PNG subido por el centro)
///  2. [id] numérico de ARASAAC
///  3. [consulta]: palabra que se busca en ARASAAC
/// Si no hay imagen (o falla la conexión) se muestra [iconoReserva].
class PictogramaImagen extends StatefulWidget {
  const PictogramaImagen({
    super.key,
    this.url,
    this.id,
    this.consulta,
    this.size = 80,
    this.iconoReserva = Icons.image_outlined,
    this.opacidad = 1,
  });

  final String? url;
  final String? id;
  final String? consulta;
  final double size;
  final IconData iconoReserva;
  final double opacidad;

  @override
  State<PictogramaImagen> createState() => _PictogramaImagenState();
}

class _PictogramaImagenState extends State<PictogramaImagen> {
  late Future<String?> _futuroUrl;

  @override
  void initState() {
    super.initState();
    _futuroUrl = _resolver();
  }

  @override
  void didUpdateWidget(covariant PictogramaImagen old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url ||
        old.id != widget.id ||
        old.consulta != widget.consulta) {
      _futuroUrl = _resolver();
    }
  }

  Future<String?> _resolver() async {
    final directa = widget.url;
    if (directa != null && directa.startsWith('http')) return directa;

    final idNumerico = int.tryParse(widget.id ?? '');
    if (idNumerico != null) return ArasaacService.urlImagen(idNumerico);

    final consulta = widget.consulta;
    if (consulta != null && consulta.trim().isNotEmpty) {
      final encontrado = await ArasaacService.instance.buscarId(consulta);
      if (encontrado != null) return ArasaacService.urlImagen(encontrado);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final reserva = Icon(
      widget.iconoReserva,
      color: AppColors.primary,
      size: widget.size * 0.5,
    );

    return Semantics(
      image: true,
      label: widget.consulta,
      child: Opacity(
        opacity: widget.opacidad,
        child: Container(
          width: widget.size,
          height: widget.size,
          padding: EdgeInsets.all(widget.size * 0.06),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 1.5),
          ),
          child: FutureBuilder<String?>(
            future: _futuroUrl,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              final url = snap.data;
              if (url == null) return Center(child: reserva);
              return Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Center(child: reserva),
              );
            },
          ),
        ),
      ),
    );
  }
}
