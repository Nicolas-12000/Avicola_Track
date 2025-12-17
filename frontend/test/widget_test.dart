import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avicola_track_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: AvicolaTrackApp()));

    // Verify that the login screen is shown
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
