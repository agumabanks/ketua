import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:ketua_ui/screen/photo_editor_screen/photo_editor_screen.dart';
import 'package:ketua_ui/utils/const_res.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/common/common_fun.dart';
import 'package:ketua_ui/common/common_ui.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/model/setting_model.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/screen/countries/select_country_controller.dart';
import 'package:ketua_ui/screen/countries/countries_model.dart';
import 'package:ketua_ui/screen/create_profile_screen/create_profile_screen_view_model.dart';
import 'package:ketua_ui/service/extention/datetime_extention.dart';
import 'package:ketua_ui/service/extention/list_extension.dart';
import 'package:ketua_ui/service/extention/string_extention.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/utils/app_res.dart';
import 'package:stacked/stacked.dart';

class EditProfileScreenViewModel extends BaseViewModel {
  UserData? userData;

  EditProfileScreenViewModel(this.userData);

  void init() {
    getPrefSettings();
  }

  final selectCountryController = Get.find<SelectCountryController>();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController aboutController = TextEditingController();
  TextEditingController instagramController = TextEditingController();
  TextEditingController facebookController = TextEditingController();
  TextEditingController youtubeController = TextEditingController();
  DateTime selectedDob =
      DateTime.now().subtract(const Duration(days: 365 * 18));

  List<String> deleteIds = [];

  List<Images> imageList = [];

  bool showDropdown = false;
  bool isLoading = false;
  bool isSaving = false, isPicking = false, _disposed = false;
  final Set<String> _temporaryFiles = {};
  ImagePicker imagePicker = ImagePicker();

  GenderType selectedGender = GenderType.male;
  GenderType selectedGenderPref = GenderType.male;
  SettingData? settingData;

  List<Interests> interestList = [];
  List<RelationshipGoals> relationshipGoals = [];
  List<Religions> religions = [];
  List<Language> languages = [];
  List<Interests> selectedInterests = [];
  RelationshipGoals? selectedRelationShipGoal;
  Religions? selectedReligion;
  List<Language> selectedLanguages = [];

  void getPrefSettings() async {
    settingData = SessionManager.instance.getSettings();
    interestList = (settingData?.interests ?? [])
        .where((element) => element.isDeleted == 0)
        .toList();
    relationshipGoals = (settingData?.relationshipGoals ?? [])
        .where((element) => element.isDeleted == 0)
        .toList();
    religions = (settingData?.religions ?? [])
        .where((element) => element.isDeleted == 0)
        .toList();
    languages = (settingData?.language ?? [])
        .where((element) => element.isDeleted == 0)
        .toList();
    getLocalData();
    notifyListeners();
  }

  void getLocalData() async {
    if (userData == null) return;
    fullNameController.text = userData?.fullname ?? '';
    userNameController.text = userData?.username ?? '';
    bioController.text = userData?.bio ?? '';
    aboutController.text = userData?.about ?? '';
    instagramController.text = userData?.instagram ?? '';
    facebookController.text = userData?.facebook ?? '';
    youtubeController.text = userData?.youtube ?? '';
    imageList = List<Images>.from(userData?.images ?? []);
    selectedGender = userData!.gender;
    selectedGenderPref = userData!.genderPreferred;
    selectedDob = userData?.ageToDateTime ?? selectedDob;
    var country = selectCountryController.allCountries
        .search(userData?.country ?? '', (p0) => p0.countryName)
        .firstOrNull;
    if (country != null) {
      selectCountryController.selectCountry(country: country);
    }
    if (country != null) {
      final savedState = userData?.state ?? '';
      var state = selectCountryController.selectedStatesFromCountry
          .firstWhereOrNull((e) => e.name == savedState);
      state ??= selectCountryController.selectedStatesFromCountry
          .firstWhereOrNull((e) =>
              e.name.toLowerCase() == ('$savedState Region').toLowerCase());
      if (state == null && savedState.isNotEmpty)
        state = CountryState(
            name: savedState,
            countryCode: country.countryCode,
            stateCode: 'saved');
      if (state != null) selectCountryController.selectState(state: state);
      final savedCity = userData?.city ?? '';
      var city = selectCountryController.selectedCitiesFromState
          .firstWhereOrNull((e) => e.name == savedCity);
      if (city == null && savedCity.isNotEmpty)
        city = City(name: savedCity, stateCode: state?.stateCode ?? 'saved');
      if (city != null) selectCountryController.selectCity(city: city);
    }
// Interests
    selectedInterests = (userData?.interests ?? '')
        .split(',')
        .map((id) => interestList
            .firstWhereOrNull((e) => e.id.toString() == id && e.isDeleted == 0))
        .whereType<Interests>()
        .toList();

    // Relationship Goal
    selectedRelationShipGoal = relationshipGoals.firstWhereOrNull(
        (e) => e.isDeleted == 0 && e.id == userData?.relationshipGoalId);

    // Religion
    selectedReligion = religions.firstWhereOrNull((e) =>
        e.isDeleted == 0 &&
        e.titleRemoveEmoji == userData?.religionKey?.removeEmojis.trim());

    // Languages
    selectedLanguages = (userData?.languageKeys ?? '')
        .split(',')
        .map((id) => languages.firstWhereOrNull((e) =>
            e.isDeleted == 0 && e.title?.removeEmojis.trim() == id.trim()))
        .whereType<Language>()
        .toList();

    notifyListeners();
  }

  void onImageRemove(Images image, int index) {
    if (isSaving || isPicking) return;
    imageList.removeAt(index);
    if (image.id != -1) {
      deleteIds.add("${image.id}");
    }
    notifyListeners();
  }

  void onAllScreenTap() {
    showDropdown = false;
    notifyListeners();
  }

  Future<void> onSaveTap() async {
    if (isSaving || isPicking) return;
    if (imageList.isEmpty) {
      return CommonUI.snackBarWidget(S.current.pleaseAddAtLeastEtc);
    }
    if (fullNameController.text.trim().isEmpty) {
      return CommonUI.snackBarWidget(S.current.enterFullName);
    }
    if (userNameController.text.trim().isEmpty) {
      return CommonUI.snackBarWidget(S.current.enterUsername);
    }
    if (bioController.text.trim().isEmpty) {
      return CommonUI.snackBarWidget(S.current.enterBio);
    }
    if (selectCountryController.selectedCountry.value == null) {
      return CommonUI.snackBar(message: S.current.pleaseSelectCountry);
    }
    if (selectCountryController.selectedState.value == null) {
      return CommonUI.snackBar(message: S.current.pleaseSelectState);
    }
    if (selectCountryController.selectedCity.value == null) {
      return CommonUI.snackBar(message: S.current.pleaseSelectCity);
    }
    if (selectedInterests.isEmpty) {
      return CommonUI.snackBarWidget(S.current.selectInterestsToContinue);
    }
    if (selectedRelationShipGoal == null) {
      return CommonUI.snackBarWidget(S.current.selectYourRelationshipGoal);
    }
    if (selectedLanguages.isEmpty) {
      return CommonUI.snackBarWidget(S.current.selectYourLanguage);
    }

    List<XFile> imageFile = [];

    for (var element in imageList) {
      if (element.id == -1) {
        imageFile.add(XFile(element.image ?? ''));
      }
    }
    // print(imageFile.map((e) => e.path));
    // return;
    isSaving = true;
    notifyListeners();
    try {
      final value = await ApiProvider().updateProfile(
        images: imageFile,
        imageOrder: _imageOrder(),
        deleteImageIds: deleteIds,
        fullName: fullNameController.text.trim(),
        userName: userNameController.text.trim(),
        bio: bioController.text.trim(),
        about: aboutController.text.trim(),
        country: selectCountryController.selectedCountry.value?.countryName,
        state: selectCountryController.selectedState.value?.name,
        city: selectCountryController.selectedCity.value?.name,
        dob: selectedDob.dobFormat,
        gender: selectedGender.value,
        instagram: instagramController.text.trim(),
        facebook: facebookController.text.trim(),
        youtube: youtubeController.text.trim(),
        genderPreferred: selectedGenderPref.value,
        interest: selectedInterests.map((e) => '${e.id}').toList(),
        relationshipGoalId: selectedRelationShipGoal?.id,
        religionKey: selectedReligion?.title?.removeEmojis.trim(),
        languageKeys: selectedLanguages
            .map((e) => e.title?.removeEmojis.trim())
            .join(','),
      );
      if (_disposed) return;
      if (value.status != true || value.data == null) {
        CommonUI.snackBarWidget(
            value.message ?? 'Unable to save your profile.');
        return;
      }
      Get.back(result: value.data);
    } catch (_) {
      if (!_disposed)
        CommonUI.snackBarWidget(
            'Unable to save. Your changes are still here. Please retry.');
    } finally {
      if (!_disposed) {
        isSaving = false;
        notifyListeners();
      }
    }
  }

  List<String> _imageOrder() {
    var index = 0;
    return imageList
        .map((image) => image.id == -1 ? 'new:${index++}' : '${image.id}')
        .toList();
  }

  void makeCover(int index) {
    if (isSaving || isPicking || index == 0) return;
    final image = imageList.removeAt(index);
    imageList.insert(0, image);
    notifyListeners();
  }

  Future<void> selectImages() async {
    if (isPicking || isSaving) return;
    if (imageList.length >= 6) {
      CommonUI.snackBarWidget('You can add up to 6 photos.');
      return;
    }
    isPicking = true;
    notifyListeners();
    try {
      final images = await imagePicker.pickMultiImage(
          imageQuality: AppRes.quality,
          maxWidth: AppRes.maxWidth,
          maxHeight: AppRes.maxHeight);
      if (_disposed) return;
      final available = 6 - imageList.length;
      if (images.length > available)
        CommonUI.snackBarWidget(
            'Only the first $available photos will be added.');
      for (final image in images.take(available)) {
        final edited =
            await Get.to<String>(() => PhotoEditorScreen(path: image.path));
        if (_disposed) return;
        if (edited != null) {
          _temporaryFiles.add(edited);
          imageList.add(Images(id: -1, image: edited));
          notifyListeners();
        }
      }
    } catch (_) {
      if (!_disposed)
        CommonUI.snackBarWidget('Unable to open photos. Please try again.');
    } finally {
      if (!_disposed) {
        isPicking = false;
        notifyListeners();
        if (imageList.any((p) => p.id == -1)) await _savePhotosAutomatically();
      }
    }
  }

  Future<void> editPhoto(int index) async {
    if (isSaving || isPicking) return;
    isPicking = true;
    notifyListeners();
    try {
      final original = imageList[index];
      var path = original.image!;
      if (original.id != -1) {
        final uri = Uri.parse('${ConstRes.aImageBaseUrl}$path');
        if (uri.host != Uri.parse(ConstRes.aImageBaseUrl).host)
          throw StateError('Invalid photo');
        final response =
            await http.get(uri).timeout(const Duration(seconds: 15));
        if (response.statusCode != 200 ||
            response.bodyBytes.length > 10 * 1024 * 1024)
          throw StateError('Photo unavailable');
        final dir = await getTemporaryDirectory();
        path =
            '${dir.path}/ketua_source_${DateTime.now().microsecondsSinceEpoch}.jpg';
        await File(path).writeAsBytes(response.bodyBytes);
        _temporaryFiles.add(path);
      }
      if (_disposed) return;
      final edited = await Get.to<String>(() => PhotoEditorScreen(path: path));
      if (_disposed || edited == null) return;
      _temporaryFiles.add(edited);
      if (original.id != -1) deleteIds.add('${original.id}');
      imageList[index] = Images(id: -1, image: edited);
      notifyListeners();
    } catch (_) {
      if (!_disposed)
        CommonUI.snackBarWidget('Unable to edit this photo. Please retry.');
    } finally {
      if (!_disposed) {
        isPicking = false;
        notifyListeners();
        if (imageList.any((p) => p.id == -1)) await _savePhotosAutomatically();
      }
    }
  }

  Future<void> _savePhotosAutomatically() async {
    if (_disposed || isSaving || isPicking || imageList.isEmpty) return;
    isSaving = true;
    notifyListeners();
    try {
      final response = await ApiProvider().updateProfile(
        images: imageList
            .where((p) => p.id == -1)
            .map((p) => XFile(p.image!))
            .toList(),
        imageOrder: _imageOrder(),
        deleteImageIds: List.of(deleteIds),
      );
      if (_disposed) return;
      if (response.status != true || response.data == null) {
        CommonUI.snackBarWidget(
            response.message ?? 'Photo not saved. Tap Save to retry.');
        return;
      }
      userData = response.data;
      imageList = List<Images>.from(response.data!.images ?? []);
      deleteIds.clear();
      CommonUI.snackBarWidget('Photos updated');
    } catch (_) {
      if (!_disposed)
        CommonUI.snackBarWidget(
            'Photo not saved. Your edit is kept; tap Save to retry.');
    } finally {
      if (!_disposed) {
        isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshLocation() async {
    final position = await CommonFun.getUserCurrentLocation();
    if (!_disposed)
      CommonUI.snackBarWidget(position == null
          ? 'Location unavailable. Check device permissions and try again.'
          : 'Location refreshed. Distance updates when both people have a recent location.');
  }

  void onDateOfBirthTap(BuildContext context) {
    final now = DateTime.now();
    final last = DateTime(now.year - 18, now.month, now.day);
    showDatePicker(
            context: context,
            initialDate: selectedDob.isAfter(last) ? last : selectedDob,
            firstDate: DateTime(1900),
            lastDate: last)
        .then((date) {
      if (date != null && !_disposed) {
        selectedDob = date;
        notifyListeners();
      }
    });
  }

  void onGenderTap(GenderType type) {
    selectedGender = type;
    notifyListeners();
  }

  onSelectInterestTap(Interests interest) {
    final id = interest.id;
    if (id == null) return;

    final isAlreadySelected = selectedInterests.any((e) => e.id == id);

    if (isAlreadySelected) {
      selectedInterests.removeWhere((e) => e.id == id);
    } else {
      selectedInterests.add(interest);
    }

    notifyListeners();
  }

  onRelationshipGoalTap(RelationshipGoals goal) {
    selectedRelationShipGoal = goal;
    notifyListeners();
  }

  onReligionTap(Religions religion) {
    selectedReligion = religion;
    notifyListeners();
  }

  onLanguagesTap(Language language) {
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

  @override
  void dispose() {
    _disposed = true;
    for (final path in _temporaryFiles) {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    }
    userNameController.dispose();
    fullNameController.dispose();
    bioController.dispose();
    aboutController.dispose();
    instagramController.dispose();
    facebookController.dispose();
    youtubeController.dispose();
    super.dispose();
  }
}
