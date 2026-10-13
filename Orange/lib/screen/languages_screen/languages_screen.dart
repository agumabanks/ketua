import 'package:flutter/material.dart';
import 'package:ketua_ui/common/top_bar_area.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/screen/languages_screen/languages_screen_view_model.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/font_res.dart';
import 'package:stacked/stacked.dart';

class LanguagesScreen extends StatelessWidget {
  const LanguagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<LanguagesScreenViewModel>.reactive(
      onViewModelReady: (viewModel) => viewModel.init(),
      viewModelBuilder: () => LanguagesScreenViewModel(),
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: ColorRes.bgDark,
          body: Column(
            children: [
              TopBarArea(title2: S.current.languages.toUpperCase()),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      return RadioGroup(
                        onChanged: viewModel.onLanguageChange,
                        groupValue: viewModel.value,
                        child: RadioListTile(
                          value: index,
                          activeColor: ColorRes.themeColor,
                          splashRadius: 0,
                          hoverColor: Colors.transparent,
                          dense: true,
                          title: Text(viewModel.languages[index],
                              style: const TextStyle(
                                  color: ColorRes.textPrimaryDark, fontFamily: FontRes.semiBold, fontSize: 15)),
                          subtitle: Text(
                            viewModel.subLanguage[index],
                            style: const TextStyle(
                              color: ColorRes.textSecondaryDark,
                              fontFamily: FontRes.regular,
                            ),
                          ),
                        ),
                      );
                    },
                    itemCount: viewModel.languages.length,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
