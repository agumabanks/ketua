import 'package:ketua_ui/common/ketua_copy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/model/setting_model.dart';
import 'package:ketua_ui/screen/create_profile_screen/create_profile_screen_view_model.dart';
import 'package:ketua_ui/screen/edit_profile_screen/edit_profile_screen_view_model.dart';
import 'package:ketua_ui/utils/color_res.dart';

class TextFieldsArea extends StatelessWidget {
  final EditProfileScreenViewModel model;
  const TextFieldsArea({super.key, required this.model});
  Widget _field(String label, TextEditingController controller,
          {int lines = 1, int? maxLength, String? hint}) =>
      TextField(
          enabled: !model.isSaving,
          controller: controller,
          maxLines: lines,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              filled: true,
              fillColor: ColorRes.bgDark,
              alignLabelWithHint: true,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              counterStyle:
                  const TextStyle(color: ColorRes.textSecondaryDark)));
  Widget _section(String title, IconData icon, List<Widget> children) =>
      Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: ColorRes.surfaceDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: ColorRes.borderDark)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: ColorRes.ketuaAccent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(KetuaCopy.label(title),
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w800)))
            ]),
            const SizedBox(height: 18),
            ...children
          ]));
  Widget _label(String value) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(KetuaCopy.label(value),
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: ColorRes.textSecondaryDark)));
  Widget _choices<T>(List<T> items, List<T> selected, String Function(T) name,
          void Function(T) onTap) =>
      Wrap(
          spacing: 8,
          runSpacing: 6,
          children: items
              .map((item) => ChoiceChip(
                  label: Text(name(item)),
                  selected: selected.contains(item),
                  onSelected: model.isSaving ? null : (_) => onTap(item)))
              .toList());
  Future<void> _pick<T>(BuildContext context, String title, List<T> items,
      String Function(T) label, void Function(T) selected) async {
    var query = '';
    final value = await showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: ColorRes.surfaceDark,
        builder: (context) => StatefulBuilder(
            builder: (context, set) => SafeArea(
                child: SizedBox(
                    height: MediaQuery.sizeOf(context).height * .75,
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            20, 8, 20, MediaQuery.viewInsetsOf(context).bottom),
                        child: Column(children: [
                          Text(KetuaCopy.label(title),
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 14),
                          TextField(
                              decoration: const InputDecoration(
                                  hintText: 'Search',
                                  prefixIcon: Icon(Icons.search)),
                              onChanged: (v) =>
                                  set(() => query = v.toLowerCase())),
                          const SizedBox(height: 12),
                          Expanded(
                              child: ListView(
                                  children: items
                                      .where((e) => label(e)
                                          .toLowerCase()
                                          .contains(query))
                                      .map((e) => ListTile(
                                          title: Text(label(e)),
                                          onTap: () =>
                                              Navigator.pop(context, e)))
                                      .toList()))
                        ]))))));
    if (value != null) selected(value);
  }

  @override
  Widget build(BuildContext context) {
    final countries = model.selectCountryController;
    return Column(children: [
      _section('The basics', Icons.person_outline_rounded, [
        _field(S.current.enterFullName, model.fullNameController,
            maxLength: 100),
        const SizedBox(height: 12),
        _field(S.current.username, model.userNameController, maxLength: 30),
        const SizedBox(height: 12),
        _field(S.current.bio, model.bioController,
            lines: 3, maxLength: 1000, hint: 'What makes you, you?'),
        const SizedBox(height: 12),
        _field(S.current.about, model.aboutController,
            lines: 4,
            maxLength: 2000,
            hint: 'A story, a passion, a good conversation starter.'),
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cake_outlined),
            title: Text(S.current.dateOfBirth),
            subtitle: Text(KetuaCopy.label(
                '${model.selectedDob.day}/${model.selectedDob.month}/${model.selectedDob.year}')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => model.onDateOfBirthTap(context)),
        _label('Gender'),
        _choices<GenderType>(CreateProfileScreenViewModel.profileGenders,
            [model.selectedGender], (g) => g.title, model.onGenderTap)
      ]),
      _section('Your location', Icons.near_me_outlined, [
        Text(
            KetuaCopy.label(
                'Your city is public. Exact coordinates stay private; nearby distances are approximate.'),
            style: const TextStyle(
                color: ColorRes.textSecondaryDark, height: 1.4)),
        const SizedBox(height: 12),
        Obx(() => Column(children: [
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.current.country),
                  subtitle: Text(countries.selectedCountry.value?.countryName ??
                      'Select country'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pick(
                      context,
                      S.current.country,
                      countries.allCountries,
                      (e) => e.countryName,
                      (e) => countries.selectCountry(country: e))),
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                      countries.selectedCountry.value?.countryName == 'Uganda'
                          ? 'District'
                          : 'District / region'),
                  subtitle: Text(
                      countries.selectedState.value?.name ?? 'Select region'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: countries.selectedCountry.value == null
                      ? null
                      : () => _pick(
                          context,
                          countries.selectedCountry.value?.countryName ==
                                  'Uganda'
                              ? 'District'
                              : 'District / region',
                          countries.selectedStatesFromCountry,
                          (e) => e.name,
                          (e) => countries.selectState(state: e))),
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.current.city),
                  subtitle:
                      Text(countries.selectedCity.value?.name ?? 'Select city'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: countries.selectedState.value == null
                      ? null
                      : () => _pick(
                          context,
                          S.current.city,
                          countries.selectedCitiesFromState,
                          (e) => e.name,
                          (e) => countries.selectCity(city: e)))
            ])),
        SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
                onPressed: model.isSaving ? null : model.refreshLocation,
                icon: const Icon(Icons.my_location_rounded),
                label: Text(KetuaCopy.label('Refresh device location'))))
      ]),
      _section('Your vibe', Icons.auto_awesome_outlined, [
        _label(S.current.interest),
        _choices<Interests>(model.interestList, model.selectedInterests,
            (e) => e.title ?? '', model.onSelectInterestTap),
        _label(S.current.relationshipGoals),
        _choices<RelationshipGoals>(
            model.relationshipGoals,
            [
              if (model.selectedRelationShipGoal != null)
                model.selectedRelationShipGoal!
            ],
            (e) => e.title ?? '',
            model.onRelationshipGoalTap),
        _label(S.current.languages),
        _choices<Language>(model.languages, model.selectedLanguages,
            (e) => e.title ?? '', model.onLanguagesTap),
        _label('${S.current.religion} · optional'),
        _choices<Religions>(
            model.religions,
            [if (model.selectedReligion != null) model.selectedReligion!],
            (e) => e.title ?? '',
            model.onReligionTap)
      ]),
      _section('Social links', Icons.link_rounded, [
        _field('Instagram', model.instagramController),
        const SizedBox(height: 12),
        _field('Facebook', model.facebookController),
        const SizedBox(height: 12),
        _field('YouTube', model.youtubeController)
      ]),
    ]);
  }
}
