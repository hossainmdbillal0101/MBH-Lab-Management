import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_management/src/app.dart';
import 'package:lab_management/src/store.dart';

void main() {
  testWidgets(
      'public mobile layout supports navigation and asset search without admin controls',
      (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(LabApp(store: LabStore()));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.textContaining('Read only'), findsOneWidget);
    expect(find.text('Staff sign in'), findsNothing);
    expect(find.text('Add asset'), findsNothing);
    await t.tap(find.text('Assets'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, 'DEMO-PC-003');
    await t.pumpAndSettle();
    expect(find.text('Workstation 03'), findsOneWidget);
    expect(find.text('Workstation 01'), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets('desktop labs and maintenance history render without overflow',
      (t) async {
    t.view.physicalSize = const Size(1440, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(LabApp(store: LabStore()));
    await t.pumpAndSettle();
    await t.tap(find.text('Labs'));
    await t.pumpAndSettle();
    expect(find.text('Innovation lab'), findsOneWidget);
    await t.tap(find.text('Explore assets').first);
    await t.pumpAndSettle();
    expect(find.text('4 assets'), findsOneWidget);
    await t.tap(find.text('Maintenance'));
    await t.pumpAndSettle();
    expect(find.text('Inspection history'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
