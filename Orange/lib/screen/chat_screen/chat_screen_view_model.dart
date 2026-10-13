import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/common/common_fun.dart';
import 'package:ketua_ui/common/common_ui.dart';
import 'package:ketua_ui/common/confirmation_dialog.dart';
import 'package:ketua_ui/common/video_upload_dialog.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/model/chat_and_live_stream/chat.dart';
import 'package:ketua_ui/model/setting_model.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/model/wallet/minus_coin_from_wallet.dart';
import 'package:ketua_ui/screen/bottom_diamond_shop/bottom_diamond_shop.dart';
import 'package:ketua_ui/screen/chat_screen/widgets/image_video_send_sheet.dart';
import 'package:ketua_ui/screen/chat_screen/widgets/image_view_page.dart';
import 'package:ketua_ui/screen/chat_screen/widgets/item_selection_dialog_android.dart';
import 'package:ketua_ui/screen/explore_screen/widgets/reverse_swipe_dialog.dart';
import 'package:ketua_ui/screen/user_detail_screen/user_detail_screen.dart';
import 'package:ketua_ui/screen/user_report_screen/report_sheet.dart';
import 'package:ketua_ui/screen/video_preview_screen/video_preview_screen.dart';
import 'package:ketua_ui/screen/video_preview_screen/video_preview_screen_view_model.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/service/subscription/subscription_manager.dart';
import 'package:ketua_ui/utils/app_res.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:stacked/stacked.dart';

/// F06 — Server-side chat view model. Uses REST API instead of Firestore for
/// message storage, conversation metadata, blocking, muting, and deletion.
class ChatScreenViewModel extends BaseViewModel {
  ImagePicker picker = ImagePicker();

  TextEditingController textMsgController = TextEditingController();
  ScrollController scrollController = ScrollController();

  File? chatImage;
  String selectedItem = S.current.image;
  String blockUnblock = S.current.block;
  List<ChatMessage> chatData = [];
  String deletedId = '';
  List<String> notDeletedIdentity = [];
  List<String> timeStamp = [];
  bool isLongPress = false;
  int walletCoin = 0;
  bool isAutoPayEnable = false;
  bool isBlock = false;
  bool isBlockOther = false;
  static String conversationID = '';
  int messagePrice = 0;

  Appdata? settingAppData;

  Conversation conversation;
  UserData? registrationUserData;
  UserData? receiverUserData;

  Map<String, List<ChatMessage>>? grouped;
  int startingNumber = 30;

  Timer? _pollTimer;

  ChatScreenViewModel(this.conversation);

  void init() {
    conversationID = conversation.conversationId ?? '';
    getPrefData();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => getChat());
  }

  Future<void> getPrefData() async {
    registrationUserData = SessionManager.instance.getUser();

    blockUnblock = conversation.block == true ? S.current.unBlock : S.current.block;
    isAutoPayEnable = SessionManager.instance.getBool(key: SessionKeys.isMessageDialog);
    isBlock = conversation.block == true;
    isBlockOther = conversation.blockFromOther == true;

    settingAppData = SessionManager.instance.getSettings()?.appdata;
    messagePrice = settingAppData?.messagePrice ?? 0;
    notifyListeners();

    getProfileAPi();
  }

  Future<void> getProfileAPi() async {
    ApiProvider().getProfile(userID: conversation.user?.userid).then((value) {
      receiverUserData = value.data;
      notifyListeners();
    });

    ApiProvider().getProfile(userID: registrationUserData?.id).then((value) async {
      registrationUserData = value.data;
      walletCoin = value.data?.wallet ?? 0;
      blockUnblock = value.data?.blockedUsers?.contains('${conversation.user?.userid}') == true
          ? S.current.unBlock
          : S.current.block;
      isBlock = value.data?.blockedUsers?.contains('${conversation.user?.userid}') == true;
      notifyListeners();
      SessionManager.instance.setUser(value.data);
    });
  }

  Future<void> minusCoinApi(Function onCompletion) async {
    CommonUI.lottieLoader();
    MinusCoinFromWallet minusCoinFromWallet =
        await ApiProvider().minusCoinFromWallet(settingAppData?.messagePrice);
    Get.back();
    if (minusCoinFromWallet.status == true) {
      onCompletion.call();
      int wallet = (minusCoinFromWallet.wallet ?? 0).toInt();
      registrationUserData?.wallet = wallet;
      updateDataLocalUser(registrationUserData);
    }
  }

  // ---- REST-based chat ----

  Future<void> getChat() async {
    if (conversationID.isEmpty) return;
    try {
      final res = await ApiProvider().chatMessages(conversationID, count: startingNumber);
      if (res['status'] == true) {
        final data = res['data'];
        final list = data is List ? data : [];
        chatData = list.map((e) => ChatMessage.fromJson(e)).toList();

        final now = DateTime.now();
        Map<String, List<ChatMessage>> customGrouped = {};
        for (var message in chatData) {
          if (message.time != null) {
            final time = DateTime.fromMillisecondsSinceEpoch(message.time!.toInt());
            final formattedDate = DateFormat(AppRes.dMY).format(time);
            String groupKey;
            if (formattedDate == DateFormat(AppRes.dMY).format(now)) {
              groupKey = S.current.today;
            } else if (formattedDate == DateFormat(AppRes.dMY).format(now.subtract(const Duration(days: 1)))) {
              groupKey = S.current.yesterday;
            } else {
              groupKey = formattedDate;
            }
            customGrouped.putIfAbsent(groupKey, () => []).add(message);
          }
        }
        grouped = customGrouped;
        startingNumber += 45;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching chat: $e");
    }
  }

  // Send a text or media message via REST
  Future<void> sendMessage({
    required String msgType,
    String? textMessage,
    String? image,
    String? video,
  }) async {
    final receiverId = conversation.user?.userid;
    if (receiverId == null) return;

    final res = await ApiProvider().chatSend(
      receiverId,
      textMessage,
      messageType: msgType,
    );

    if (res['status'] == true) {
      // Prepend the new message locally for instant feedback.
      final msgData = res['data'];
      if (msgData != null) {
        final msg = ChatMessage.fromJson(msgData);
        chatData.insert(0, msg);
        // Regroup
        final now = DateTime.now();
        Map<String, List<ChatMessage>> customGrouped = {};
        for (var message in chatData) {
          if (message.time != null) {
            final time = DateTime.fromMillisecondsSinceEpoch(message.time!.toInt());
            final formattedDate = DateFormat(AppRes.dMY).format(time);
            String groupKey;
            if (formattedDate == DateFormat(AppRes.dMY).format(now)) {
              groupKey = S.current.today;
            } else if (formattedDate == DateFormat(AppRes.dMY).format(now.subtract(const Duration(days: 1)))) {
              groupKey = S.current.yesterday;
            } else {
              groupKey = formattedDate;
            }
            customGrouped.putIfAbsent(groupKey, () => []).add(message);
          }
        }
        grouped = customGrouped;
        notifyListeners();
      }

      // Notify receiver
      if (receiverUserData?.isNotification == 1) {
        _sendPushNotification(textMessage ?? '');
      }
    } else {
      CommonUI.snackBarWidget(res['message']?.toString() ?? 'Failed to send');
    }
  }

  // Block/unblock via REST
  Future<void> blockUser() async {
    ApiProvider().updateBlockList(conversation.user?.userid);
    final res = await ApiProvider().chatBlock(conversationID, 'block');
    if (res['status'] == true) {
      blockUnblock = S.current.unBlock;
      isBlock = true;
      isBlockOther = true;
      notifyListeners();
    }
  }

  Future<void> unBlockUser() async {
    ApiProvider().updateBlockList(conversation.user?.userid);
    final res = await ApiProvider().chatBlock(conversationID, 'unblock');
    if (res['status'] == true) {
      blockUnblock = S.current.block;
      isBlock = false;
      isBlockOther = false;
      notifyListeners();
    }
  }

  // Soft-delete selected messages via REST
  Future<void> onDeleteBtnClick() async {
    for (int i = 0; i < timeStamp.length; i++) {
      final msg = chatData.firstWhereOrNull((m) => '${m.time?.round()}' == timeStamp[i]);
      if (msg?.id != null) {
        await ApiProvider().chatDeleteMessage(msg!.id! as int);
      }
    }
    timeStamp = [];
    Get.back();
    await getChat();
  }

  // ---- UI event handlers ----

  void onUserTap() {
    Get.to(() => UserDetailScreen(userId: conversation.user?.userid));
  }

  void onCancelBtnClick() {
    timeStamp = [];
    notifyListeners();
  }

  void chatDeleteDialog() {
    Get.dialog(ConfirmationDialog(
      onTap: onDeleteBtnClick,
      description: S.current.afterDeletingTheChatYouCanNotRestoreOurMessage,
      dialogSize: 1.6,
      padding: const EdgeInsets.symmetric(horizontal: 40),
    ));
  }

  void onLongPress(ChatMessage? data) {
    if (!timeStamp.contains('${data?.time?.round()}')) {
      timeStamp.add('${data?.time?.round()}');
    } else {
      timeStamp.remove('${data?.time?.round()}');
    }
    isLongPress = true;
    notifyListeners();
  }

  void unblockDialog() {
    Get.dialog(ConfirmationDialog(
      onTap: () { Get.back(); unBlockUser(); },
      description: S.current.areYouSureYouWantToUnblockThisUser,
      textButton: S.current.unBlock,
      heading: "${S.current.unBlock} ${conversation.user?.username} ?",
      dialogSize: 1.6,
    ));
  }

  Future<void> onMoreBtnTap(String value) async {
    if (value == S.current.block) blockUser();
    if (value == S.current.unBlock) unBlockUser();
    if (value == AppRes.report) {
      Get.bottomSheet(
        ReportSheet(
          reportId: conversation.user?.userid,
          userData: receiverUserData,
          fullName: conversation.user?.username,
          profileImage: conversation.user?.image,
          age: int.parse(conversation.user?.age ?? '0'),
          address: conversation.user?.city,
          reportType: 1,
        ),
        isScrollControlled: true,
      );
    }
  }

  // Send text
  void onSendBtnTap() async {
    if (textMsgController.text.trim().isEmpty) return;
    final textMessage = textMsgController.text.trim();
    textMsgController.clear();

    if (isBlockOther) { CommonUI.snackBarWidget(S.current.thisUserBlockYou); return; }

    // Free for fake/subscribed/zero-price
    if (registrationUserData?.isFake == 1 || isSubscribe.value || messagePrice <= 0) {
      await sendMessage(msgType: 'msg', textMessage: textMessage);
      return;
    }

    if ((registrationUserData?.wallet ?? 0) >= messagePrice) {
      if (isAutoPayEnable) {
        minusCoinApi(() async { await sendMessage(msgType: 'msg', textMessage: textMessage); });
      } else {
        getChatMsgDialog(
          onContinueTap: (isSelected) {
            isAutoPayEnable = isSelected;
            SessionManager.instance.setBool(key: SessionKeys.isMessageDialog, value: isSelected);
            minusCoinApi(() { Get.back(); sendMessage(msgType: 'msg', textMessage: textMessage); });
          },
          onCancelTap: () {},
        );
      }
    } else {
      emptyDialog();
    }
  }

  void onPlusButtonClick(int type) {
    if (registrationUserData?.isFake == 1 || isSubscribe.value) { openMediaPicker(type); return; }
    if (messagePrice == 0) { openMediaPicker(type); }
    else if (walletCoin >= messagePrice) { openMediaPicker(type); }
    else { emptyDialog(); }
  }

  void payAndOpenMediaPicker(int type) { minusCoinApi(() => openMediaPicker(type)); }

  void onAutoPaySelected(bool isSelected, int type, Function onCompletion) {
    isAutoPayEnable = isSelected;
    SessionManager.instance.setBool(key: SessionKeys.isMessageDialog, value: isSelected);
    minusCoinApi(() { Get.back(); onCompletion.call(); });
  }

  void openMediaPicker(int type) {
    if (isBlockOther) { CommonUI.snackBarWidget(S.current.thisUserBlockYou); return; }
    Get.bottomSheet(
      ItemSelectionDialogAndroid(
        onImageBtnClick: () { Get.back(); pickImage(type); },
        onVideoBtnClick: () { Get.back(); pickVideo(type); },
      ),
      backgroundColor: ColorRes.transparent,
      isScrollControlled: true,
    );
  }

  Future<void> pickImage(int type) async {
    selectedItem = S.current.image;
    final picked = await picker.pickImage(
      source: type == 0 ? ImageSource.gallery : ImageSource.camera,
      imageQuality: AppRes.quality, maxHeight: AppRes.maxHeight, maxWidth: AppRes.maxWidth,
    );
    if (picked == null || picked.path.isEmpty) return;
    final imageFile = File(picked.path);
    Get.bottomSheet(
      ImageVideoSendSheet(
        image: imageFile, selectedItem: selectedItem,
        onSendBtnClick: (msg, _) async {
          CommonUI.lottieLoader();
          isAutoPayEnable
              ? minusCoinApi(() async {
                  final response = await ApiProvider().getStoreFileGivePath(image: imageFile);
                  Get.back();
                  if (response.status == true) {
                    Get.back();
                    await sendMessage(msgType: 'image', textMessage: msg, image: response.path);
                  } else { CommonUI.snackBarWidget(response.message); }
                })
              : getChatMsgDialog(
                  onContinueTap: (isSelected) => onAutoPaySelected(isSelected, type, () async {
                    final response = await ApiProvider().getStoreFileGivePath(image: imageFile);
                    Get.back();
                    if (response.status == true) { Get.back(); await sendMessage(msgType: 'image', textMessage: msg, image: response.path); }
                    else { CommonUI.snackBarWidget(response.message); }
                  }),
                  onCancelTap: () { Get.back(); Get.back(); },
                );
        },
      ),
      isScrollControlled: true,
    );
  }

  Future<void> pickVideo(int type) async {
    selectedItem = S.current.videoCap;
    final picked = await picker.pickVideo(
      source: type == 0 ? ImageSource.gallery : ImageSource.camera,
      maxDuration: const Duration(seconds: 60),
    );
    if (picked == null || picked.path.isEmpty) return;
    final videoFile = File(picked.path);
    final sizeInMb = videoFile.lengthSync() / (1024 * 1024);
    if (sizeInMb > AppRes.maxVideoUploadSize) {
      Get.dialog(VideoUploadDialog(selectAnother: () { Get.back(); pickVideo(type); }));
      return;
    }
    final thumbnail = await CommonFun.getFileThumbnail(picked.path);
    Get.bottomSheet(
      ImageVideoSendSheet(
        image: thumbnail, selectedItem: selectedItem,
        onSendBtnClick: (msg, _) async {
          CommonUI.lottieLoader();
          isAutoPayEnable
              ? minusCoinApi(() async {
                  final [thumbRes, videoRes] = await Future.wait([
                    ApiProvider().getStoreFileGivePath(image: thumbnail),
                    ApiProvider().getStoreFileGivePath(image: videoFile),
                  ]);
                  Get.back();
                  if (thumbRes.status == true && videoRes.status == true) {
                    Get.back();
                    await sendMessage(msgType: 'video', textMessage: msg, video: videoRes.path, image: thumbRes.path);
                  } else { CommonUI.snackBarWidget(thumbRes.message ?? videoRes.message); }
                })
              : getChatMsgDialog(
                  onContinueTap: (isSelected) => onAutoPaySelected(isSelected, type, () async {
                    final [thumbRes, videoRes] = await Future.wait([
                      ApiProvider().getStoreFileGivePath(image: thumbnail),
                      ApiProvider().getStoreFileGivePath(image: videoFile),
                    ]);
                    Get.back();
                    if (thumbRes.status == true && videoRes.status == true) { Get.back(); await sendMessage(msgType: 'video', textMessage: msg, video: videoRes.path, image: thumbRes.path); }
                    else { CommonUI.snackBarWidget(thumbRes.message ?? videoRes.message); }
                  }),
                  onCancelTap: () { Get.back(); Get.back(); },
                );
        },
      ),
      isScrollControlled: true,
    );
  }

  void onVideoItemClick(ChatMessage? data) {
    Get.to(() => VideoPreviewScreen(videoUrl: data?.video, type: VideoType.other));
  }

  void onImageTap(ChatMessage? imageData) {
    Get.to(() => ImageViewPage(userData: imageData, onBack: Get.back));
  }

  void _sendPushNotification(String lastMessage) {
    ApiProvider().pushNotification(
      title: registrationUserData?.fullname ?? '',
      body: lastMessage,
      conversationId: conversationID,
      deviceType: receiverUserData?.deviceType,
      token: '${receiverUserData?.deviceToken}',
    );
  }

  void emptyDialog() {
    Get.dialog(EmptyWalletDialog(
      onCancelTap: () { Get.back(); },
      onContinueTap: () { Get.back(); Get.bottomSheet(const BottomDiamondShop()); },
      walletCoin: walletCoin,
    ));
  }

  void getChatMsgDialog({required Function(bool isSelected) onContinueTap, required Function onCancelTap}) {
    Get.dialog(ReverseSwipeDialog(
      onContinueTap: onContinueTap,
      isCheckBoxVisible: true, walletCoin: walletCoin,
      title1: S.current.message.toUpperCase(), title2: S.current.priceCap,
      dialogDisc: AppRes.messageDisc(settingAppData?.messagePrice),
      coinPrice: '${settingAppData?.messagePrice ?? 0}',
      onCancelTap: () { Get.back(); onCancelTap.call(); },
    )).then((_) => getProfileAPi());
  }

  void updateDataLocalUser(UserData? data) { SessionManager.instance.setUser(data); }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _updateSenderUser();
    scrollController.dispose();
    textMsgController.dispose();
    conversationID = '';
    super.dispose();
  }

  void _updateSenderUser() async {
    // Mark messages as read when leaving the chat.
    try {
      final res = await ApiProvider().chatMessages(conversationID, count: 1);
      if (res['status'] == true) {
        final data = res['data'];
        if (data is List && data.isNotEmpty) {
          final lastMsg = ChatMessage.fromJson(data.first);
          await ApiProvider().chatMarkRead(conversationID, lastMsg.id! as int);
        }
      }
    } catch (_) {}
  }
}
