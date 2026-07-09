import 'package:flutter_test/flutter_test.dart';

import 'package:ink_ai/main.dart';

void main() {
  testWidgets('TattooStudioScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const InkAI());

    expect(find.text('Design Your Ink'), findsOneWidget);
    expect(find.text('Upload Body Part'), findsOneWidget);
    expect(find.text('Upload Tattoo Idea'), findsOneWidget);
    expect(find.text('Generate Tattoo'), findsOneWidget);
  });
}