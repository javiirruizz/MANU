import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manu/main.dart';

void main() {
  testWidgets('Carga inicial de la aplicación MiAgendaApp', (
    WidgetTester tester,
  ) async {
    // Configurar tamaño de pantalla horizontal (tablet/desktop)
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Renderizar la aplicación
    await tester.pumpWidget(const MiAgendaApp());
    await tester.pumpAndSettle();

    // Comprobar que se muestra el título de la agenda
    expect(find.text('Mi Agenda'), findsOneWidget);
  });
}
