import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/common/button/custom_text_button.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/utils/asset_res.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/font_res.dart';

class EmptyFindMatch extends StatelessWidget {
  final VoidCallback onTap;

  const EmptyFindMatch({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(AssetRes.emptyFindMatch, height: 200, width: 200),
          const SizedBox(height: 5),
          Text(
            S.of(context).noMatchesFound,
            style: const TextStyle(
                fontFamily: FontRes.bold,
                color: ColorRes.textPrimaryDark,
                fontSize: 25),
          ),
          const SizedBox(height: 5),
          Text(
            S
                .of(context)
                .tryExpandingYourAgeOrDistancePreferencesOrSwitchInterests,
            style: const TextStyle(
                fontFamily: FontRes.regular,
                color: ColorRes.textSecondaryDark,
                fontSize: 17),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          CustomTextButton(
              onTap: onTap,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              title: S.of(context).makeYourPreferenceWider),
          TextButton(onPressed: () => Get.back(), child: const Text('Back')),
        ],
      ),
    );
  }
}
