import 'package:flutter_test/flutter_test.dart';
import 'package:metu_fit/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MetuFitApp());
  });
}
