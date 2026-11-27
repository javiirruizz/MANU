import 'dart:math';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TareaPdf {
  const TareaPdf({
    required this.hora,
    required this.nombre,
    this.pictogramaUrl,
  });
  final String hora; // p. ej. "09:00"
  final String nombre;
  final String? pictogramaUrl;
}

class DiaPdf {
  const DiaPdf(this.nombre, this.tareas);
  final String nombre; // p. ej. "Lunes"
  final List<TareaPdf> tareas;
}

class AgendaPdfService {
  /// Filas por página. Cada fila tiene altura fija, así ninguna tarea
  /// queda cortada entre dos páginas.
  static const _filasPorPagina = 4;
  static const _alturaFila = 104.0;
  static const _tamPicto = 56.0;

  Future<Uint8List> generar({
    required String titulo,
    required String subtitulo,
    required List<DiaPdf> dias,
  }) async {
    // Descarga los pictogramas una sola vez (los repetidos se reutilizan)
    final urls = {
      for (final d in dias)
        for (final t in d.tareas)
          if (t.pictogramaUrl != null && t.pictogramaUrl!.isNotEmpty)
            t.pictogramaUrl!,
    };
    final imagenes = <String, pw.ImageProvider>{};
    await Future.wait(
      urls.map((url) async {
        try {
          imagenes[url] = await networkImage(url);
        } catch (_) {
          // Sin imagen: la celda se imprime solo con hora y nombre
        }
      }),
    );

    final maxFilas = dias.fold<int>(0, (m, d) => max(m, d.tareas.length));
    final paginas = max(1, (maxFilas / _filasPorPagina).ceil());

    final doc = pw.Document(title: titulo);

    for (var p = 0; p < paginas; p++) {
      final desde = p * _filasPorPagina;

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    titulo,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    paginas > 1
                        ? '$subtitulo  ·  Página ${p + 1} de $paginas'
                        : subtitulo,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey700),
                defaultColumnWidth: const pw.FlexColumnWidth(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue100,
                    ),
                    children: [
                      for (final d in dias)
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            d.nombre,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  for (var f = 0; f < _filasPorPagina; f++)
                    pw.TableRow(
                      children: [
                        for (final d in dias)
                          _celda(
                            desde + f < d.tareas.length
                                ? d.tareas[desde + f]
                                : null,
                            imagenes,
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return doc.save();
  }

  pw.Widget _celda(TareaPdf? t, Map<String, pw.ImageProvider> imagenes) {
    if (t == null) return pw.SizedBox(height: _alturaFila);

    final img = t.pictogramaUrl == null ? null : imagenes[t.pictogramaUrl];

    return pw.Container(
      height: _alturaFila,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            t.hora,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          if (img != null)
            pw.Image(
              img,
              width: _tamPicto,
              height: _tamPicto,
              fit: pw.BoxFit.contain,
            )
          else
            pw.SizedBox(height: _tamPicto),
          pw.SizedBox(height: 2),
          pw.Text(
            t.nombre,
            textAlign: pw.TextAlign.center,
            maxLines: 2,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Abre el diálogo de impresión del sistema (también permite guardar en PDF).
  Future<void> imprimir(Uint8List bytes, String nombreArchivo) =>
      Printing.layoutPdf(name: nombreArchivo, onLayout: (_) async => bytes);

  /// Comparte o guarda el PDF como archivo.
  Future<void> compartir(Uint8List bytes, String nombreArchivo) =>
      Printing.sharePdf(bytes: bytes, filename: '$nombreArchivo.pdf');
}
