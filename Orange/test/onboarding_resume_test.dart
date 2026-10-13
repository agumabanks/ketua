import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/screen/create_profile_screen/create_profile_screen_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => Get.reset());
  test('resuming setup preserves existing preferences and owned photos', () {
    final user = UserData.fromJson({
      'id': 39, 'fullname': 'Phone QA', 'gender': 2, 'gender_preferred': 3,
      'age_preferred_min': 25, 'age_preferred_max': 45,
      'distance_preference': 80, 'country': 'Uganda', 'state': 'Central', 'city': 'Kampala',
      'images': [{'id': 6, 'image': 'ketua-qa/photo.jpg'}],
    });
    final model = CreateProfileScreenViewModel();
    model.init(user);
    expect(model.selectedGenderType, GenderType.female);
    expect(model.selectedPreferredGender, GenderType.other);
    expect(model.selectedAgeRange.start, 25);
    expect(model.selectedAgeRange.end, 45);
    expect(model.selectedDistance, 80);
    expect(model.images.single.id, 6);
    model.init(user);
    expect(model.images.length, 1);
    expect(model.userData?.city, 'Kampala');
  });
}
