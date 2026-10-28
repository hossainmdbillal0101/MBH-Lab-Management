import 'package:flutter_test/flutter_test.dart';
import 'package:lab_management/src/store.dart';
import 'package:lab_management/src/firebase_api.dart';

class FakeApi extends FirebaseApi {
  @override
  bool get configured => true;
  final bool administrator;
  final Map<String, Map<String, Map<String, dynamic>>> data = {
    'labs': {
      'lab-1': {'name': 'Test lab', 'location': 'Test location'}
    },
    'assets': {},
    'inspections': {}
  };
  FakeApi({this.administrator = true});
  @override
  Future<void> authenticate(String email, String password,
      {bool register = false}) async {
    uid = 'test-user';
    admin = administrator;
  }

  @override
  Future<List<Map<String, dynamic>>> list(String collection) async =>
      data[collection]!.entries.map((e) => {'id': e.key, ...e.value}).toList();
  @override
  Future<void> save(
      String collection, String id, Map<String, dynamic> value) async {
    data[collection]![id] = value;
  }

  @override
  Future<void> create(
      String collection, String id, Map<String, dynamic> value) async {
    if (data[collection]!.containsKey(id)) throw StateError('Already exists');
    data[collection]![id] = value;
  }

  @override
  Future<void> saveBatch(Map<String, Map<String, dynamic>> docs) async {
    for (final e in docs.entries) {
      final p = e.key.split('/');
      data[p[0]]![p[1]] = e.value;
    }
  }
}

Map<String, dynamic> asset() => {
      'tag': 'TEST-PC-001',
      'name': 'Test workstation',
      'labId': 'lab-1',
      'model': 'Test model',
      'os': 'Linux',
      'monitorTag': 'TEST-MON-001',
      'due': DateTime.now()
          .add(const Duration(days: 30))
          .toIso8601String()
          .substring(0, 10)
    };
void main() {
  test('public preview has fictional data and no write access', () async {
    final s = LabStore();
    expect(s.assets.length, 12);
    expect(s.labs.length, 3);
    expect(s.canEdit, false);
    await expectLater(s.addLab('Any', 'Any'), throwsStateError);
    await expectLater(s.addAsset(asset()), throwsStateError);
    await expectLater(
        s.recordInspection(s.assets.first, List.filled(9, 'Pass'), '',
            'Routine', '2030-01-01'),
        throwsStateError);
  });
  test('admin access requires live configuration and successful sign in',
      () async {
    final api = FakeApi();
    final s = LabStore(api: api);
    api.admin = true;
    expect(s.canEdit, false);
    await s.authenticate('owner@example.invalid', 'fake-password');
    expect(s.canEdit, true);
    s.signOut();
    expect(s.canEdit, false);
    expect(api.uid, isNull);
  });
  test('ordinary authenticated reader cannot mutate records', () async {
    final s = LabStore(api: FakeApi(administrator: false));
    await s.authenticate('reader@example.invalid', 'fake-password');
    expect(s.canEdit, false);
    await expectLater(s.addAsset(asset()), throwsStateError);
  });
  test('asset tag prevents duplicates and rejects invalid IDs', () async {
    final s = LabStore(api: FakeApi());
    await s.authenticate('owner@example.invalid', 'fake-password');
    await s.addAsset(asset());
    await expectLater(s.addAsset(asset()), throwsArgumentError);
    await expectLater(
        s.addAsset({...asset(), 'tag': 'bad/path'}), throwsArgumentError);
    expect(s.assets.length, 1);
  });
  test('incomplete inspection cannot be recorded', () async {
    final s = LabStore(api: FakeApi());
    await s.authenticate('owner@example.invalid', 'fake-password');
    await s.addAsset(asset());
    await expectLater(
        s.recordInspection(
            s.assets.first, ['Pass'], '', 'Routine', '2030-01-01'),
        throwsArgumentError);
    await expectLater(
        s.recordInspection(s.assets.first, List.filled(9, 'Not checked'), '',
            'Routine', '2030-01-01'),
        throwsArgumentError);
    expect(s.inspections, isEmpty);
  });
  test(
      'inspection updates asset and immutable history in one batch without mutating the selected map',
      () async {
    final s = LabStore(api: FakeApi());
    await s.authenticate('owner@example.invalid', 'fake-password');
    await s.addAsset(asset());
    final selected = s.assets.first;
    final result = List.filled(9, 'Pass')..[6] = 'Issue';
    await s.recordInspection(selected, result, 'Cable replacement needed.',
        'Follow-up', '2030-01-01');
    expect(selected['id'], 'TEST-PC-001');
    expect(s.assets.first['status'], 'Attention');
    expect(s.assets.first['due'], '2030-01-01');
    expect(s.inspections.single['results'], result);
    expect(s.history('TEST-PC-001').length, 1);
  });
}
