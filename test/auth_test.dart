import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lab_management/src/app.dart';
import 'package:lab_management/src/firebase_api.dart';
import 'package:lab_management/src/store.dart';

class ConfiguredApi extends FirebaseApi {
  ConfiguredApi({http.Client? client}) : super(client: client);
  @override
  bool get configured => true;
}

void main() {
  test('public preview cannot issue password setup requests', () async {
    await expectLater(
        FirebaseApi().requestPasswordReset('staff@example.invalid'),
        throwsStateError);
  });
  test(
      'password setup uses the Firebase email endpoint without sending a password',
      () async {
    var calls = 0;
    final api = ConfiguredApi(client: MockClient((request) async {
      calls++;
      expect(request.url.host, 'identitytoolkit.googleapis.com');
      expect(request.url.path, '/v1/accounts:sendOobCode');
      expect(jsonDecode(request.body),
          {'requestType': 'PASSWORD_RESET', 'email': 'staff@example.invalid'});
      expect(request.headers.containsKey('Authorization'), false);
      return http.Response('{}', 200);
    }));
    await api.requestPasswordReset(' staff@example.invalid ');
    expect(calls, 1);
    expect(api.uid, isNull);
    expect(api.admin, false);
    await expectLater(
        api.requestPasswordReset('not-an-email'), throwsArgumentError);
    expect(calls, 1);
  });
  testWidgets(
      'private mobile login and password setup fit above keyboard without exposing records',
      (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetViewInsets);
    final api = ConfiguredApi(
        client: MockClient((_) async => http.Response('{}', 200)));
    await t.pumpWidget(LabApp(store: LabStore(api: api)));
    await t.pumpAndSettle();
    expect(find.text('Workstation 01'), findsNothing);
    await t.tap(find.text('Staff sign in'));
    await t.pumpAndSettle();
    t.view.viewInsets = const FakeViewPadding(bottom: 300);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await t.ensureVisible(find.text('Set or reset your app password'));
    await t.tap(find.text('Set or reset your app password'));
    await t.pumpAndSettle();
    expect(find.text('Set or reset app password'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'staff@example.invalid');
    await t.tap(find.text('Request setup email'));
    await t.pumpAndSettle();
    expect(
        find.textContaining('If this email belongs to a provisioned account'),
        findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
