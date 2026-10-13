import 'updates_empty.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/common/common_fun.dart';
import 'package:ketua_ui/common/common_ui.dart';
import 'package:ketua_ui/common/custom_image.dart';
import 'package:ketua_ui/common/fullname_with_age.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/model/notification/user_notification_model.dart';
import 'package:ketua_ui/model/social/post/add_post.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/screen/single_post_screen/single_post_screen.dart';
import 'package:ketua_ui/screen/user_detail_screen/user_detail_screen.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/font_res.dart';
import 'package:ketua_ui/utils/urls.dart';

class PersonalNotificationPage extends StatelessWidget {
  final List<UserNotificationData> userNotification;
  final ScrollController controller;
  final Function(UserData? data) onUserTap;

  const PersonalNotificationPage(
      {super.key,
      required this.userNotification,
      required this.controller,
      required this.onUserTap});

  @override
  Widget build(BuildContext context) {
    return userNotification.isEmpty
        ? const UpdatesEmpty()
        : ListView.builder(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 24 + MediaQuery.paddingOf(context).bottom),
            itemCount: userNotification.length,
            itemBuilder: (context, index) {
              UserNotificationData notification = userNotification[index];
              UserData? user = notification.user;
              return InkWell(
                onTap: () {
                  if (user != null) onUserTap(user);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    spacing: 12,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          if (user != null)
                            Get.to(() => UserDetailScreen(userData: user));
                        },
                        child: CustomImage(
                            image: user?.profileImage,
                            height: 40,
                            width: 40,
                            radius: 30,
                            fullname: user?.fullname),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            switch (notification.type) {
                              case 1:
                                navigateUser(notification);
                                break;
                              case 2:
                                navigatePost(notification);
                                break;
                              case 3:
                                navigatePost(notification);
                                break;
                              case 5:
                              case 6:
                              case 4:
                                navigateUser(notification);
                                break;
                              default:
                                break;
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: FullnameWithAge(
                                          userData: user,
                                          fontColor: Colors.white,
                                          fontSize: 15,
                                          fontFamily: FontRes.bold)),
                                  Text(
                                    CommonFun.timeAgo(
                                      notification.createdAt ?? DateTime.now(),
                                    ),
                                    style: const TextStyle(
                                        fontSize: 11, color: ColorRes.grey2),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(getNotificationType(userNotification[index]),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                      height: 1.4),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis)
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
  }

  String getNotificationType(UserNotificationData? notificationData) {
    if (notificationData?.message?.trim().isNotEmpty == true)
      return notificationData!.message!;
    if (notificationData?.type == 5) return 'You received a gift';
    if (notificationData?.type == 6) return 'You have a new match';
    if (notificationData?.type == 7) return 'Your boost has been updated';
    return notificationData?.type == 1
        ? '${notificationData?.user?.fullname} ${S.current.hasFollowedYourProfile}'
        : notificationData?.type == 2
            ? '${notificationData?.user?.fullname} ${S.current.hasCommentedOnYourPost}'
            : notificationData?.type == 3
                ? '${notificationData?.user?.fullname} ${S.current.hasLikedYourPost}'
                : notificationData?.type == 4
                    ? '${notificationData?.user?.fullname} ${S.current.hasLikedYourProfile}'
                    : 'KETUA update';
  }

  void navigateUser(UserNotificationData data) {
    if (data.user != null) Get.to(() => UserDetailScreen(userData: data.user));
  }

  void navigatePost(UserNotificationData notification) {
    CommonUI.lottieLoader();
    ApiProvider().callPost(
        completion: (response) {
          Get.back();
          AddPost post = AddPost.fromJson(response);
          if (post.status == true) {
            Get.to(() => SinglePostScreen(post: post.data));
          } else {
            CommonUI.snackBar(message: post.message ?? '');
          }
        },
        url: Urls.aFetchPostByPostId,
        param: {
          Urls.userId: SessionManager.instance.getUserID().toString(),
          Urls.aPostId: notification.itemId
        });
  }
}
