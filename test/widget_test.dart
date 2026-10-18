import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:realtime_object_detection/main.dart';

void main() {
  testWidgets('app boots to a MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const LiveDetectApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
