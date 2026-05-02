import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskease_clean/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskEaseApp());
    expect(find.byType(TaskEaseApp), findsOneWidget);
  });
}