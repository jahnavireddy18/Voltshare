import 'package:flutter_test/flutter_test.dart';
import 'package:vnest_app/main.dart';

void main() {
  testWidgets('VNest app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const VNestApp());
    expect(find.text('Get Started'), findsNothing);
  });
}
