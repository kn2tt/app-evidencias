import 'package:flutter_test/flutter_test.dart';
import 'package:app_evidencias/main.dart';

void main() {
  testWidgets('La aplicación inicia correctamente',
      (WidgetTester tester) async {
    await tester.pumpWidget(const EvidenciasApp());

    expect(find.byType(EvidenciasApp), findsOneWidget);
  });
}