import 'package:flutter_test/flutter_test.dart';

import 'package:app_evidencias/main.dart';

void main() {
  testWidgets('La aplicación muestra la pantalla principal',
      (WidgetTester tester) async {
    await tester.pumpWidget(const EvidenciasApp());

    expect(find.text('Evidencias'), findsOneWidget);
    expect(find.text('Captura de evidencias'), findsOneWidget);
    expect(
      find.textContaining('Registra fotografías'),
      findsOneWidget,
    );
  });
}