import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('基础组件可正常渲染', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Moodiary Test'))),
      ),
    );

    expect(find.text('Moodiary Test'), findsOneWidget);
  });
}
