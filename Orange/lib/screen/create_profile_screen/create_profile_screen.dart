import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ketua_ui/common/button/custom_text_button.dart';
import 'package:ketua_ui/common/custom_text_field.dart';
import 'package:ketua_ui/common/login_setup_view.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/screen/create_profile_screen/create_profile_screen_view_model.dart';
import 'package:ketua_ui/screen/create_profile_screen/widget/border_text_card.dart';
import 'package:ketua_ui/utils/asset_res.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/font_res.dart';
import 'package:stacked/stacked.dart';

class CreateProfileScreen extends StatelessWidget {
  const CreateProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<CreateProfileScreenViewModel>.reactive(
        viewModelBuilder: () => Get.find<CreateProfileScreenViewModel>(),
        disposeViewModel: false,
        builder: (context, viewModel, child) {
          return LoginSetupView(
            title: S.of(context).createProfile,
            description: S.of(context).letsSetUpYourPerfectProfile,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 20,
                      children: [
                        CustomTextField(
                            title: S.current.fullName,
                            prefixIcon: AssetRes.icProfileUser,
                            controller: viewModel.fullnameController),
                        CustomTextField(
                          controller: viewModel.bioController,
                          height: 90,
                          title: S.current.bio,
                          isExpand: true,
                        ),
                        CustomTextField(
                          controller: viewModel.aboutController,
                          height: 90,
                          title: S.current.about,
                          isExpand: true,
                        ),
                        CustomTextField(
                          title: S.current.dateOfBirth,
                          child: DateOfBirthTiles(
                              onTap: () => viewModel.onDateOfBirthTap(context),
                              selectedDob: viewModel.selectedDob,
                              hasChosenDob: viewModel.dobConfirmed),
                        ),
                        GenderTiles(
                            selectedType: viewModel.selectedGenderType,
                            onTap: viewModel.onGenderTap),
                        Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: ColorRes.surfaceDark,
                                borderRadius: BorderRadius.circular(24)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Your area',
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 8),
                                  const Text(
                                      'Find people nearby. Your exact position stays private.',
                                      style: TextStyle(
                                          color: ColorRes.textSecondaryDark)),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                      onPressed: viewModel.locating
                                          ? null
                                          : viewModel.detectLocation,
                                      icon: const Icon(Icons.my_location),
                                      label: Text(viewModel.locating
                                          ? 'Finding your location…'
                                          : 'Use my location')),
                                  if (viewModel.locationMessage != null)
                                    Text(viewModel.locationMessage!,
                                        style: const TextStyle(
                                            color: ColorRes.textSecondaryDark)),
                                  TextField(
                                      controller: viewModel.countryText,
                                      onChanged: (_) =>
                                          viewModel.notifyListeners(),
                                      decoration: const InputDecoration(
                                          labelText: 'Country',
                                          hintText: 'Uganda')),
                                  TextField(
                                      controller: viewModel.districtText,
                                      decoration: InputDecoration(
                                          labelText: viewModel.isUganda
                                              ? 'District'
                                              : 'District / region',
                                          hintText: 'e.g. Wakiso')),
                                  TextField(
                                      controller: viewModel.townText,
                                      decoration: const InputDecoration(
                                          labelText: 'Town / city',
                                          hintText: 'e.g. Kira')),
                                ])),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                CustomTextButton(
                  onTap: () => viewModel
                      .onContinueTap(CreateProfileContinueTap.createProfile),
                )
              ],
            ),
          );
        });
  }
}

class DateOfBirthTiles extends StatelessWidget {
  final VoidCallback onTap;
  final DateTime selectedDob;
  final bool hasChosenDob;

  const DateOfBirthTiles(
      {super.key,
      required this.onTap,
      required this.selectedDob,
      this.hasChosenDob = true});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image.asset(
              AssetRes.icCalender,
              height: 20,
              width: 20,
              color: ColorRes.dimGrey3,
            ),
          ),
          Expanded(
            child: Text(
              hasChosenDob
                  ? DateFormat('dd-MMM-yyyy').format(selectedDob)
                  : S.of(context).dateOfBirth,
              style: const TextStyle(
                  color: ColorRes.dimGrey3,
                  fontFamily: FontRes.medium,
                  fontSize: 16),
            ),
          )
        ],
      ),
    );
  }
}

class GenderTiles extends StatelessWidget {
  final String? title;
  final GenderType selectedType;
  final Function(GenderType type) onTap;

  const GenderTiles(
      {super.key, required this.selectedType, required this.onTap, this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        TitleTextView(title: (title ?? S.current.gender).capitalize ?? ''),
        Row(
          spacing: 10,
          children: List.generate(
            CreateProfileScreenViewModel.profileGenders.length,
            (index) {
              GenderType type =
                  CreateProfileScreenViewModel.profileGenders[index];
              bool isSelected = selectedType.value ==
                  CreateProfileScreenViewModel.profileGenders[index].value;
              return Expanded(
                child: BorderTextCard(
                  onTap: () => onTap(type),
                  text: type.title,
                  isSelected: isSelected,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
