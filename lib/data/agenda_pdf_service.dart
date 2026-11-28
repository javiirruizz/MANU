import 'dart:math';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';

class TareaPdf {
  const TareaPdf({
    required this.inicio,
    required this.fin,
    required this.nombre,
    this.pictogramaUrl,
  });
  final DateTime inicio;
  final DateTime fin;
  final String nombre;
  final String? pictogramaUrl;
}

class PlatoPdf {
  const PlatoPdf({
    required this.etiqueta, // "1º plato", "2º plato", "Postre"
    required this.nombre,
    this.pictogramaUrl,
  });
  final String etiqueta;
  final String nombre;
  final String? pictogramaUrl;
}

class DiaPdf {
  const DiaPdf({
    required this.fecha,
    this.tareas = const [],
    this.menu = const [],
  });
  final DateTime fecha;
  final List<TareaPdf> tareas;
  final List<PlatoPdf> menu;
}

class AgendaPdfService {
  static const _filasPorPagina = 4;
  static const _alturaFila = 92.0;
  static const _alturaPlato = 62.0;
  static const _alturaCabecera = 36.0;
  static const _tamPicto = 64.0;

  static final _verde = PdfColor.fromHex('#80C8C8');
  static const _texto = PdfColors.grey900;

  static const _dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  static const _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  static const _estados = [
    'Contento',
    'Tranquilo',
    'Preocupado',
    'Enfadado',
    'Cansado',
  ];

  Future<Uint8List> generar({
    required String titulo,
    required List<DiaPdf> dias,
    bool rellenarFecha = true,
    bool relojConHora = true,
    List<String> pictosCabecera = const [], // URLs opcionales (hasta 5)
  }) async {
    // Descarga cada pictograma una sola vez
    final urls = <String>{
      ...pictosCabecera,
      for (final d in dias) ...[
        for (final t in d.tareas)
          if (t.pictogramaUrl != null && t.pictogramaUrl!.isNotEmpty)
            t.pictogramaUrl!,
        for (final p in d.menu)
          if (p.pictogramaUrl != null && p.pictogramaUrl!.isNotEmpty)
            p.pictogramaUrl!,
      ],
    };
    final imagenes = <String, pw.ImageProvider>{};
    await Future.wait(
      urls.map((url) async {
        try {
          imagenes[url] = await networkImage(url);
        } catch (e) {
          debugPrint('Pictograma no cargado: $url -> $e');
        }
      }),
    );

    final doc = pw.Document(title: titulo);

    for (final d in dias) {
      final paginas = max(1, (d.tareas.length / _filasPorPagina).ceil());

      for (var p = 0; p < paginas; p++) {
        final filas = d.tareas
            .skip(p * _filasPorPagina)
            .take(_filasPorPagina)
            .toList();
        final esUltima = p == paginas - 1;

        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(28),
            build: (_) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  titulo,
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 6),
                if (pictosCabecera.isNotEmpty) ...[
                  _cabeceraPictos(pictosCabecera, imagenes),
                  pw.SizedBox(height: 10),
                ],
                _lineaFecha(d.fecha, rellenarFecha),
                pw.SizedBox(height: 14),
                _bloqueActividades(filas, imagenes, p > 0, relojConHora),
                pw.Spacer(),
                if (esUltima)
                  pw.SizedBox(
                    height: _alturaCabecera + 3 * _alturaPlato + 4,
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Expanded(child: _bloqueMenu(d.menu, imagenes)),
                        pw.SizedBox(width: 14),
                        pw.Expanded(child: _bloqueAnimo()),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    }

    return doc.save();
  }

  // ---------------------------------------------------------------- cabecera

  pw.Widget _cabeceraPictos(
    List<String> urls,
    Map<String, pw.ImageProvider> imagenes,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        for (final u in urls.take(5))
          pw.Container(
            width: 56,
            height: 56,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
            child: imagenes[u] == null
                ? pw.SizedBox()
                : pw.Image(imagenes[u]!, fit: pw.BoxFit.contain),
          ),
      ],
    );
  }

  pw.Widget _lineaFecha(DateTime f, bool rellenar) {
    pw.Widget campo(String valor, double ancho) => pw.Container(
      width: ancho,
      height: 24,
      alignment: pw.Alignment.bottomCenter,
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 1, color: PdfColors.grey700),
        ),
      ),
      child: pw.Text(
        rellenar ? valor : '',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );

    pw.Widget palabra(String t) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6),
      child: pw.Text(t, style: pw.TextStyle(fontSize: 18, color: _texto)),
    );

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          'Hoy es',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 6),
        campo(_dias[f.weekday - 1], 110),
        palabra(','),
        campo('${f.day}', 40),
        palabra('de'),
        campo(_meses[f.month - 1], 100),
        palabra('del'),
        campo('${f.year}', 60),
      ],
    );
  }

  pw.Widget _titulo(String texto) => pw.Container(
    height: _alturaCabecera,
    color: _verde,
    alignment: pw.Alignment.center,
    child: pw.Text(
      texto,
      style: pw.TextStyle(
        fontSize: 15,
        fontWeight: pw.FontWeight.bold,
        color: _texto,
      ),
    ),
  );

  // -------------------------------------------------------------- actividades

  pw.Widget _bloqueActividades(
    List<TareaPdf> filas,
    Map<String, pw.ImageProvider> imagenes,
    bool continuacion,
    bool relojConHora,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.2)),
      child: pw.Column(
        children: [
          _titulo(continuacion ? 'ACTIVIDADES (continuación)' : 'ACTIVIDADES'),
          for (var i = 0; i < _filasPorPagina; i++)
            _filaActividad(
              i < filas.length ? filas[i] : null,
              imagenes,
              relojConHora,
            ),
        ],
      ),
    );
  }

  pw.Widget _filaActividad(
    TareaPdf? t,
    Map<String, pw.ImageProvider> imagenes,
    bool relojConHora,
  ) {
    final img = t?.pictogramaUrl == null ? null : imagenes[t!.pictogramaUrl];

    return pw.Container(
      height: _alturaFila,
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(width: 1)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          _reloj(relojConHora ? t?.inicio : null),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: t == null
                ? pw.SizedBox()
                : pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${_hhmm(t.inicio)} - ${_hhmm(t.fin)}',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        t.nombre,
                        maxLines: 2,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: _texto,
                        ),
                      ),
                    ],
                  ),
          ),
          if (img != null)
            pw.Image(
              img,
              width: _tamPicto,
              height: _tamPicto,
              fit: pw.BoxFit.contain,
            ),
        ],
      ),
    );
  }

  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// Reloj analógico. Con [hora] dibuja las manecillas; sin ella queda en
  /// blanco para que el alumno dibuje la hora.
  pw.Widget _reloj(DateTime? hora, {double s = 72}) {
    final c = s / 2;
    const r = 0.0; // sin uso, mantiene legible el cálculo de abajo
    final radioNumeros = c - 11;

    return pw.SizedBox(
      width: s,
      height: s,
      child: pw.Stack(
        children: [
          pw.CustomPaint(
            size: PdfPoint(s, s),
            painter: (canvas, size) {
              canvas
                ..setStrokeColor(PdfColors.grey800)
                ..setLineWidth(2.5)
                ..drawEllipse(c, c, c - 2, c - 2)
                ..strokePath();

              if (hora == null) return;

              void mano(double angulo, double largo, double grosor) {
                canvas
                  ..setLineCap(PdfLineCap.round)
                  ..setLineWidth(grosor)
                  ..moveTo(c, c)
                  ..lineTo(c + largo * sin(angulo), c + largo * cos(angulo))
                  ..strokePath();
              }

              final h = (hora.hour % 12) + hora.minute / 60;
              mano(h * pi / 6, c * 0.5, 3.2);
              mano(hora.minute * pi / 30, c * 0.72, 2);
            },
          ),
          for (var n = 1; n <= 12; n++)
            pw.Positioned(
              left: c + radioNumeros * sin(n * pi / 6) - 6 + r,
              top: c - radioNumeros * cos(n * pi / 6) - 5,
              child: pw.SizedBox(
                width: 12,
                height: 10,
                child: pw.Center(
                  child: pw.Text(
                    '$n',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------- menú y emociones

  pw.Widget _bloqueMenu(
    List<PlatoPdf> menu,
    Map<String, pw.ImageProvider> imagenes,
  ) {
    final platos = List<PlatoPdf?>.generate(
      3,
      (i) => i < menu.length ? menu[i] : null,
    );

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.2)),
      child: pw.Column(
        children: [
          _titulo('Menú del día'),
          for (final p in platos)
            pw.Container(
              height: _alturaPlato,
              padding: const pw.EdgeInsets.all(5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(width: 1)),
              ),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 50,
                    height: 50,
                    child:
                        (p?.pictogramaUrl != null &&
                            imagenes[p!.pictogramaUrl] != null)
                        ? pw.Image(
                            imagenes[p.pictogramaUrl]!,
                            fit: pw.BoxFit.contain,
                          )
                        : pw.SizedBox(),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: p == null
                        ? pw.SizedBox()
                        : pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                p.etiqueta,
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.grey700,
                                ),
                              ),
                              pw.Text(
                                p.nombre,
                                maxLines: 2,
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _casilla() => pw.Container(
    width: 14,
    height: 14,
    decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.2)),
  );

  pw.Widget _bloqueAnimo() {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.2)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _titulo('¿Cómo me siento hoy?'),
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final e in _estados)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 9),
                    child: pw.Row(
                      children: [
                        _casilla(),
                        pw.SizedBox(width: 8),
                        pw.Text(e, style: const pw.TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                pw.Row(
                  children: [
                    _casilla(),
                    pw.SizedBox(width: 8),
                    pw.Text('Otro: ', style: const pw.TextStyle(fontSize: 13)),
                    pw.Expanded(
                      child: pw.Container(
                        height: 14,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: 1)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ salida

  Future<void> imprimir(Uint8List bytes, String nombreArchivo) =>
      Printing.layoutPdf(name: nombreArchivo, onLayout: (_) async => bytes);

  Future<void> compartir(Uint8List bytes, String nombreArchivo) =>
      Printing.sharePdf(bytes: bytes, filename: '$nombreArchivo.pdf');
}
