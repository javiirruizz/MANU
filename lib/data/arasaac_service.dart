import 'dart:convert';

import 'package:http/http.dart' as http;

/// Busca pictogramas en ARASAAC por palabra ("comer", "lentejas", "contento"...)
/// y construye la URL de la imagen. Guarda los resultados en memoria para no
/// repetir peticiones.
class ArasaacService {
  ArasaacService._();
  static final ArasaacService instance = ArasaacService._();

  static const _api = 'https://api.arasaac.org/v1';

  /// Si una palabra devuelve un pictograma que no os gusta, fijad aquí el id
  /// que prefiráis. Ejemplo: {'asamblea': 1234}
  static const Map<String, int> _fijos = {};

  final Map<String, Future<int?>> _cache = {};

  static const _vacias = {
    'el',
    'la',
    'los',
    'las',
    'un',
    'una',
    'de',
    'del',
    'y',
    'con',
    'en',
    'a',
    'al',
    'mi',
    'mis',
    'tu',
    'para',
    'por',
    'se',
  };

  /// Devuelve el id del mejor pictograma para [texto], o null si no hay.
  /// Si la frase completa no da resultado ("Lavarse los dientes"), prueba con
  /// sus palabras importantes de la última a la primera ("dientes", "lavarse").
  Future<int?> buscarId(String texto) async {
    final completo = texto.trim().toLowerCase();
    if (completo.isEmpty) return null;

    final id = await _buscarConCache(completo);
    if (id != null) return id;

    final palabras = completo
        .split(RegExp(r'[\s,.;:]+'))
        .where((w) => w.length > 2 && !_vacias.contains(w) && w != completo)
        .toList()
        .reversed;
    for (final palabra in palabras) {
      final porPalabra = await _buscarConCache(palabra);
      if (porPalabra != null) return porPalabra;
    }
    return null;
  }

  Future<int?> _buscarConCache(String clave) {
    final fijo = _fijos[clave];
    if (fijo != null) return Future.value(fijo);

    return _cache.putIfAbsent(clave, () async {
      final id = await _buscar(clave);
      if (id == null) _cache.remove(clave); // permite reintentar más tarde
      return id;
    });
  }

  Future<int?> _buscar(String texto) async {
    try {
      final url = Uri.parse(
        '$_api/pictograms/es/bestsearch/${Uri.encodeComponent(texto)}',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final datos = jsonDecode(res.body);
      if (datos is List && datos.isNotEmpty) {
        final id = datos.first['_id'];
        if (id is int) return id;
      }
    } catch (_) {
      // Sin conexión o error de la API: se mostrará el icono de reserva.
    }
    return null;
  }

  static String urlImagen(int id, {int tamano = 500}) =>
      'https://static.arasaac.org/pictograms/$id/${id}_$tamano.png';
}
