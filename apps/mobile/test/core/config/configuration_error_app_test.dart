import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/configuration_error_app.dart';

void main() {
  testWidgets(
    'shows every violation so the Founder knows exactly what to fix',
    (tester) async {
      await tester.pumpWidget(
        const ConfigurationErrorApp(
          violations: ['API_BASE_URL is not set.', 'Something else is wrong.'],
        ),
      );

      expect(find.text('Configuration error'), findsOneWidget);
      expect(find.textContaining('API_BASE_URL is not set.'), findsOneWidget);
      expect(find.textContaining('Something else is wrong.'), findsOneWidget);
    },
  );
}
