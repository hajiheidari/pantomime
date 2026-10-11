import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantomime/features/share/invite.dart';
import 'package:pantomime/features/share/share_link.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SharedPreferences> prefs() async {
    SharedPreferences.setMockInitialValues({});
    return SharedPreferences.getInstance();
  }

  test('code is made once and kept', () async {
    final p = await prefs();
    final code = InviteService(p).code;
    expect(code, matches(RegExp(r'^[A-Z2-9]{8}$')));
    expect(InviteService(p).code, code);
  });

  test(
    'no visits → stays locked; a visit on any server → unlocked for good',
    () async {
      final p = await prefs();
      var iranVisits = 0;
      final client = MockClient((req) async {
        if (req.url.host == 'espadna.ir') {
          return http.Response('{"visits":$iranVisits}', 200);
        }
        throw Exception('offline');
      });
      final service = InviteService(p, client: client);
      expect(await service.check(), isFalse);
      expect(service.unlockedForever, isFalse);
      iranVisits = 1;
      expect(await service.check(), isTrue);
      expect(InviteService(p).unlockedForever, isTrue);
    },
  );

  test('shared links carry the code', () {
    inviteCode = 'K7Q2ABCD';
    expect(
      withShareLink('hi', 'fa'),
      endsWith('/pantomime-app/fa/?i=K7Q2ABCD'),
    );
    inviteCode = null;
    expect(withShareLink('hi', 'fa'), endsWith('/pantomime-app/fa/'));
  });
}
