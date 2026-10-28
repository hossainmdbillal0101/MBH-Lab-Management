import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_management/src/app.dart';
import 'package:lab_management/src/store.dart';

// Optional artifact generation, not a replacement for browser/device testing.
void main() {
  testWidgets('capture portfolio previews', (tester) async {
    final fontPath = Platform.environment['SCREENSHOT_FONT'];
    if (fontPath != null) {
      await tester.runAsync(() async {
        final loader = FontLoader('Roboto')
          ..addFont(Future.value(
              ByteData.sublistView(await File(fontPath).readAsBytes())));
        await loader.load();
      });
    }
    final iconPath = Platform.environment['SCREENSHOT_ICON_FONT'];
    if (iconPath != null) {
      await tester.runAsync(() async {
        final loader = FontLoader('MaterialIcons')
          ..addFont(Future.value(
              ByteData.sublistView(await File(iconPath).readAsBytes())));
        await loader.load();
      });
    }
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = LabStore();
    final key = GlobalKey();
    await tester
        .pumpWidget(RepaintBoundary(key: key, child: LabApp(store: store)));
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = (await tester.runAsync(() => boundary.toImage()))!;
      final bytes = await tester
          .runAsync(() => image.toByteData(format: ui.ImageByteFormat.png));
      await tester.runAsync(() async {
        final path = File('docs/previews/$name.png');
        await path.parent.create(recursive: true);
        await path.writeAsBytes(bytes!.buffer.asUint8List());
      });
      image.dispose();
    }

    await capture('dashboard-desktop');
    await tester.tap(find.text('Assets'));
    await tester.pumpAndSettle();
    await capture('assets-desktop');
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    await tester.drag(
        find.byType(SingleChildScrollView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await capture('assets-mobile');
    expect(tester.takeException(), isNull);
  }, skip: !const bool.fromEnvironment('CAPTURE_PREVIEWS'));
}
