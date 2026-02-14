import 'package:flutter_test/flutter_test.dart';
import 'package:theia/app.dart';

void main() {
  testWidgets('Theia app starts and shows main navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TheiaApp());
    expect(find.text('Theia'), findsOneWidget);
  });
}
