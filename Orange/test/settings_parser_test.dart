import 'package:flutter_test/flutter_test.dart';
import 'package:ketua_ui/model/setting_model.dart';

void main() {
  test('settings support numeric strings returned by the live API', () {
    final settings = Appdata.fromJson({'min_threshold': '100', 'new_user_free_coins': '0', 'coin_rate': 10, 'is_dating': '1', 'is_social_media': 1, 'message_price': '5'});
    expect(settings.minThreshold, 100);
    expect(settings.newUserFreeCoins, 0);
    expect(settings.coinRate, '10');
    expect(settings.isDating, 1);
    expect(settings.isSocialMedia, 1);
    expect(settings.messagePrice, 5);
  });
}
