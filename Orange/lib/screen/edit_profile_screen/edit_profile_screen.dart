import 'package:ketua_ui/utils/font_res.dart';
import 'package:ketua_ui/common/ketua_copy.dart';
import 'package:flutter/material.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/screen/edit_profile_screen/edit_profile_screen_view_model.dart';
import 'package:ketua_ui/screen/edit_profile_screen/widgets/image_list_area.dart';
import 'package:ketua_ui/screen/edit_profile_screen/widgets/text_fields_area.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:stacked/stacked.dart';

class EditProfileScreen extends StatelessWidget {
  final UserData? userData;
  const EditProfileScreen({super.key, required this.userData});
  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<EditProfileScreenViewModel>.reactive(
          onViewModelReady: (model) => model.init(),
          viewModelBuilder: () => EditProfileScreenViewModel(userData),
          builder: (context, model, child) => Scaffold(
              backgroundColor: ColorRes.bgDark,
              appBar: AppBar(
                  title: Text(KetuaCopy.label('Edit profile'),
                      style: const TextStyle(
                          fontFamily: FontRes.bold,
                          fontWeight: FontWeight.w800)),
                  actions: [
                    Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: TextButton(
                            onPressed: model.isSaving || model.isPicking
                                ? null
                                : model.onSaveTap,
                            child: Text(
                                KetuaCopy.label(
                                    model.isSaving ? 'Saving…' : 'Save'),
                                style: const TextStyle(
                                    fontFamily: FontRes.bold,
                                    fontWeight: FontWeight.w800))))
                  ]),
              body: SafeArea(
                  child: ListView(
                      key: const PageStorageKey('edit-profile'),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                    Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(colors: [
                              Color(0xFF33213E),
                              Color(0xFF1E2334)
                            ])),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(KetuaCopy.label('Show your best self.'),
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontFamily: FontRes.bold,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15)),
                              const SizedBox(height: 10),
                              Text(
                                  KetuaCopy.label(
                                      'Your photos. Your story. Your kind of connection.'),
                                  style: const TextStyle(
                                      color: ColorRes.textSecondaryDark,
                                      height: 1.5))
                            ])),
                    const SizedBox(height: 20),
                    ImageListArea(model: model),
                    const SizedBox(height: 20),
                    TextFieldsArea(model: model),
                    const SizedBox(height: 20),
                    SizedBox(
                        height: 54,
                        child: FilledButton(
                            onPressed: model.isSaving || model.isPicking
                                ? null
                                : model.onSaveTap,
                            child: model.isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: const CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Text(KetuaCopy.label('Save changes'),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontFamily: FontRes.bold,
                                        fontWeight: FontWeight.w800)))),
                  ]))));
}
