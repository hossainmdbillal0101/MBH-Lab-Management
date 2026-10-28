import 'dart:convert';
import 'package:http/http.dart' as http;

/// Firebase REST adapter shared by Android and web. Rules enforce authorization.
class FirebaseApi {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const enabled = apiKey != '' && projectId != '';
  bool get configured => enabled;

  String? _token, _refreshToken;
  DateTime _expires = DateTime(2000);
  String? uid;
  String? email;
  bool admin = false;
  final http.Client client;
  FirebaseApi({http.Client? client}) : client = client ?? http.Client();

  Future<Map<String, dynamic>> _send(String method, Uri uri,
      {Map<String, dynamic>? body, String? token}) async {
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token'
    };
    late http.Response response;
    final encoded = body == null ? null : jsonEncode(body);
    if (method == 'GET') {
      response = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));
    } else if (method == 'DELETE') {
      response = await client
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 20));
    } else if (method == 'PATCH') {
      response = await client
          .patch(uri, headers: headers, body: encoded)
          .timeout(const Duration(seconds: 20));
    } else {
      response = await client
          .post(uri, headers: headers, body: encoded)
          .timeout(const Duration(seconds: 20));
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      final error = data['error'];
      throw Exception(error is Map
          ? error['message']
          : 'Request failed (${response.statusCode})');
    }
    return data;
  }

  Future<void> authenticate(String email, String password,
      {bool register = false}) async {
    final action = register ? 'signUp' : 'signInWithPassword';
    final d = await _send(
        'POST',
        Uri.https('identitytoolkit.googleapis.com', '/v1/accounts:$action',
            {'key': apiKey}),
        body: {
          'email': email,
          'password': password,
          'returnSecureToken': true
        });
    uid = d['localId'] as String;
    this.email = d['email'] as String?;
    _setToken(d['idToken'] as String, d['refreshToken'] as String,
        int.parse(d['expiresIn'] as String));
  }

  Future<void> requestPasswordReset(String email) async {
    if (!configured) throw StateError('Staff backend is not configured.');
    final address = email.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(address)) {
      throw ArgumentError('Enter a valid email address.');
    }
    await _send(
        'POST',
        Uri.https('identitytoolkit.googleapis.com', '/v1/accounts:sendOobCode',
            {'key': apiKey}),
        body: {'requestType': 'PASSWORD_RESET', 'email': address});
  }

  void _setToken(String token, String refresh, int seconds) {
    _token = token;
    _refreshToken = refresh;
    _expires = DateTime.now().add(Duration(seconds: seconds - 60));
    final claims = jsonDecode(utf8.decode(
        base64Url.decode(base64Url.normalize(token.split('.')[1])))) as Map;
    admin = claims['admin'] == true;
  }

  Future<String> _accessToken() async {
    if (_token == null) throw Exception('Please sign in.');
    if (DateTime.now().isAfter(_expires)) {
      final response = await client.post(
          Uri.https('securetoken.googleapis.com', '/v1/token', {'key': apiKey}),
          body: {
            'grant_type': 'refresh_token',
            'refresh_token': _refreshToken!
          }).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception('Session expired. Please sign in again.');
      }
      final d = jsonDecode(response.body) as Map<String, dynamic>;
      _setToken(d['id_token'] as String, d['refresh_token'] as String,
          int.parse(d['expires_in'] as String));
    }
    return _token!;
  }

  Uri _documents(String path, [Map<String, String>? query]) => Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents${path.startsWith(':') ? path : '/$path'}',
      query);

  Future<List<Map<String, dynamic>>> list(String collection) async {
    final token = await _accessToken();
    final rows = <Map<String, dynamic>>[];
    String? next;
    do {
      final d = await _send(
          'GET',
          _documents(collection,
              {'pageSize': '100', if (next != null) 'pageToken': next}),
          token: token);
      for (final doc in (d['documents'] as List? ?? [])) {
        rows.add({
          'id': (doc['name'] as String).split('/').last,
          ...decodeFields(
              Map<String, dynamic>.from(doc['fields'] as Map? ?? {}))
        });
      }
      next = d['nextPageToken'] as String?;
    } while (next != null && next.isNotEmpty);
    return rows;
  }

  Future<void> save(
      String collection, String id, Map<String, dynamic> data) async {
    await _send('PATCH', _documents('$collection/$id'),
        token: await _accessToken(),
        body: {
          'fields': data.map((key, value) => MapEntry(key, encodeValue(value)))
        });
  }

  Future<void> saveBatch(Map<String, Map<String, dynamic>> documents) async {
    await _send('POST', _documents(':commit'),
        token: await _accessToken(),
        body: {
          'writes': documents.entries
              .map((entry) => {
                    'update': {
                      'name':
                          'projects/$projectId/databases/(default)/documents/${entry.key}',
                      'fields': entry.value.map(
                          (key, value) => MapEntry(key, encodeValue(value)))
                    },
                  })
              .toList()
        });
  }

  Future<void> create(
      String collection, String id, Map<String, dynamic> data) async {
    await _send('PATCH',
        _documents('$collection/$id', {'currentDocument.exists': 'false'}),
        token: await _accessToken(),
        body: {
          'fields': data.map((key, value) => MapEntry(key, encodeValue(value)))
        });
  }

  Future<void> delete(String collection, String id) async {
    await _send('DELETE', _documents('$collection/$id'),
        token: await _accessToken());
  }

  void signOut() {
    _token = null;
    _refreshToken = null;
    uid = null;
    email = null;
    admin = false;
  }

  static Map<String, dynamic> encodeValue(dynamic value) {
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is List) {
      return {
        'arrayValue': {'values': value.map(encodeValue).toList()}
      };
    }
    return {'stringValue': value.toString()};
  }

  static dynamic decodeValue(Map<String, dynamic> value) {
    if (value.containsKey('booleanValue')) return value['booleanValue'];
    if (value.containsKey('integerValue')) {
      return int.parse(value['integerValue'] as String);
    }
    if (value.containsKey('arrayValue')) {
      final array = value['arrayValue'] as Map;
      return (array['values'] as List? ?? [])
          .map((v) => decodeValue(Map<String, dynamic>.from(v as Map)))
          .toList();
    }
    return value['stringValue'];
  }

  static Map<String, dynamic> decodeFields(Map<String, dynamic> fields) =>
      fields.map((key, value) =>
          MapEntry(key, decodeValue(Map<String, dynamic>.from(value as Map))));
}
