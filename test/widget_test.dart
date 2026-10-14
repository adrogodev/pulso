import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/app/app.dart';

void main() {
  testWidgets('PulsoApp inicializa y muestra el título', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PulsoApp()));

    expect(find.text('Pulso'), findsOneWidget);
  });
}
