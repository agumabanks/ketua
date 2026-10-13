import 'package:ketua_ui/utils/font_res.dart';
import 'package:ketua_ui/screen/subscription_sheet/plans_view.dart';
import 'package:ketua_ui/common/ketua_copy.dart';
import 'package:ketua_ui/screen/profile_screen/profile_progress_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/screen/profile_screen/earn_screen.dart';
import 'package:ketua_ui/screen/profile_screen/profile_screen_view_model.dart';
import 'package:ketua_ui/screen/profile_screen/widget/profile_images_area.dart';
import 'package:stacked/stacked.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ProfileScreenViewModel>.reactive(
      onViewModelReady: (model) {
        model.init();
      },
      viewModelBuilder: () => ProfileScreenViewModel(),
      builder: (context, model, child) {
        return Column(children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(
                    child: Text(KetuaCopy.text(context, 'Profile'),
                        style: const TextStyle(
                            fontSize: 28,
                            fontFamily: FontRes.bold,
                            fontWeight: FontWeight.w800))),
                FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF282030),
                        foregroundColor: const Color(0xFFE6C8FF),
                        textStyle: const TextStyle(fontFamily: FontRes.bold)),
                    onPressed: () => Get.to(() => const EarnScreen()),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(KetuaCopy.text(context, 'Earn')))
              ])),
          ProfileProgressCard(onEdit: model.onEditProfileTap),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Material(
                  color: const Color(0xFF252015),
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => Get.to(() => const PlansView()),
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            const Icon(Icons.workspace_premium_rounded,
                                color: Color(0xFFE7BC43), size: 28),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(
                                      KetuaCopy.text(
                                          context, 'Plans & upgrades'),
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontFamily: FontRes.bold,
                                          fontWeight: FontWeight.w800)),
                                  Text(
                                      KetuaCopy.text(context,
                                          'Explore Free, Gold and Pro'),
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12))
                                ])),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Color(0xFFE7BC43))
                          ]))))),
          Expanded(
              child: ProfileImageArea(
            userData: model.userData,
            pageController: model.pageController,
            onEditProfileTap: model.onEditProfileTap,
            onMoreBtnTap: model.onMoreBtnTap,
            onImageTap: model.onImageTap,
            onInstagramTap: () =>
                model.onSocialBtnTap(model.userData?.instagram),
            onFacebookTap: () => model.onSocialBtnTap(model.userData?.facebook),
            onYoutubeTap: () => model.onSocialBtnTap(model.userData?.youtube),
            isLoading: model.isLoading,
            isVerified: model.userData?.isVerified == 2 ? true : false,
            isSocialBtnVisible: model.isSocialBtnVisible,
          ))
        ]);
      },
    );
  }
}
