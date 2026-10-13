import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ketua_ui/screen/photo_editor_screen/photo_editor_screen.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/common/common_fun.dart';
import 'package:ketua_ui/common/common_ui.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/model/setting_model.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/screen/create_profile_screen/view/add_photos.dart';
import 'package:ketua_ui/screen/create_profile_screen/view/choose_religion.dart';
import 'package:ketua_ui/screen/create_profile_screen/view/find_matches.dart';
import 'package:ketua_ui/screen/create_profile_screen/view/relationship_goal.dart';
import 'package:ketua_ui/screen/create_profile_screen/view/select_interest.dart';
import 'package:ketua_ui/screen/create_profile_screen/view/select_languages.dart';
import 'package:ketua_ui/screen/create_profile_screen/view/your_profile_ready.dart';
import 'package:ketua_ui/screen/dashboard/dashboard_screen.dart';
import 'package:ketua_ui/service/extention/datetime_extention.dart';
import 'package:ketua_ui/service/extention/string_extention.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/utils/app_res.dart';
import 'package:stacked/stacked.dart';

class CreateProfileScreenViewModel extends BaseViewModel {
  TextEditingController fullnameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController aboutController = TextEditingController();
  final countryText = TextEditingController();
  final districtText = TextEditingController();
  final townText = TextEditingController();
  Position? locationFix;
  bool locating = false;
  bool pickingPhotos = false;
  bool saving = false;
  String? locationMessage;
  bool get isUganda => countryText.text.trim().toLowerCase() == 'uganda';
  Future<void> detectLocation() async {
    if (locating) return;
    locating = true;
    locationMessage = null;
    notifyListeners();
    try {
      final fix = await CommonFun.getUserCurrentLocation(
          shouldUpdateInProfileData: false);
      if (fix == null) throw StateError('Location unavailable');
      locationFix = fix;
      final places = await Geocoding()
          .placemarkFromCoordinates(fix.latitude, fix.longitude)
          .timeout(const Duration(seconds: 10));
      if (places.isNotEmpty) {
        final p = places.first;
        if (p.country?.isNotEmpty == true) countryText.text = p.country!;
        // Uganda's region is not its district. Leave the district editable when
        // the platform geocoder cannot provide that administrative level.
        districtText.text = (p.isoCountryCode == 'UG'
                ? p.subAdministrativeArea
                : p.administrativeArea) ??
            '';
        townText.text = p.locality?.isNotEmpty == true
            ? p.locality!
            : (p.subLocality ?? '');
      }
      locationMessage =
          'Location detected (about ${fix.accuracy.round()} m accuracy). Check your district and town.';
    } catch (_) {
      locationMessage = locationFix == null
          ? 'Location unavailable. Turn on device location or enter your area below.'
          : 'GPS detected. Enter your country, district and town below.';
    } finally {
      locating = false;
      notifyListeners();
    }
  }

  bool dobConfirmed = false;
  DateTime selectedDob =
      DateTime.now().subtract(const Duration(days: 365 * 18));
  static const profileGenders = [GenderType.male, GenderType.female];
  List<GenderType> genderTypes = profileGenders;
  List<GenderType> preferredGenderTypes = GenderType.values;
  GenderType selectedPreferredGender = GenderType.male;
  GenderType selectedGenderType = GenderType.male;
  SettingData? settingData;

  List<RelationshipGoals> relationshipGoals = [];
  List<Interests> interestList = [];
  List<Interests> selectedInterest = [];
  List<Religions> religions = [];
  List<Language> languages = [];
  List<Language> selectedLanguages = [];
  List<Photo> images = [];
  List<Photo> deletedImages = [];

  RelationshipGoals? selectedRelationShipGoal;
  Religions? selectedReligion;

  RangeValues selectedAgeRange = const RangeValues(AppRes.ageMin, 35);
  double selectedDistance = AppRes.defaultDistancePreference;
  UserData? userData;

  void init(UserData userData) {
    this.userData = userData;
    countryText.text = userData.country ?? '';
    districtText.text = userData.state ?? '';
    townText.text = userData.city ?? '';
    locationFix = null;
    fullnameController = TextEditingController(text: userData.fullname ?? '');
    bioController = TextEditingController(text: userData.bio ?? '');
    aboutController = TextEditingController(text: userData.about ?? '');
    selectedDob = userData.ageToDateTime;
    dobConfirmed = userData.dob?.isNotEmpty == true;
    settingData = SessionManager.instance.getSettings();
    images.clear();
    deletedImages.clear();
    selectedInterest.clear();
    selectedLanguages.clear();
    selectedGenderType = userData.gender;
    selectedPreferredGender = userData.genderPreferred;
    selectedAgeRange = RangeValues(
        (userData.agePreferredMin ?? AppRes.ageMin).toDouble(),
        (userData.agePreferredMax ?? 35).toDouble());
    selectedDistance =
        (userData.distancePreference ?? AppRes.defaultDistancePreference)
            .toDouble();
    initImage();

    _initializeUserPreferences();
    notifyListeners();
  }

  void onDateOfBirthTap(BuildContext context) {
    CommonFun.showDatePicker(
      context,
      selectedDob,
      onDateSelected: (time) {
        selectedDob = time;
        dobConfirmed = true;
        notifyListeners();
      },
    );
  }

  void onGenderTap(GenderType value) {
    selectedGenderType = value;
    notifyListeners();
  }

  void onPreferredGenderTap(GenderType preferredGenderTyp) {
    selectedPreferredGender = preferredGenderTyp;
    notifyListeners();
  }

  void onChangeAgeRange(RangeValues value) {
    selectedAgeRange = value;
    notifyListeners();
  }

  void onChangeDistance(double value) {
    selectedDistance = value;
    notifyListeners();
  }

  void onChangedRelationshipGoal(RelationshipGoals goal) {
    selectedRelationShipGoal = goal;
    notifyListeners();
  }

  void onSelectInterest(Interests interest) {
    final id = interest.id;
    if (id == null) return;

    final isAlreadySelected = selectedInterest.any((e) => e.id == id);

    if (isAlreadySelected) {
      selectedInterest.removeWhere((e) => e.id == id);
    } else {
      selectedInterest.add(interest);
    }

    notifyListeners();
  }

  void onSelectReligion(Religions religion) {
    selectedReligion = religion;
    notifyListeners();
  }

  void onSelectLanguages(Language language) {
    final id = language.id;
    if (id == null) return;

    final isAlreadySelected = selectedLanguages.any((e) => e.id == id);

    if (isAlreadySelected) {
      selectedLanguages.removeWhere((e) => e.id == id);
    } else {
      selectedLanguages.add(language);
    }

    notifyListeners();
  }

  Future<void> addImages() async {
    if (pickingPhotos || images.length >= AppRes.maxImages) return;
    pickingPhotos = true;
    notifyListeners();
    try {
      final remaining = AppRes.maxImages - images.length;
      final picker = ImagePicker();
      final List<XFile> picked;
      if (remaining == 1) {
        final file = await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: AppRes.quality,
            maxHeight: AppRes.maxHeight,
            maxWidth: AppRes.maxWidth);
        picked = file == null ? <XFile>[] : [file];
      } else {
        picked = await picker.pickMultiImage(
            limit: remaining,
            imageQuality: AppRes.quality,
            maxHeight: AppRes.maxHeight,
            maxWidth: AppRes.maxWidth);
      }
      for (final file in picked.take(AppRes.maxImages - images.length)) {
        final path =
            await Get.to<String>(() => PhotoEditorScreen(path: file.path));
        if (path != null) {
          images.add(Photo(-1, XFile(path)));
          notifyListeners();
        }
      }
    } catch (_) {
      CommonUI.snackBar(message: 'Unable to open photos. Please try again.');
    } finally {
      pickingPhotos = false;
      notifyListeners();
    }
  }

  Future<void> editOnboardingPhoto(int index) async {
    if (pickingPhotos || index >= images.length) return;
    pickingPhotos = true;
    notifyListeners();
    final original = images[index];
    try {
      final source = original.id == -1
          ? original.file.path
          : (await DefaultCacheManager()
                  .getSingleFile(original.file.path.addBaseURL()))
              .path;
      final path = await Get.to<String>(() => PhotoEditorScreen(path: source));
      if (path != null) {
        if (original.id != -1) deletedImages.add(original);
        images[index] = Photo(-1, XFile(path));
        notifyListeners();
      }
    } catch (_) {
      CommonUI.snackBar(
          message: 'Unable to edit this photo. Please try again.');
    } finally {
      pickingPhotos = false;
      notifyListeners();
    }
  }

  void onDeleteImage(Photo file, int index) {
    if (file.id != -1) {
      deletedImages.add(file);
    }
    images.removeAt(index);
    notifyListeners();
  }

  void onContinueTap(CreateProfileContinueTap value) {
    switch (value) {
      case CreateProfileContinueTap.createProfile:
        createProfile();
        break;
      case CreateProfileContinueTap.findMatches:
        findMatches();
        break;
      case CreateProfileContinueTap.interest:
        chooseInterest();
        break;
      case CreateProfileContinueTap.relationGoal:
        chooseRelationshipGoal();
        break;
      case CreateProfileContinueTap.religion:
        chooseReligion();
        break;
      case CreateProfileContinueTap.language:
        chooseLanguages();
        break;
      case CreateProfileContinueTap.addPhoto:
        addPhotos();
        break;
      case CreateProfileContinueTap.finalProfile:
        tapFinalProfile();
        break;
    }
  }

  void createProfile() {
    if (!dobConfirmed || selectedDob.dateTimeToAge < 18) {
      return CommonUI.snackBar(message: S.current.dateOfBirth);
    }
    if (fullnameController.text.trim().isEmpty) {
      return CommonUI.snackBar(message: S.current.enterFullName);
    }
    if (bioController.text.trim().isEmpty) {
      return CommonUI.snackBar(message: S.current.enterBio);
    }

    if (countryText.text.trim().isEmpty ||
        districtText.text.trim().isEmpty ||
        townText.text.trim().isEmpty) {
      return CommonUI.snackBar(
          message: 'Enter your country, district/region and town.');
    }

    if (settingData?.appdata?.isDating == 1) {
      selectedPreferredGender = selectedGenderType == GenderType.male
          ? GenderType.female
          : GenderType.male;
      notifyListeners();
      Get.to(() => FindMatches(model: this));
    } else {
      Get.to(() => SelectInterest(model: this));
    }
  }

  void findMatches() {
    Get.to(() => SelectInterest(model: this));
  }

  void chooseInterest() {
    if (selectedInterest.isEmpty) {
      return CommonUI.snackBar(message: S.current.selectInterestsToContinue);
    }
    if (settingData?.appdata?.isDating == 0) {
      Get.to(() => AddPhotos(model: this));
    } else {
      Get.to(() => RelationshipGoal(model: this));
    }
  }

  void chooseRelationshipGoal() {
    if (selectedRelationShipGoal == null) {
      return CommonUI.snackBar(message: S.current.selectYourRelationshipGoal);
    }
    Get.to(() => ChooseReligion(model: this));
  }

  void chooseReligion() {
    if (selectedReligion == null) {
      return CommonUI.snackBar(message: S.current.selectYourReligion);
    }
    Get.to(() => SelectLanguages(model: this));
  }

  void chooseLanguages() {
    if (selectedLanguages.isEmpty) {
      return CommonUI.snackBar(message: S.current.selectYourLanguage);
    }
    Get.to(() => AddPhotos(model: this));
  }

  void addPhotos() {
    if (images.isEmpty) {
      return CommonUI.snackBar(message: S.current.addPhotos);
    }
    Get.to(() => YourProfileReady(model: this));
  }

  initImage() {
    for (Images element in (userData?.images ?? [])) {
      if (element.image != null) {
        images.add(Photo(element.id ?? -1, XFile(element.image!)));
      }
    }
  }

  void _initializeUserPreferences() {
    interestList =
        settingData?.interests?.where((e) => e.isDeleted == 0).toList() ?? [];
    List<String> savedInterest = userData?.interests?.split(',') ?? [];
    interestList.toList().forEach((element) {
      if (savedInterest.contains('${element.id}')) {
        selectedInterest.add(element);
      }
    });

    relationshipGoals = settingData?.relationshipGoals
            ?.where((e) => e.isDeleted == 0)
            .toList() ??
        [];

    religions =
        settingData?.religions?.where((e) => e.isDeleted == 0).toList() ?? [];

    languages =
        settingData?.language?.where((e) => e.isDeleted == 0).toList() ?? [];
    selectedRelationShipGoal = relationshipGoals
        .firstWhereOrNull((goal) => goal.id == userData?.relationshipGoalId);
    selectedReligion = religions.firstWhereOrNull(
        (religion) => religion.title == userData?.religionKey);
    final savedLanguages =
        userData?.languageKeys?.split(',').map((e) => e.trim()).toSet() ??
            <String>{};
    selectedLanguages.addAll(languages.where((language) =>
        savedLanguages.contains(language.title?.removeEmojis.trim())));
  }

  void tapFinalProfile() {
    bool isDating = settingData?.appdata?.isDating == 1;
    if (fullnameController.text.trim().isEmpty) {
      return CommonUI.snackBar(message: S.current.enterFullName);
    }
    if (bioController.text.trim().isEmpty) {
      return CommonUI.snackBar(message: S.current.enterBio);
    }

    if (countryText.text.trim().isEmpty ||
        districtText.text.trim().isEmpty ||
        townText.text.trim().isEmpty) {
      return CommonUI.snackBar(
          message: 'Enter your country, district/region and town.');
    }

    if (selectedInterest.isEmpty) {
      return CommonUI.snackBar(message: S.current.selectInterestsToContinue);
    }
    if (isDating) {
      if (selectedRelationShipGoal == null) {
        return CommonUI.snackBar(message: S.current.selectYourRelationshipGoal);
      }
      if (selectedReligion == null) {
        return CommonUI.snackBar(message: S.current.selectYourReligion);
      }
      if (selectedLanguages.isEmpty) {
        return CommonUI.snackBar(message: S.current.selectYourLanguage);
      }
    }

    if (images.isEmpty) {
      return CommonUI.snackBar(message: S.current.addPhotos);
    }
    updateProfile();
  }

  void updateProfile() {
    List<XFile> image =
        images.where((element) => element.id == -1).map((e) => e.file).toList();

    if (saving) return;
    saving = true;
    CommonUI.lottieLoader();
    ApiProvider()
        .updateProfile(
            fullName: fullnameController.text.trim(),
            bio: bioController.text.trim(),
            about: aboutController.text.trim(),
            dob: selectedDob.dobFormat,
            gender: selectedGenderType.value,
            country: countryText.text.trim(),
            state: districtText.text.trim(),
            city: townText.text.trim(),
            latitude: locationFix?.latitude.toString(),
            longitude: locationFix?.longitude.toString(),
            locationAccuracy: locationFix?.accuracy,
            genderPreferred: selectedPreferredGender.value,
            ageMin: selectedAgeRange.start,
            ageMax: selectedAgeRange.end,
            distancePreference: selectedDistance,
            interest: selectedInterest.map((e) => '${e.id}').toList(),
            relationshipGoalId: selectedRelationShipGoal?.id,
            religionKey: selectedReligion?.title,
            languageKeys:
                selectedLanguages.map((e) => e.title?.removeEmojis).join(','),
            images: image,
            deleteImageIds: deletedImages.map((e) => '${e.id}').toList())
        .then((value) {
      saving = false;
      Get.back();
      if (value.status == true) {
        Get.offAll(() => const DashboardScreen());
      } else {
        CommonUI.snackBar(message: value.message ?? '');
      }
    }).catchError((Object e) {
      saving = false;
      Get.back();
      CommonUI.snackBar(
          message: 'Unable to save your profile. Your entries are still here.');
    });
  }
}

enum GenderType {
  male(1),
  female(2),
  other(3);

  final int value;

  const GenderType(this.value);

  String get title {
    switch (this) {
      case GenderType.male:
        return '👨 ${S.current.male}';
      case GenderType.female:
        return '👩‍🦰 ${S.current.female}';
      case GenderType.other:
        return S.current.other;
    }
  }

  static GenderType fromString(int? value) {
    return GenderType.values.firstWhereOrNull((e) => e.value == value) ??
        GenderType.male;
  }
}

enum CreateProfileContinueTap {
  createProfile,
  findMatches,
  interest,
  relationGoal,
  religion,
  language,
  addPhoto,
  finalProfile
}

class Photo {
  int id;
  XFile file;

  Photo(this.id, this.file);
}
