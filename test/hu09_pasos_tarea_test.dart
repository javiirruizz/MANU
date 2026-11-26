import 'package:flutter_test/flutter_test.dart';
import 'package:manu/models/paso.dart';
import 'package:manu/models/tarea.dart';
import 'package:manu/models/usuario.dart';
import 'package:manu/views/profesor/gestor_tareas_page.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Tarea crearTareaBase({List<Paso> pasos = const []}) {
    return Tarea(
      id: 'tarea_1',
      nombre: 'Taller de lectura',
      descripcion: 'Actividad guiada',
      fecha: DateTime(2026, 11, 25),
      horario: 'mañana',
      horaInicio: DateTime(2026, 11, 25, 9, 0),
      horaFinal: DateTime(2026, 11, 25, 10, 0),
      aulaId: 'Aula 1',
      creadaPor: 'profe_1',
      pasos: pasos,
    );
  }

  group('HU 09 - Listas de verificación paso a paso', () {
    test('se pueden añadir pasos secuenciales a una tarea', () {
      var tarea = crearTareaBase();
      tarea = tarea.agregarPaso('Sacar el libro');
      tarea = tarea.agregarPaso('Leer la primera página');
      tarea = tarea.agregarPaso('Responder preguntas');

      expect(tarea.pasos.length, 3);
      expect(tarea.pasos.map((p) => p.orden).toList(), [1, 2, 3]);
      expect(tarea.pasos.every((p) => p.estado == 'pendiente'), isTrue);

      expect(
        () => tarea.agregarPaso('   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('se puede reordenar la lista de pasos manteniendo el orden correlativo', () {
      var tarea = crearTareaBase()
          .agregarPaso('Paso A')
          .agregarPaso('Paso B')
          .agregarPaso('Paso C');

      tarea = tarea.reordenarPasos(0, 2);
      expect(tarea.pasos.map((p) => p.descripcion).toList(), [
        'Paso B',
        'Paso C',
        'Paso A',
      ]);
      expect(tarea.pasos.map((p) => p.orden).toList(), [1, 2, 3]);

      tarea = tarea.reordenarPasos(2, 0);
      expect(tarea.pasos.map((p) => p.descripcion).toList(), [
        'Paso A',
        'Paso B',
        'Paso C',
      ]);
      expect(tarea.pasos.map((p) => p.orden).toList(), [1, 2, 3]);

      expect(
        () => tarea.reordenarPasos(-1, 1),
        throwsA(isA<RangeError>()),
      );
      expect(
        () => tarea.reordenarPasos(0, 5),
        throwsA(isA<RangeError>()),
      );
    });

    test('al eliminar un paso se renumeran los restantes', () {
      var tarea = crearTareaBase()
          .agregarPaso('Primero')
          .agregarPaso('Segundo')
          .agregarPaso('Tercero');

      final idAEliminar = tarea.pasos[1].id;
      tarea = tarea.eliminarPaso(idAEliminar);

      expect(tarea.pasos.length, 2);
      expect(tarea.pasos.map((p) => p.descripcion).toList(), [
        'Primero',
        'Tercero',
      ]);
      expect(tarea.pasos.map((p) => p.orden).toList(), [1, 2]);
    });

    test(
      'se puede editar la descripcion de un paso sin perder su orden ni pictograma',
      () {
        final tareaInicial = crearTareaBase(
          pasos: const [
            Paso(
              id: 'p1',
              descripcion: 'Texto original',
              orden: 1,
              pictogramaId: '2262',
            ),
          ],
        );

        final editada = tareaInicial.editarPaso('p1', 'Texto corregido');
        expect(editada.pasos.first.descripcion, 'Texto corregido');
        expect(editada.pasos.first.orden, 1);
        expect(editada.pasos.first.pictogramaId, '2262');

        expect(
          () => editada.editarPaso('p1', '  '),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('serializacion y deserializacion de pasos conserva el orden', () {
      final tarea = crearTareaBase(
        pasos: const [
          Paso(id: 'p1', descripcion: 'Uno', orden: 1),
          Paso(id: 'p2', descripcion: 'Dos', orden: 2),
        ],
      );

      final mapa = tarea.toMap();
      expect((mapa['pasos'] as List).length, 2);

      // Si llegan desordenados desde Firestore, fromMap los ordena por orden
      final mapaDesordenado = {
        ...mapa,
        'pasos': [
          {'id': 'p2', 'descripcion': 'Dos', 'orden': 2, 'estado': 'pendiente'},
          {'id': 'p1', 'descripcion': 'Uno', 'orden': 1, 'estado': 'pendiente'},
        ],
      };

      final restaurada = Tarea.fromMap('tarea_1', mapaDesordenado);
      expect(restaurada.pasos.map((p) => p.descripcion).toList(), [
        'Uno',
        'Dos',
      ]);
      expect(restaurada.pasos.map((p) => p.orden).toList(), [1, 2]);
    });

    testWidgets(
      'el tutor puede crear y reordenar pasos desde GestorTareasPage',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1800, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        const alumno = Usuario(
          id: 'alum_1',
          nombreUsuario: 'alumno1',
          nombre: 'Usuario Alumno 1',
          rol: RolUsuario.alumno,
        );

        Tarea? tareaGuardada;

        await tester.pumpWidget(
          MaterialApp(
            home: GestorTareasPage(
              alumnos: const [alumno],
              fechaSeleccionada: DateTime(2026, 11, 25),
              onGuardarTarea: (nuevaTarea, _, _) async {
                tareaGuardada = nuevaTarea;
              },
            ),
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nombre de la tarea *'),
          'Lectura guiada',
        );

        await tester.tap(find.text('Selecciona al Alumno *'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Usuario Alumno 1').last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.widgetWithText(TextField, 'Añadir paso...'),
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Añadir paso...'),
          'Abrir el libro',
        );
        await tester.tap(find.text('Añadir'));
        await tester.pump();

        await tester.enterText(
          find.widgetWithText(TextField, 'Añadir paso...'),
          'Leer la página 5',
        );
        await tester.tap(find.text('Añadir'));
        await tester.pump();

        expect(find.text('Abrir el libro'), findsOneWidget);
        expect(find.text('Leer la página 5'), findsOneWidget);

        // Bajamos el primer paso para invertir el orden
        await tester.ensureVisible(find.byTooltip('Bajar paso').first);
        await tester.tap(find.byTooltip('Bajar paso').first);
        await tester.pump();

        await tester.ensureVisible(find.text('Asignar Tarea'));
        await tester.tap(find.text('Asignar Tarea'));
        await tester.pumpAndSettle();

        expect(tareaGuardada, isNotNull);
        expect(
          tareaGuardada!.pasos.map((p) => p.descripcion).toList(),
          ['Leer la página 5', 'Abrir el libro'],
        );
        expect(tareaGuardada!.pasos.map((p) => p.orden).toList(), [1, 2]);
      },
    );
  });
}
