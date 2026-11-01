import 'package:duet/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shell exposes labeled navigation destinations', (tester) async {
    final state = AppState();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appProvider.overrideWith((ref) => state)],
        child: const MaterialApp(home: AppShell()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp('Home')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Progress')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Buddy')), findsNWidgets(2));
    await tester.tap(find.text('Progress').last);
    await tester.pumpAndSettle();
    expect(find.text('Progress'), findsWidgets);
  });

  testWidgets('dark mode switch is reachable from settings', (tester) async {
    final state = AppState();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appProvider.overrideWith((ref) => state)],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Dark mode'), 500, scrollable: find.byType(Scrollable).last);
    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNWidgets(6));
    expect(find.bySemanticsLabel(RegExp('Dark mode')), findsOneWidget);
  });
}
