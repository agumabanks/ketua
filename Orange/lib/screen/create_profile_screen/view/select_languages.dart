import 'package:flutter/material.dart';
import 'package:ketua_ui/common/button/custom_text_button.dart';
import 'package:ketua_ui/common/login_setup_view.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/screen/create_profile_screen/create_profile_screen_view_model.dart';
import 'package:ketua_ui/screen/create_profile_screen/widget/border_text_card.dart';
import 'package:ketua_ui/screen/create_profile_screen/widget/error_text_widget.dart';
import 'package:stacked/stacked.dart';

class SelectLanguages extends StatelessWidget {
  final UserData? userData;
  final CreateProfileScreenViewModel model;

  const SelectLanguages({super.key, this.userData, required this.model});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<CreateProfileScreenViewModel>.reactive(
      viewModelBuilder: () => model,
      disposeViewModel: false,
      builder: (context, viewModel, child) => LoginSetupView(
        title: S.of(context).selectLanguages,
        description: 'Choose the languages you speak.',
        child: Column(
          children: [
            Expanded(
                child: viewModel.languages.isEmpty
                    ? ErrorTextWidget(S
                        .of(context)
                        .pleaseAddLanguagesInTheAdminPanelToContinue)
                    : ListView.builder(
                        itemCount: viewModel.languages.length,
                        itemBuilder: (context, index) {
                          bool isSelected = viewModel.selectedLanguages.any(
                              (element) =>
                                  element.id == viewModel.languages[index].id);
                          return BorderTextCard(
                            text: viewModel.languages[index].title ?? '',
                            onTap: () => viewModel
                                .onSelectLanguages(viewModel.languages[index]),
                            isSelected: isSelected,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            isCheckBtnVisible: true,
                            margin: const EdgeInsets.only(bottom: 5),
                          );
                        })),
            CustomTextButton(
              onTap: () =>
                  viewModel.onContinueTap(CreateProfileContinueTap.language),
            )
          ],
        ),
      ),
    );
  }
}
