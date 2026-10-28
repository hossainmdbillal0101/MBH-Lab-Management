import 'package:flutter/foundation.dart';
import 'firebase_api.dart';

const inspectionChecks = [
  'Operating system and boot',
  'Updates and endpoint protection',
  'Mouse and pointing devices',
  'Keyboard and input',
  'Monitor and display',
  'Storage health',
  'Network connectivity',
  'Physical cleanliness',
  'Power and cable connections',
];

class LabStore extends ChangeNotifier {
  final FirebaseApi api;
  LabStore({FirebaseApi? api}) : api = api ?? FirebaseApi() {
    resetDemo();
  }
  List<Map<String, dynamic>> labs = [], assets = [], inspections = [];
  bool signedIn = false, busy = false;
  String? error;
  bool get live => api.configured;
  bool get canEdit => live && signedIn && api.admin;
  DateTime get today => DateTime.now();
  String labName(String id) =>
      labs
          .where((x) => x['id'] == id)
          .map((x) => x['name'] as String)
          .firstOrNull ??
      'Unassigned';
  bool overdue(Map<String, dynamic> asset) =>
      DateTime.parse(asset['due'] as String)
          .isBefore(DateTime(today.year, today.month, today.day));
  List<Map<String, dynamic>> history(String id) =>
      inspections.where((x) => x['assetId'] == id).toList()
        ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
  void resetDemo() {
    if (live && signedIn) return;
    labs = [
      {
        'id': 'lab-1',
        'name': 'Innovation lab',
        'location': 'Demo campus / Level 1'
      },
      {
        'id': 'lab-2',
        'name': 'Computing studio',
        'location': 'Demo campus / Level 2'
      },
      {
        'id': 'lab-3',
        'name': 'Research workspace',
        'location': 'Demo campus / Level 3'
      },
    ];
    assets = List.generate(
        12,
        (i) => {
              'id': 'asset-${i + 1}',
              'tag': 'DEMO-PC-${(i + 1).toString().padLeft(3, '0')}',
              'name': 'Workstation ${(i + 1).toString().padLeft(2, '0')}',
              'labId': 'lab-${i ~/ 4 + 1}',
              'model': i.isEven
                  ? 'OptiPlex demo desktop'
                  : 'ThinkCentre demo desktop',
              'os': i % 3 == 0 ? 'Linux' : 'Windows 11',
              'status': i == 2 || i == 7
                  ? 'Attention'
                  : i == 9
                      ? 'In service'
                      : 'Ready',
              'due': today
                  .add(Duration(days: i % 4 == 0 ? -8 : i * 3 + 3))
                  .toIso8601String()
                  .substring(0, 10),
              'monitorTag': 'DEMO-MON-${(i + 1).toString().padLeft(3, '0')}',
            });
    inspections = List.generate(
        6,
        (i) => {
              'id': 'inspection-$i',
              'assetId': 'asset-${i + 1}',
              'date': today
                  .subtract(Duration(days: 2 + i * 4))
                  .toIso8601String()
                  .substring(0, 10),
              'phase': 'Routine',
              'results':
                  List.generate(9, (n) => i == 2 && n == 6 ? 'Issue' : 'Pass'),
              'notes': i == 2
                  ? 'Intermittent network connection. Follow-up required.'
                  : 'Routine preventive maintenance completed.',
              'technician': 'Demo technician',
              'outcome': i == 2 ? 'Attention' : 'Ready',
              'nextDue': today
                  .add(const Duration(days: 30))
                  .toIso8601String()
                  .substring(0, 10),
            });
    notifyListeners();
  }

  Future<void> authenticate(String email, String password) async {
    if (!live) throw StateError('Live backend is not configured.');
    busy = true;
    error = null;
    notifyListeners();
    try {
      await api.authenticate(email.trim(), password, register: false);
      signedIn = true;
      await refresh();
    } catch (_) {
      api.signOut();
      signedIn = false;
      error = 'Sign-in failed or this account cannot access the workspace.';
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (!live || !signedIn) return;
    final data = await Future.wait(
        [api.list('labs'), api.list('assets'), api.list('inspections')]);
    labs = data[0];
    assets = data[1];
    inspections = data[2];
    notifyListeners();
  }

  void signOut() {
    api.signOut();
    signedIn = false;
    error = null;
    resetDemo();
  }

  void _requireEditor() {
    if (!canEdit) {
      throw StateError('An authenticated workspace administrator is required.');
    }
  }

  Future<void> addLab(String name, String location) async {
    _requireEditor();
    if (name.trim().isEmpty ||
        location.trim().isEmpty ||
        name.length > 100 ||
        location.length > 200) {
      throw ArgumentError('Enter a valid lab name and location.');
    }
    await api.save('labs', 'lab-${DateTime.now().microsecondsSinceEpoch}',
        {'name': name.trim(), 'location': location.trim()});
    await refresh();
  }

  Future<void> addAsset(Map<String, dynamic> data) async {
    _requireEditor();
    for (final key in ['tag', 'name', 'model', 'os', 'monitorTag']) {
      if ((data[key] as String? ?? '').trim().isEmpty ||
          (data[key] as String).length > 150) {
        throw ArgumentError('Complete all asset fields.');
      }
    }
    if (!labs.any((l) => l['id'] == data['labId'])) {
      throw ArgumentError('Select an existing lab.');
    }
    if (assets.any((a) =>
        (a['tag'] as String).toLowerCase() ==
        (data['tag'] as String).toLowerCase())) {
      throw ArgumentError('Asset tag already exists.');
    }
    DateTime.parse(data['due'] as String);
    final tag = (data['tag'] as String).trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9_-]{3,80}$').hasMatch(tag)) {
      throw ArgumentError(
          'Use 3-80 letters, numbers, underscores or hyphens for the tag.');
    }
    await api.create('assets', tag, {...data, 'tag': tag, 'status': 'Ready'});
    await refresh();
  }

  Future<void> recordInspection(Map<String, dynamic> asset,
      List<String> results, String notes, String phase, String nextDue) async {
    _requireEditor();
    if (results.length != inspectionChecks.length ||
        results.any((x) => !['Pass', 'Issue', 'Not applicable'].contains(x))) {
      throw ArgumentError('Complete all nine checks.');
    }
    if (notes.length > 2000 || phase.isEmpty) {
      throw ArgumentError('Use notes of at most 2000 characters.');
    }
    final next = DateTime.parse(nextDue);
    if (next.isBefore(DateTime(today.year, today.month, today.day))) {
      throw ArgumentError('Next service date cannot be in the past.');
    }
    final outcome = results.contains('Issue') ? 'Attention' : 'Ready';
    final id = 'inspection-${DateTime.now().microsecondsSinceEpoch}';
    final updatedAsset = Map<String, dynamic>.from(asset)..remove('id');
    await api.saveBatch({
      'inspections/$id': {
        'assetId': asset['id'],
        'date': today.toIso8601String().substring(0, 10),
        'phase': phase,
        'results': results,
        'notes': notes.trim(),
        'technician': api.uid!,
        'outcome': outcome,
        'nextDue': nextDue
      },
      'assets/${asset['id']}': {
        ...updatedAsset,
        'status': outcome,
        'due': nextDue
      },
    });
    await refresh();
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
