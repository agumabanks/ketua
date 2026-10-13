import 'package:ketua_ui/screen/webview_screen/webview_screen.dart';
import 'package:ketua_ui/utils/urls.dart';
import 'dart:io';
import 'phone_sign_in_screen.dart';
import 'package:ketua_ui/common/ketua_wordmark.dart';

import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/screen/auth_screen/auth_screen_view_model.dart';
import 'package:ketua_ui/utils/asset_res.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/font_res.dart';
import 'package:stacked/stacked.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AuthScreenViewModel>.reactive(
      onViewModelReady: (viewModel) {
        viewModel.init(0);
      },
      viewModelBuilder: () => AuthScreenViewModel(),
      builder: (context, viewModel, child) {
        return Scaffold(
          body: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                foregroundDecoration: BoxDecoration(
                    color: ColorRes.themeColor.withValues(alpha: 0.15)),
                child: Image.asset('assets/images/ketua_auth_2.jpg',
                    height: double.infinity,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    cacheWidth: 1080),
              ),
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Column(children: [
                          KetuaWordmark(size: 42),
                          SizedBox(height: 8),
                          Text('Meet. Vibe. Connect.',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16))
                        ])),
                    Container(
                      padding: const EdgeInsets.only(
                          left: 15, right: 15, bottom: 60, top: 25),
                      decoration: const ShapeDecoration(
                          shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius.vertical(
                                top: SmoothRadius(
                                    cornerRadius: 40, cornerSmoothing: 1)),
                          ),
                          color: ColorRes.surfaceDark),
                      child: Column(
                        spacing: 10,
                        children: [
                          SocialLoginCard(
                              image: AssetRes.icEmail,
                              icon: Icons.phone_rounded,
                              iconColor: ColorRes.white,
                              text: 'Continue With Phone',
                              onTap: () =>
                                  Get.to(() => const PhoneSignInScreen())),
                          SocialLoginCard(
                              image: AssetRes.googleLogo,
                              text: S.current.continueWithGoogle,
                              onTap: viewModel.onGoogleTap),
                          if (const bool.fromEnvironment('KETUA_EMAIL_AUTH'))
                            SocialLoginCard(
                                image: AssetRes.icEmail,
                                iconColor: ColorRes.white,
                                text: S.of(context).continueWithEmail,
                                onTap: () => viewModel.onLoginTap(1)),
                          if (Platform.isIOS &&
                              const bool.fromEnvironment('KETUA_APPLE_AUTH'))
                            SocialLoginCard(
                              image: AssetRes.appleLogo,
                              text: S.current.continueWithApple,
                              bgColor: ColorRes.black,
                              iconColor: ColorRes.white,
                              textColor: ColorRes.white,
                              onTap: viewModel.onAppleTap,
                            ),
                          const SizedBox(height: 15),
                          Wrap(alignment: WrapAlignment.center, children: [
                            TextButton(
                                onPressed: () => Get.to(() => WebViewScreen(
                                    appBarTitle: 'Terms of use',
                                    url: Urls.aTermsOfUse)),
                                child: const Text('Terms')),
                            TextButton(
                                onPressed: () => Get.to(() => WebViewScreen(
                                    appBarTitle: 'Privacy policy',
                                    url: Urls.aPrivacyPolicy)),
                                child: const Text('Privacy'))
                          ]),
                          const Text(
                              'By continuing, you agree to KETUA’s Terms and acknowledge our Privacy Policy.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: ColorRes.textSecondaryDark,
                                  fontSize: 12,
                                  height: 1.5)),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class SocialLoginCard extends StatelessWidget {
  final IconData? icon;
  final String image;
  final String text;
  final Color? bgColor;
  final Color? textColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const SocialLoginCard(
      {super.key,
      required this.image,
      this.icon,
      required this.text,
      this.bgColor,
      this.textColor,
      this.iconColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 30),
        decoration: ShapeDecoration(
            color: bgColor ?? ColorRes.surfaceDark2,
            shape: SmoothRectangleBorder(
              borderRadius:
                  SmoothBorderRadius(cornerRadius: 15, cornerSmoothing: 1),
              side: BorderSide(color: bgColor ?? ColorRes.borderDark),
            ),
            shadows: [
              BoxShadow(
                  color: ColorRes.black.withValues(alpha: 0.06),
                  offset: const Offset(0, 4),
                  blurRadius: 10)
            ]),
        child: Row(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon == null
                ? Image.asset(image, height: 20, width: 20, color: iconColor)
                : Icon(icon, size: 20, color: iconColor),
            Text(
              text,
              style: TextStyle(
                  color: textColor ?? ColorRes.white,
                  fontFamily: FontRes.semiBold,
                  fontSize: 17),
            )
          ],
        ),
      ),
    );
  }
}
