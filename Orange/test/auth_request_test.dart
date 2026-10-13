import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/model/search/filter_profile_model.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/utils/const_res.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SessionManager.instance.setAuthToken('qa-session-token');
  });
  test('generic requests carry user auth only to KETUA origin', () async {
    final seen = <http.Request>[];
    final api = ApiProvider(client: MockClient((request) async {
      seen.add(request);
      return http.Response('{"status":true,"data":[]}', 200);
    }));
    await api.callPost(url: '${ConstRes.aBaseUrl}filteredProfiles', completion: (_) {});
    await api.callPost(url: 'https://third-party.invalid/location', completion: (_) {});
    expect(seen.first.headers['Authorization'], 'Bearer qa-session-token');
    expect(seen.last.headers.containsKey('Authorization'), false);
    expect(seen.last.headers.containsKey('apikey'), false);
  });
  test('failed generic request completes with an error instead of leaving a spinner', () async {
    final api = ApiProvider(client: MockClient((_) async => throw StateError('offline')));
    Object? result;
    await api.callPost(url: '${ConstRes.aBaseUrl}filteredProfiles', completion: (r) => result = r);
    expect(FilterProfileModel.fromJson(result).status, false);
    expect(FilterProfileModel.fromJson({'status':false,'message':'Unauthenticated.'}).data, isEmpty);
  });
}
