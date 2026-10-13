import 'package:ketua_ui/screen/commerce/sponsored_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/common/common_ui.dart';
import 'package:ketua_ui/common/custom_image.dart';
import 'package:ketua_ui/common/full_image_view_shimmer.dart';
import 'package:ketua_ui/common/profile_detail_card.dart';
import 'package:ketua_ui/common/social_icon.dart';
import 'package:ketua_ui/common/top_story_line.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/screen/explore_screen/explore_screen_view_model.dart';
import 'package:ketua_ui/screen/explore_screen/widgets/suggest_photo_tap_view.dart';
import 'package:ketua_ui/screen/explore_screen/widgets/swipe_right_view.dart';
import 'package:ketua_ui/screen/subscription_sheet/widget/subscribe_card.dart';
import 'package:ketua_ui/service/extention/string_extention.dart';
import 'package:ketua_ui/utils/asset_res.dart';
import 'package:ketua_ui/utils/color_res.dart';

class FullImageView extends StatelessWidget {
  final ExploreScreenViewModel model;

  const FullImageView({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    if (model.isLoading && model.combinedList.isEmpty) {
      return const FullImageViewShimmer();
    } else {
      return Expanded(
        child: (model.combinedList.isEmpty || model.deckExhausted)
            ? CommonUI.noData()
            : CardSwiper(
                key: ValueKey(model.deckRevision),
                controller: model.cardController,
                initialIndex: model.currentCombinedIndex
                    .clamp(0, model.combinedList.length - 1),
                isLoop: false,
                onEnd: model.onDeckEnd,
                duration: const Duration(milliseconds: 180),
                cardsCount: model.combinedList.length,
                onUndo: model.onUndo,
                onSwipe: (prevIndex, currentIndex, direction) {
                  // reset page to 0 for new card
                  model.resetPageAt(currentIndex ?? 0);
                  return model.onSwipe(prevIndex, currentIndex, direction);
                },
                isDisabled: model.isSwipeDisable,
                numberOfCardsDisplayed: model.combinedList.length > 1 ? 2 : 1,
                padding: const EdgeInsets.symmetric(horizontal: 15)
                    .add(const EdgeInsets.only(top: 10)),
                allowedSwipeDirection: const AllowedSwipeDirection.only(
                    left: true, right: true, up: true),
                cardBuilder: (context, currentProfileIndex, percentThresholdX,
                    percentThresholdY) {
                  final userData = model.combinedList[currentProfileIndex];

                  if (userData.id == -2)
                    return SponsoredCard(ad: userData.sponsoredAd!);

                  if (userData.id == -1) {
                    return SubscribeCard(
                        onNoThanksTap: () => model.onLikeDislikeTap(false));
                  }

                  // ✅ use persistent PageController
                  final PageController pageController =
                      model.getPageController(currentProfileIndex);

                  return RepaintBoundary(
                      child: Stack(
                    children: [
                      ImagePageView(
                          userData: userData,
                          pageController: pageController,
                          model: model),
                      Column(
                        children: [
                          const SizedBox(height: 14),
                          TopStoryLine(
                            pageController: pageController,
                            imageLength: userData.images?.length ?? 0,
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                            child: Row(
                              children: [
                                SocialIcon(
                                  icon: AssetRes.instagramLogo,
                                  onSocialIconTap: () =>
                                      model.onSocialBtnTap(2),
                                  isVisible: model
                                      .isSocialBtnVisible(userData.instagram),
                                ),
                                SocialIcon(
                                  icon: AssetRes.facebookLogo,
                                  onSocialIconTap: () =>
                                      model.onSocialBtnTap(1),
                                  isVisible: model
                                      .isSocialBtnVisible(userData.facebook),
                                ),
                                SocialIcon(
                                  icon: AssetRes.youtubeLogo,
                                  onSocialIconTap: () =>
                                      model.onSocialBtnTap(0),
                                  isVisible: model
                                      .isSocialBtnVisible(userData.youtube),
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),
                          ProfileDetailCard(
                              userData: userData, onImageTap: model.onImageTap),
                        ],
                      ),
                      if (model.likeStatus != 0)
                        Positioned(
                          top: 50,
                          left: model.isLikeDisLikeStatus ? 50 : null,
                          right: model.isLikeDisLikeStatus ? null : 50,
                          child: RotationTransition(
                            turns: AlwaysStoppedAnimation(
                                !model.isLikeDisLikeStatus ? -15.9 : 15.9),
                            child: Image.asset(
                                model.isLikeDisLikeStatus == false
                                    ? AssetRes.icNope
                                    : AssetRes.icLike,
                                width: 150,
                                height: 150),
                          ),
                        ),
                      SwipeRightView(model: model, index: currentProfileIndex),
                      SuggestPhotoTapView(
                          model: model, index: currentProfileIndex),
                    ],
                  ));
                },
              ),
      );
    }
  }
}

class BorderLineCustom extends StatelessWidget {
  const BorderLineCustom(
      {super.key, this.height = 10, this.color = Colors.black});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 1.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (5 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.vertical,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}

class ImagePageView extends StatefulWidget {
  final UserData userData;
  final PageController pageController;
  final ExploreScreenViewModel model;

  const ImagePageView(
      {super.key,
      required this.userData,
      required this.pageController,
      required this.model});

  @override
  State<ImagePageView> createState() => _ImagePageViewState();
}

class _ImagePageViewState extends State<ImagePageView> {
  @override
  Widget build(BuildContext context) {
    return (widget.userData.images ?? []).isEmpty
        ? CommonUI.profileImagePlaceHolder(
            name: widget.userData.fullname,
            heightWidth: MediaQuery.of(context).size.height,
            borderRadius: 20,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: PageView.builder(
              controller: widget.pageController,
              itemCount: (widget.userData.images ?? []).length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, currentImageIndex) {
                Images image =
                    (widget.userData.images ?? [])[currentImageIndex];
                return Stack(
                  children: [
                    CustomImage(
                        image: image.image?.addBaseURL(),
                        cacheWidth: (MediaQuery.of(context).size.width *
                                MediaQuery.of(context).devicePixelRatio)
                            .round()
                            .clamp(1, 1600),
                        fullname: widget.userData.fullname,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        radius: 0),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => widget.model.onImageLeftTap(
                                widget.pageController, currentImageIndex),
                            child: Container(
                                height: Get.height - 256,
                                color: ColorRes.transparent),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => widget.model.onImageRightTap(
                                widget.pageController,
                                currentImageIndex,
                                (widget.userData.images ?? []).length),
                            child: Container(
                                height: Get.height - 256,
                                color: ColorRes.transparent),
                          ),
                        ),
                      ],
                    )
                  ],
                );
              },
            ),
          );
  }
}
