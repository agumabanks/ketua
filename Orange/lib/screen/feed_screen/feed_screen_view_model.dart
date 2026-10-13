import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/common/confirmation_dialog.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/model/setting_model.dart';
import 'package:ketua_ui/model/social/feed.dart';
import 'package:ketua_ui/model/social/post/add_comment.dart';
import 'package:ketua_ui/model/social/story/fetch_stories.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/screen/comment_sheet/comment_sheet.dart';
import 'package:ketua_ui/screen/create_post_screen/create_post_screen.dart';
import 'package:ketua_ui/screen/story_view_screen/story_view_screen.dart';
import 'package:ketua_ui/screen/user_report_screen/report_sheet.dart';

import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/service/share_manager.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/urls.dart';
import 'package:stacked/stacked.dart';

enum MoreBtnValue { report, delete, share }

class FeedScreenViewModel extends BaseViewModel {
  List<Post> postList = [];
  List<UserData> headerStories = [];
  bool isLoading = true;
  bool _closed=false;
  final int _owner=SessionManager.instance.getUserID();
  ScrollController scrollController = ScrollController();
  MoreBtnValue moreBtnValue = MoreBtnValue.share;
  UserData? myUserData;

  @override void dispose(){_closed=true;scrollController.dispose();super.dispose();}

  // init Camera description

  Appdata? settingAppData;

  void init() {
    prefData();
    _restoreFeed();
    fetchScrollData();
  }

  Future<void> _restoreFeed() async {
    final saved=await SessionManager.instance.readSnapshot('community');
    if(_closed || _owner!=SessionManager.instance.getUserID())return;
    if(saved!=null) { final feed=Feed.fromJson(saved); postList=feed.data?.posts??[];headerStories=feed.data?.usersStories??[];isLoading=false;notifyListeners(); }
    fetchFeedData();
  }
  void fetchFeedData({bool more=false}) {
    if(_closed)return;
    isLoading = postList.isEmpty && headerStories.isEmpty;
    ApiProvider().callPost(
        completion: (response) {
          if(_closed || _owner!=SessionManager.instance.getUserID())return;
          Feed feed = Feed.fromJson(response);
          if(feed.status!=true && feed.message!='Posts not Available') {isLoading=false;notifyListeners();return;}
          if (!more && feed.status == true) SessionManager.instance.writeSnapshot('community',feed.toJson());
          if (!more) {
            postList = feed.data?.posts ?? [];
          } else {
            final known=postList.map((p)=>p.id).toSet();
            postList.addAll((feed.data?.posts??[]).where((p)=>!known.contains(p.id)));
          }
          headerStories = feed.data?.usersStories ?? [];
          headerStories.sort((a, b) {
            if (a.isAllStoryShown()) {
              return 1;
            }
            return -1;
          });
          isLoading = false;
          notifyListeners();
        },
        url: Urls.aFetchHomePageData,
        param: {
          Urls.myUserId: SessionManager.instance.getUserID().toString(),
        });
  }

  void fetchStories({required UserData? userData}) {
    ApiProvider().callPost(
        completion: (response) {
          FetchStories fetchStories = FetchStories.fromJson(response);
          headerStories = fetchStories.data ?? [];
          headerStories.sort((a, b) {
            if (a.isAllStoryShown()) {
              return 1;
            }
            return -1;
          });
          // Update Other PostUser
          for (var element in headerStories) {
            for (var postUser in postList) {
              if (postUser.userId == element.id) {
                postUser.user = element;
              }
            }
          }
          notifyListeners();
        },
        url: Urls.aFetchStories,
        param: {Urls.myUserId: SessionManager.instance.getUserID().toString()});
  }

  void getProfile() {
    ApiProvider()
        .getProfile(userID: SessionManager.instance.getUserID())
        .then((value) {
      myUserData = value.data;
      // Update My PostUser
      for (var element in postList) {
        Post p = element;
        if (myUserData?.id == p.user?.id) {
          element.user = myUserData;
        }
      }
      notifyListeners();
    });
  }

  void fetchScrollData() {
    scrollController.addListener(() {
      if (scrollController.offset ==
          scrollController.position.maxScrollExtent) {
        if (!isLoading) {
          fetchFeedData(more:true);
        }
      }
    });
  }

  void onCommentBtnClick(Post? post) {
    Get.bottomSheet(CommentSheet(post: post), isScrollControlled: true)
        .then((value) {
      notifyListeners();
    });
  }

  void onCreatePost() {
    Get.bottomSheet<Post>(
      const CreatePostScreen(),
      isScrollControlled: true,
      backgroundColor: ColorRes.white,
      barrierColor: ColorRes.white,
      enableDrag: false,
    ).then((value) {
      if (value != null) {
        postList.insert(0, value);
        notifyListeners();
      }
    });
  }

  void onMoreBtnClick(
      MoreBtnValue value, Post post, Function(int id)? onDeleteItem) {
    if (MoreBtnValue.share == value) {
      sharePost(post);
    } else if (MoreBtnValue.report == value) {
      Get.bottomSheet(
          ReportSheet(
              reportId: post.id,
              profileImage: post.user?.profileImage,
              age: post.user?.age,
              fullName: post.user?.fullname,
              address: post.user?.address,
              userData: post.user,
              reportType: 2),
          isScrollControlled: true);
    } else if (MoreBtnValue.delete == value) {
      Get.dialog(
        ConfirmationDialog(
          onTap: () {
            onDeleteItem?.call(post.id ?? -1);
            Get.back();
            postList.removeWhere((element) => element.id == post.id);
            notifyListeners();
            ApiProvider().callPost(
              completion: (response) {},
              url: Urls.aDeleteMyPost,
              param: {
                Urls.userId: SessionManager.instance.getUserID().toString(),
                Urls.aPostId: post.id
              },
            );
          },
          description: S.current.areYouSureYouWantToDeleteThePost,
          heading: S.current.deletePost,
          dialogSize: 2,
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  void sharePost(Post post) async {
    ShareManager.shared.shareTheContent(key: ShareKeys.post, value: post.id ?? -1);
  }

  void prefData() async {
    myUserData = SessionManager.instance.getUser();
    settingAppData = SessionManager.instance.getSettings()?.appdata;
    notifyListeners();

    getProfile();
  }

  onProfilePictureClick({required List<UserData> userStories,
    Function(UserData? data)? onCallback,
      required int userIndex}) {
    Get.bottomSheet<UserData?>(
      StoryViewScreen(stories: userStories, userIndex: userIndex),
      isScrollControlled: true,
      barrierColor: ColorRes.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    ).then((value) {
      getProfile();
      if (value != null) {
        for (var element in postList) {
          if (element.userId == value.id) {
            element.user = value;
          }
        }
        if (myUserData?.id == value.id) {
          myUserData = value;
        }
        int index =
            headerStories.indexWhere((element) => element.id == value.id);

        if (index != -1) {
          headerStories[index] = value;
          log('${headerStories[index].toJson()}');
        }

        notifyListeners();
        onCallback?.call(value);
      }
    });
  }
}
