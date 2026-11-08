import 'package:flutter_test/flutter_test.dart';
import 'package:manu/data/pictograma_repository.dart';
import 'package:manu/models/tarea.dart';

void main() {
  group('HU 05 - Asignación de pictogramas', () {
    late PictogramaRepository repository;

    setUp(() {
      repository = PictogramaRepository();
    });

    test(
      'Prueba de aceptación 1: Subir una imagen en formato PNG, asociarle una etiqueta textual y verificar que queda guardada',
      () async {
        final guardado = await repository.subirPictograma(
          nombreArchivo: 'lavar_dientes.png',
          etiquetaTextual: 'Cepillarse los dientes',
        );

        expect(guardado.nombre, 'Cepillarse los dientes');
        expect(guardado.esDeArasaac, isFalse);

        final todos = await repository.buscarPorEtiqueta('');
        expect(
          todos.any((p) => p.idPictograma == guardado.idPictograma),
          isTrue,
        );
      },
    );

    test(
      'Prueba de aceptación 2: Realizar una búsqueda en la biblioteca usando la etiqueta de texto y comprobar que la imagen aparece en los resultados',
      () async {
        await repository.subirPictograma(
          nombreArchivo: 'pintar_acuarela.png',
          etiquetaTextual: 'Pintar con acuarelas',
        );

        final resultados = await repository.buscarPorEtiqueta('acuarelas');

        expect(resultados, isNotEmpty);
        expect(resultados.first.nombre, 'Pintar con acuarelas');
      },
    );

    test(
      'Prueba de aceptación 3: Intentar subir un archivo no admitido (ej. PDF) y comprobar que el sistema bloquea la subida',
      () async {
        expect(
          () => repository.subirPictograma(
            nombreArchivo: 'documento.pdf',
            etiquetaTextual: 'Ficha de lectura',
          ),
          throwsA(isA<FormatoNoAdmitidoException>()),
        );
      },
    );

    test(
      'Asignar pictograma encontrado a una Tarea (relación muchos a muchos)',
      () async {
        final resultados = await repository.buscarPorEtiqueta('Asamblea');
        expect(resultados, isNotEmpty);

        final tareaInicial = Tarea(
          id: 'tarea_1',
          nombre: 'Asamblea matinal',
          descripcion: 'Saludos y calendario',
          fecha: DateTime(2026, 11, 8),
          horario: 'mañana',
          horaInicio: DateTime(2026, 11, 8, 9, 0),
          horaFinal: DateTime(2026, 11, 8, 9, 30),
          aulaId: 'aula_1',
          creadaPor: 'profesor_1',
        );

        final tareaActualizada = await repository.asignarPictogramaATarea(
          tarea: tareaInicial,
          pictograma: resultados.first,
        );

        expect(tareaActualizada.pictogramas.length, 1);
        expect(tareaActualizada.pictogramas.first.nombre, 'Asamblea matinal');
      },
    );
  });
}

