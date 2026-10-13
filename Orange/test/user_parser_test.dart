import 'package:flutter_test/flutter_test.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
void main() {
  test('new social account payload accepts server numeric strings and missing profile', () {
    final user = UserModel.fromJson({'status': true, 'token': 'fixture', 'data': {
      'id': 1, 'login_type': '1', 'device_type': '1', 'wallet': '0', 'is_verified': '0',
      'gender': '1', 'gender_preferred': '3', 'is_like': '0', 'is_notification': '1', 'age_preferred_min': null, 'images': [{'id': '1', 'user_id': '35', 'image': 'ketua-qa/sanaa.jpg'}]}});
    expect(user.status, true);
    expect(user.data!.loginType, 1);
    expect(user.data!.deviceType, 1);
    expect(user.data!.wallet, 0);
    expect(user.data!.isLiked, false);
    expect(user.data!.gender.value, 1);
    expect(user.data!.genderPreferred.value, 3);
    expect(user.data!.images!.first.userId, 35);
    expect(user.data!.isVerified, 0);
    expect(user.data!.agePreferredMin, isNull);
  });
}
