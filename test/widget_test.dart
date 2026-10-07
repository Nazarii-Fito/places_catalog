import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/app/app.dart';

void main() {
  testWidgets('App starts on the login route', (tester) async {
    await tester.pumpWidget(const PlacesCatalogApp());
    await tester.pumpAndSettle();
    expect(find.text('Log In'), findsOneWidget);
  });
}
