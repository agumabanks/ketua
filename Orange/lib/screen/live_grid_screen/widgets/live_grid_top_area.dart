import 'package:flutter/material.dart';
import 'package:ketua_ui/common/ketua_wordmark.dart';
import 'package:ketua_ui/common/button/round_icon_button.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/utils/asset_res.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/font_res.dart';

class LiveGridTopArea extends StatelessWidget {
  final VoidCallback onBackBtnTap;
  final VoidCallback onGoLiveTap;
  final UserData? userData;

  const LiveGridTopArea(
      {super.key,
      required this.onBackBtnTap,
      required this.onGoLiveTap,
      this.userData});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 19),
        child: Row(
          children: [
            RoundIconButton(onTap: onBackBtnTap),
            const SizedBox(width: 13),
            const KetuaWordmark(size: 26),
            Text(
              " ${S.current.live}",
              style: const TextStyle(
                fontSize: 20,
                color: ColorRes.textPrimaryDark,
              ),
            ),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: onGoLiveTap,
              child: Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ColorRes.lightKetua,
                      ColorRes.themeColor,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      AssetRes.sun,
                      height: 21,
                      width: 21,
                      color: ColorRes.white,
                    ),
                    const SizedBox(width: 7.62),
                    Text(
                      S.current.goLive,
                      style: const TextStyle(
                        color: ColorRes.white,
                        fontSize: 14,
                        fontFamily: FontRes.extraBold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
