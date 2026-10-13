import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/model/chat_and_live_stream/add_live_stream_history.dart';
import 'package:ketua_ui/model/chat_and_live_stream/agora.dart';
import 'package:ketua_ui/model/chat_and_live_stream/apply_for_live.dart';
import 'package:ketua_ui/model/chat_and_live_stream/fetch_live_stream_history.dart';
import 'package:ketua_ui/model/fetch_redeem_request.dart';
import 'package:ketua_ui/model/get_diamond_pack.dart';
import 'package:ketua_ui/model/get_explore_screen.dart';
import 'package:ketua_ui/model/map/fetch_user_coordinate.dart';
import 'package:ketua_ui/model/notification/admin_notification.dart';
import 'package:ketua_ui/model/notification/user_notification_model.dart';
import 'package:ketua_ui/model/report.dart';
import 'package:ketua_ui/model/search/search_user.dart';
import 'package:ketua_ui/model/search/search_user_by_id.dart';
import 'package:ketua_ui/model/setting_model.dart';
import 'package:ketua_ui/model/store_file_give_path.dart';
import 'package:ketua_ui/model/user/delete_account.dart';
import 'package:ketua_ui/model/user/like_model.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/model/verification.dart';
import 'package:ketua_ui/model/wallet/minus_coin_from_wallet.dart';
import 'package:ketua_ui/service/firebase_notification_manager.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/utils/app_res.dart';
import 'package:ketua_ui/utils/const_res.dart';
import 'package:ketua_ui/utils/network_guard.dart';
import 'package:ketua_ui/utils/urls.dart';

class ApiProvider {
  final http.Client? client;

  /// K17: default guarded HTTP client. Every app-authored request goes through
  /// [NetworkGuard] so a non-allowlisted host can never be contacted. Callers
  /// that inject their own `client` (tests) still pass through [callPost]'s
  /// explicit [NetworkGuard] check; this default covers the many direct
  /// `_http.post/get` call sites throughout this provider.
  late final http.Client _http = _GuardedClient(client ?? http.Client());

  ApiProvider({this.client});
  Map<String, String> headers = {Urls.apiKeyName: ConstRes.apiKey};
  String myUserId = SessionManager.instance.getUserID().toString();

  // K09: build request headers with the per-user bearer token (when present).
  Map<String, String> authHeaders() {
    final h = <String, String>{Urls.apiKeyName: ConstRes.apiKey};
    final token = SessionManager.instance.getAuthToken();
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Future<int> incomingLikesCount() async {
    final response = await _http.get(
        Uri.parse('${ConstRes.aBaseUrl}likes/incoming'),
        headers: authHeaders());
    final result = _safeJson(response.body);
    if (response.statusCode != 200 || result['status'] != true)
      throw StateError('Likes unavailable');
    return int.tryParse('${result['count']}') ?? 0;
  }

  Future<void> _persistAuth(String? token) async {
    if (token != null && token.isNotEmpty) {
      await SessionManager.instance.setAuthToken(token);
    }
  }

  Future<UserModel> registration(
      {required String? email,
      required String? fullName,
      required String? deviceToken,
      required int? loginType,
      String? password}) async {
    Map<String, dynamic> map = {};
    map[Urls.fullName] = fullName;
    map[Urls.deviceToken] = deviceToken;
    map[Urls.deviceType] = Platform.isAndroid ? Urls.aOne : Urls.aTwo;
    map[Urls.loginType] = loginType.toString();
    map[Urls.identity] = email;
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Sign in again to securely connect your KETUA account.');
    }
    map['id_token'] = idToken;
    http.Response response = await _http.post(
      Uri.parse(Urls.aRegister),
      headers: authHeaders(),
      body: map,
    );
    UserModel user = UserModel.fromJson(jsonDecode(response.body));

    if (user.status == true) {
      await _persistAuth(user.token);
      if (user.data?.isNotification == 1) {
        FirebaseNotificationManager.shared.subscribeToTopic();
        FirebaseNotificationManager.shared
            .subscribeToTopic(topic: AppRes.liveStreamingTopic);
      } else {
        FirebaseNotificationManager.shared.unsubscribeToTopic();
        FirebaseNotificationManager.shared
            .unsubscribeToTopic(topic: AppRes.liveStreamingTopic);
      }
      SessionManager.instance.setUser(user.data);
    }
    return user;
  }

  Future<Map<String, dynamic>> resolvePhone(String phone) async {
    final r = await _http.post(
        Uri.parse('${ConstRes.aBaseUrl}auth/phone/resolve'),
        headers: authHeaders(),
        body: {'phone': phone}).timeout(const Duration(seconds: 15));
    if (r.statusCode == 429)
      return {
        'status': false,
        'message': 'Too many attempts. Please wait a minute.'
      };
    return Map<String, dynamic>.from(jsonDecode(r.body));
  }

  Future<UserModel> phoneAccount(
      {required String phone,
      required String password,
      required bool register,
      String? fullname,
      String? confirmation,
      String? deviceToken}) async {
    final response = await _http.post(
        Uri.parse(
            '${ConstRes.aBaseUrl}auth/phone/${register ? 'register' : 'login'}'),
        headers: authHeaders(),
        body: {
          'phone': phone,
          'password': password,
          if (register) 'fullname': fullname ?? '',
          if (register) 'password_confirmation': confirmation ?? '',
          if (deviceToken != null) 'device_token': deviceToken
        }).timeout(const Duration(seconds: 20));
    final result = UserModel.fromJson(jsonDecode(response.body));
    if (result.status == true) {
      await _persistAuth(result.token);
      SessionManager.instance.setUser(result.data);
    }
    return result;
  }

  Future<UserModel> fakeUserLogin(
      {required String? email,
      required String password,
      required String deviceToken}) async {
    Map<String, dynamic> map = {};
    map[Urls.identity] = email;
    map[Urls.password] = password;
    map[Urls.deviceToken] = deviceToken;
    map[Urls.deviceType] = Platform.isAndroid ? Urls.aOne : Urls.aTwo;
    http.Response response = await _http.post(
      Uri.parse(Urls.aFakeUserLogin),
      headers: authHeaders(),
      body: map,
    );
    UserModel user = UserModel.fromJson(jsonDecode(response.body));

    if (user.status == true) {
      await _persistAuth(user.token);
      if (user.data?.isNotification == 1) {
        FirebaseNotificationManager.shared.subscribeToTopic();
        FirebaseNotificationManager.shared
            .subscribeToTopic(topic: AppRes.liveStreamingTopic);
      } else {
        FirebaseNotificationManager.shared.unsubscribeToTopic();
        FirebaseNotificationManager.shared
            .unsubscribeToTopic(topic: AppRes.liveStreamingTopic);
      }
      SessionManager.instance.setUser(user.data);
    }
    return user;
  }

  Future<ApplyForLive> applyForLive(File? introVideo, String aboutYou,
      String languages, String socialLinks) async {
    var request = http.MultipartRequest(
      Urls.post,
      Uri.parse(Urls.aApplyForLive),
    );
    request.headers.addAll(authHeaders());
    request.fields[Urls.userId] = myUserId.toString();
    request.fields[Urls.aSocialLink] = socialLinks;
    if (introVideo != null) {
      request.files.add(
        http.MultipartFile(Urls.aIntroVideo,
            introVideo.readAsBytes().asStream(), introVideo.lengthSync(),
            filename: introVideo.path.split("/").last),
      );
    }
    request.fields[Urls.aLanguages] = languages;
    request.fields[Urls.aAboutYou] = aboutYou;

    var response = await request.send();
    var respStr = await response.stream.bytesToString();
    final responseJson = jsonDecode(respStr);
    ApplyForLive applyForLive = ApplyForLive.fromJson(responseJson);
    return applyForLive;
  }

  Future<UserModel> updateProfile({
    String? fullName,
    int? gender,
    String? age,
    String? dob,
    double? distancePreference,
    int? relationshipGoalId,
    String? religionKey,
    String? languageKeys,
    List<XFile>? images,
    String? live,
    String? bio,
    List<String>? interest,
    String? latitude,
    String? longitude,
    String? instagram,
    String? facebook,
    String? youtube,
    String? userName,
    int? genderPreferred,
    double? ageMin,
    double? ageMax,
    List<String>? deleteImageIds,
    String? about,
    int? isVerified,
    String? hiddenUserIds,
    String? country,
    String? state,
    String? city,
    String? appLanguage,
    double? locationAccuracy,
    List<String>? imageOrder,
  }) async {
    var request = http.MultipartRequest(
      Urls.post,
      Uri.parse(Urls.aUpdateProfile),
    );
    request.headers.addAll(authHeaders());
    request.fields[Urls.userId] = myUserId.toString();
    if (live != null) {
      request.fields[Urls.live] = live;
    }
    if (genderPreferred != null) {
      request.fields[Urls.genderPreferred] = '$genderPreferred';
    }
    if (distancePreference != null) {
      request.fields[Urls.distancePreference] = '${distancePreference.toInt()}';
    }
    if (relationshipGoalId != null) {
      request.fields[Urls.relationshipGoalId] = '$relationshipGoalId';
    }
    if (religionKey != null) {
      request.fields[Urls.religionKey] = religionKey;
    }
    if (languageKeys != null) {
      request.fields[Urls.languageKeys] = languageKeys;
    }
    if (bio != null) {
      request.fields[Urls.bio] = bio;
    }
    if (age != null) {
      request.fields[Urls.age] = age;
    }
    if (country != null) {
      request.fields[Urls.country] = country;
    }
    if (state != null) {
      request.fields[Urls.state] = state;
    }
    if (city != null) {
      request.fields[Urls.city] = city;
    }
    if (dob != null) {
      request.fields[Urls.dob] = dob;
    }
    if (isVerified != null) {
      request.fields[Urls.isVerified] = '$isVerified';
    }
    if (fullName != null) {
      request.fields[Urls.fullName] = fullName;
    }
    if (userName != null) {
      request.fields[Urls.userName] = userName;
    }
    if (instagram != null) {
      request.fields[Urls.instagram] = instagram;
    }
    if (ageMin != null) {
      request.fields[Urls.agePreferredMin] = '${ageMin.toInt()}';
    }
    if (ageMax != null) {
      request.fields[Urls.agePreferredMax] = '${ageMax.toInt()}';
    }
    if (facebook != null) {
      request.fields[Urls.facebook] = facebook;
    }
    if (youtube != null) {
      request.fields[Urls.youtube] = youtube;
    }
    if (latitude != null) {
      request.fields[Urls.latitude] = latitude;
    }
    if (longitude != null) {
      request.fields[Urls.longitude] = longitude;
    }
    if (interest != null) {
      request.fields[Urls.interests] = interest.join(",");
    }
    if (gender != null) {
      request.fields[Urls.gender] = '$gender';
    }
    if (about != null) {
      request.fields[Urls.about] = about;
    }
    if (hiddenUserIds != null) {
      request.fields[Urls.hiddenUserIds] = hiddenUserIds;
    }
    if (appLanguage != null) {
      request.fields[Urls.appLanguage] = appLanguage;
    }
    if (locationAccuracy != null)
      request.fields['location_accuracy_m'] = '$locationAccuracy';
    if (imageOrder != null)
      for (var i = 0; i < imageOrder.length; i++)
        request.fields['image_order[$i]'] = imageOrder[i];
    List<http.MultipartFile> newList = <http.MultipartFile>[];
    Map<String, String> map = {};
    if (deleteImageIds != null) {
      for (int i = 0; i < deleteImageIds.length; i++) {
        map['${Urls.deleteImagesId}[$i]'] = deleteImageIds[i];
      }
    }
    request.fields.addAll(map);
    if (images != null) {
      for (int i = 0; i < images.length; i++) {
        File imageFile = File(images[i].path);
        var multipartFile = http.MultipartFile(Urls.images,
            imageFile.readAsBytes().asStream(), imageFile.lengthSync(),
            filename: imageFile.path.split('/').last);
        newList.add(multipartFile);
      }
    }

    request.files.addAll(newList);
    var response = await request.send().timeout(const Duration(seconds: 30));
    var respStr = await response.stream
        .bytesToString()
        .timeout(const Duration(seconds: 30));
    final responseJson = jsonDecode(respStr);
    UserModel updateProfile = UserModel.fromJson(responseJson);
    if (updateProfile.status == true && updateProfile.data != null)
      SessionManager.instance.setUser(updateProfile.data);
    // Profile and conversation identity are authoritative in the KETUA backend.
    return updateProfile;
  }

  Future<UserModel> getProfile({int? userID}) async {
    http.Response response = await http
        .post(Uri.parse(Urls.aGetProfile), headers: authHeaders(), body: {
      Urls.userId: '${userID ?? myUserId}',
      Urls.myUserId: myUserId.toString(),
    });

    UserModel profile = UserModel.fromJson(jsonDecode(response.body));
    if (profile.status == true && myUserId == profile.data?.id.toString()) {
      SessionManager.instance.setUser(profile.data);
    }

    return profile;
  }

  Future<UserModel> fetchMyUserProfile() async {
    http.Response response = await _http.post(
        Uri.parse(Urls.aFetchMyUserProfile),
        headers: authHeaders(),
        body: {
          Urls.userId: myUserId,
        });
    UserModel profile = UserModel.fromJson(jsonDecode(response.body));
    if (profile.status == true) {
      SessionManager.instance.setUser(profile.data);
    }
    return profile;
  }

  Future<UserModel> onOffNotification(int state) async {
    http.Response response = await _http.post(Uri.parse(Urls.aOnOffNotification),
        headers: authHeaders(),
        body: {
          Urls.userId: myUserId.toString(),
          Urls.aState: state.toString()
        });
    return UserModel.fromJson(jsonDecode(response.body));
  }

  Future<UserModel> onOffShowMeOnMap(int state) async {
    http.Response response = await _http.post(Uri.parse(Urls.aOnOffShowMeOnMap),
        headers: authHeaders(),
        body: {
          Urls.userId: myUserId.toString(),
          Urls.aState: state.toString()
        });
    return UserModel.fromJson(jsonDecode(response.body));
  }

  Future<UserModel> onOffAnonymous(int? state) async {
    http.Response response = await _http.post(Uri.parse(Urls.aOnOffAnonymous),
        headers: authHeaders(),
        body: {
          Urls.userId: myUserId.toString(),
          Urls.aState: state.toString()
        });

    return UserModel.fromJson(jsonDecode(response.body));
  }

  Future<Report> addReport(String reason, String description, int? id) async {
    http.Response response = await _http.post(Uri.parse(Urls.aAddUserReport),
        headers: authHeaders(),
        body: {
          Urls.aReason: reason,
          Urls.aDescription: description,
          Urls.userId: id.toString()
        });
    return Report.fromJson(jsonDecode(response.body));
  }

  Future<AdminNotification> adminNotification(int start) async {
    http.Response response = await _http.post(
        Uri.parse(Urls.aGetAdminNotification),
        headers: authHeaders(),
        body: {
          Urls.aStart: start.toString(),
          Urls.aCount: '${AppRes.paginationLimit}'
        });
    return AdminNotification.fromJson(jsonDecode(response.body));
  }

  Future<UserNotificationModel> getUserNotification(int start) async {
    http.Response response = await _http.post(
        Uri.parse(Urls.aGetUserNotification),
        headers: authHeaders(),
        body: {
          Urls.userId: myUserId.toString(),
          Urls.aStart: start.toString(),
          Urls.aCount: '${AppRes.paginationLimit}',
        });
    // print('error : ${response.body}');
    return UserNotificationModel.fromJson(jsonDecode(response.body));
  }

  Future<SettingModel> getSettingData() async {
    http.Response response = await _http.post(
      Uri.parse(Urls.aGetSettingData),
      headers: authHeaders(),
    );
    SettingModel setting = SettingModel.fromJson(jsonDecode(response.body));
    if (setting.status == true) {
      SessionManager.instance.setSettings(setting.data);
    }
    return setting;
  }

  Future<SearchUser> searchUser(
      {required String searchKeyword, required int start}) async {
    http.Response response = await http
        .post(Uri.parse(Urls.aSearchUsers), headers: authHeaders(), body: {
      Urls.userId: "${SessionManager.instance.getUserID()}",
      Urls.aKeyword: searchKeyword,
      Urls.aStart: start.toString(),
      Urls.aCount: '${AppRes.paginationLimit}'
    });
    SearchUser searchUser = SearchUser.fromJson(jsonDecode(response.body));
    return searchUser;
  }

  Future<SearchUserById> searchUserById(
      {required String searchKeyword,
      int? interestId,
      required int start}) async {
    http.Response response = await _http.post(
        Uri.parse(Urls.aSearchUsersForInterest),
        headers: authHeaders(),
        body: {
          Urls.userId: "${SessionManager.instance.getUserID()}",
          Urls.aKeyword: searchKeyword,
          Urls.aStart: start.toString(),
          Urls.aCount: '${AppRes.paginationLimit}',
          Urls.aInterestId: interestId.toString()
        });
    return SearchUserById.fromJson(jsonDecode(response.body));
  }

  Future<LikeModel> updateLikedProfile(int? profileId) async {
    http.Response response = await _http.post(
        Uri.parse(Urls.aUpdateLikedProfile),
        headers: authHeaders(),
        body: {
          Urls.userId: '$profileId',
          Urls.myUserId: myUserId,
        });
    LikeModel likeResponse = LikeModel.fromJson(jsonDecode(response.body));

    return likeResponse;
  }

  Future<Report> likedProfile(int? profileId) async {
    http.Response response = await http
        .post(Uri.parse(Urls.aLikedProfile), headers: authHeaders(), body: {
      Urls.userId: '$profileId',
      Urls.myUserId: myUserId,
    });
    Report likeResponse = Report.fromJson(jsonDecode(response.body));
    return likeResponse;
  }

  Future<Report> dislikedProfile(int? profileId) async {
    http.Response response = await http
        .post(Uri.parse(Urls.aDislikedProfile), headers: authHeaders(), body: {
      Urls.userId: '$profileId',
      Urls.myUserId: myUserId,
    });
    Report likeResponse = Report.fromJson(jsonDecode(response.body));
    return likeResponse;
  }

  // ===== Mission features (token-auth, server-authoritative) =====

  /// Swipe-up "Star" (premium super-like). Returns parsed JSON.
  Future<Map<String, dynamic>> starProfile(int? profileId) async {
    final r = await http
        .post(Uri.parse(Urls.aStarProfile), headers: authHeaders(), body: {
      Urls.userId: '$profileId',
    });
    return _safeJson(r.body);
  }

  /// Token-auth like with match detection.
  Future<Map<String, dynamic>> matchLike(int? profileId) async {
    final r = await http
        .post(Uri.parse(Urls.aMatchLike), headers: authHeaders(), body: {
      Urls.userId: '$profileId',
    });
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> myMatches() async {
    final r = await http
        .post(Uri.parse(Urls.aMyMatches), headers: authHeaders(), body: {});
    return _safeJson(r.body);
  }

  /// Send a gift (server prices + debits wallet atomically).
  Future<Map<String, dynamic>> sendGift(int giftId, int receiverId,
      {String context = 'chat',
      int? expectedCoinPrice,
      String? clientKey}) async {
    final r = await http
        .post(Uri.parse(Urls.aSendGift), headers: authHeaders(), body: {
      'gift_id': '$giftId',
      if (clientKey != null) 'client_key': clientKey,
      'receiver_id': '$receiverId',
      'context': context,
      if (expectedCoinPrice != null)
        'expected_coin_price': '$expectedCoinPrice',
    });
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> boostStatus() async {
    final r = await _http.post(Uri.parse('${Urls.aBoost}/status'),
        headers: authHeaders(), body: {});
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> activateBoost() async {
    final r = await http
        .post(Uri.parse(Urls.aBoost), headers: authHeaders(), body: {});
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> heartbeat() async {
    final r = await http
        .post(Uri.parse(Urls.aHeartbeat), headers: authHeaders(), body: {});
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> profileCompleteness() async {
    final r = await _http.post(Uri.parse(Urls.aProfileCompleteness),
        headers: authHeaders(), body: {});
    return _safeJson(r.body);
  }

  // ===== Short video (F15) =====
  Future<Map<String, dynamic>> shortVideoFeed(
      {int start = 0, int count = 10}) async {
    final r = await http
        .post(Uri.parse(Urls.aShortVideoFeed), headers: authHeaders(), body: {
      'start': '$start',
      'count': '$count',
    });
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> shortVideoLike(int shortVideoId) async {
    final r = await http
        .post(Uri.parse(Urls.aShortVideoLike), headers: authHeaders(), body: {
      'short_video_id': '$shortVideoId',
    });
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> shortVideoView(int shortVideoId) async {
    final r = await http
        .post(Uri.parse(Urls.aShortVideoView), headers: authHeaders(), body: {
      'short_video_id': '$shortVideoId',
    });
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> shortVideoShare(int shortVideoId) async {
    final r = await http
        .post(Uri.parse(Urls.aShortVideoShare), headers: authHeaders(), body: {
      'short_video_id': '$shortVideoId',
    });
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> shortVideoCreate({
    required File videoFile,
    String? caption,
    String? hashtags,
    int? durationSec,
  }) async {
    final req =
        http.MultipartRequest('POST', Uri.parse(Urls.aShortVideoCreate));
    req.headers.addAll(authHeaders());
    req.files.add(await http.MultipartFile.fromPath('video', videoFile.path));
    if (caption != null) req.fields['caption'] = caption;
    if (hashtags != null) req.fields['hashtags'] = hashtags;
    if (durationSec != null) req.fields['duration_sec'] = '$durationSec';
    final resp = await req.send();
    return _safeJson(await resp.stream.bytesToString());
  }

  Future<Map<String, dynamic>> shortVideoDelete(int shortVideoId) async {
    final r = await http
        .post(Uri.parse(Urls.aShortVideoDelete), headers: authHeaders(), body: {
      'short_video_id': '$shortVideoId',
    });
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> experiences({String? category}) async {
    final r = await _http.get(
        Uri.parse('${ConstRes.aBaseUrl}experiences').replace(
            queryParameters: category == null ? null : {'category': category}),
        headers: authHeaders());
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> experienceTickets() async {
    final r = await _http.get(
        Uri.parse('${ConstRes.aBaseUrl}experiences/tickets'),
        headers: authHeaders());
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> reserveExperience(int id) async {
    final r = await _http.post(
        Uri.parse('${ConstRes.aBaseUrl}experiences/reserve'),
        headers: authHeaders(),
        body: {'experience_id': '$id'});
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> creatorEarn() async {
    final r = await _http.get(Uri.parse('${ConstRes.aBaseUrl}creator/earn'),
        headers: authHeaders());
    return _safeJson(r.body);
  }

  // ===== Chat (F06) — server-authoritative messaging =====
  Future<Map<String, dynamic>> chatConversations() async {
    final r = await _http.post(Uri.parse(Urls.aChatConversations),
        headers: authHeaders(), body: {});
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> chatSend(int receiverId, String? body,
      {String messageType = 'text',
      File? media,
      String? clientKey,
      int? replyToId}) async {
    if (media != null) {
      final req = http.MultipartRequest('POST', Uri.parse(Urls.aChatSend));
      req.headers.addAll(authHeaders());
      req.fields['receiver_id'] = '$receiverId';
      if (clientKey != null) req.fields['client_key'] = clientKey;
      if (replyToId != null) req.fields['reply_to_id'] = '$replyToId';
      req.fields['message_type'] = messageType;
      if (body != null) req.fields['body'] = body;
      req.files.add(await http.MultipartFile.fromPath('media', media.path));
      final resp = await req.send();
      return _safeJson(await resp.stream.bytesToString());
    }
    final r = await http
        .post(Uri.parse(Urls.aChatSend), headers: authHeaders(), body: {
      'receiver_id': '$receiverId',
      if (body != null) 'body': body,
      'message_type': messageType,
      if (clientKey != null) 'client_key': clientKey,
      if (replyToId != null) 'reply_to_id': '$replyToId',
    });
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> chatMessages(String conversationId,
      {int? beforeId, int count = 50}) async {
    final r = await http
        .post(Uri.parse(Urls.aChatMessages), headers: authHeaders(), body: {
      'conversation_id': conversationId,
      if (beforeId != null) 'before_id': '$beforeId',
      'count': '$count',
    });
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> chatMarkRead(
      String conversationId, int lastReadMessageId) async {
    final r = await http
        .post(Uri.parse(Urls.aChatRead), headers: authHeaders(), body: {
      'conversation_id': conversationId,
      'last_read_message_id': '$lastReadMessageId',
    });
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> chatBlock(
      String conversationId, String action) async {
    final r = await http
        .post(Uri.parse(Urls.aChatBlock), headers: authHeaders(), body: {
      'conversation_id': conversationId,
      'action': action,
    });
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> chatMute(
      String conversationId, String action) async {
    final r = await http
        .post(Uri.parse(Urls.aChatMute), headers: authHeaders(), body: {
      'conversation_id': conversationId,
      'action': action,
    });
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> chatDeleteMessage(int messageId) async {
    final r = await _http.post(Uri.parse(Urls.aChatDeleteMessage),
        headers: authHeaders(),
        body: {
          'message_id': '$messageId',
        });
    return _safeJson(r.body);
  }

  Future<Map<String, dynamic>> chatDeleteConversation(
      String conversationId) async {
    final r = await _http.post(Uri.parse(Urls.aChatDeleteConversation),
        headers: authHeaders(),
        body: {
          'conversation_id': conversationId,
        });
    return _safeJson(r.body);
  }

  Map<String, dynamic> _safeJson(String body) {
    try {
      final d = jsonDecode(body);
      return d is Map<String, dynamic> ? d : {'status': false, 'raw': body};
    } catch (_) {
      return {'status': false, 'raw': body};
    }
  }

  Future<UserModel> updateSaveProfile(int? profileId) async {
    var userData = SessionManager.instance.getUser();
    String? savedProfile = userData?.savedProfile;

    // Send the updated saved profiles to the server
    http.Response response = await _http.post(
      Uri.parse(Urls.aUpdateSavedProfile),
      headers: authHeaders(),
      body: {
        Urls.userId: myUserId.toString(),
        Urls.aProfiles: savedProfile,
      },
    );

    // Parse the response and return the result
    UserModel updateSavedProfile =
        UserModel.fromJson(jsonDecode(response.body));

    return updateSavedProfile;
  }

  Future<FetchLiveStreamHistory> fetchAllLiveStreamHistory(int starting) async {
    http.Response response = await _http.post(
        Uri.parse(Urls.aFetchAllLiveStreamHistory),
        headers: authHeaders(),
        body: {
          Urls.userId: myUserId.toString(),
          Urls.aStart: '$starting',
          Urls.aCount: '${AppRes.paginationLimit}'
        });
    return FetchLiveStreamHistory.fromJson(jsonDecode(response.body));
  }

  Future<Verification> applyForVerification(
      File? photo, File? docImage, String fullName, String docType) async {
    var request =
        http.MultipartRequest(Urls.post, Uri.parse(Urls.aApplyForVerification));
    request.headers.addAll(authHeaders());
    request.fields[Urls.userId] = myUserId.toString();
    request.fields[Urls.aDocumentType] = docType;
    if (photo != null) {
      request.files.add(
        http.MultipartFile(
            Urls.aSelfie, photo.readAsBytes().asStream(), photo.lengthSync(),
            filename: photo.path.split("/").last),
      );
    }
    if (docImage != null) {
      request.files.add(
        http.MultipartFile(Urls.aDocument, docImage.readAsBytes().asStream(),
            docImage.lengthSync(),
            filename: docImage.path.split("/").last),
      );
    }
    request.fields[Urls.fullName] = fullName;

    var response = await request.send();
    var respStr = await response.stream.bytesToString();
    final responseJson = jsonDecode(respStr);
    Verification applyForVerification = Verification.fromJson(responseJson);
    return applyForVerification;
  }

  Future<DeleteAccount> deleteAccount(int? deleteId) async {
    http.Response response = await _http.post(Uri.parse(Urls.aDeleteMyAccount),
        headers: authHeaders(), body: {Urls.userId: deleteId.toString()});
    DeleteAccount deleteAccount =
        DeleteAccount.fromJson(jsonDecode(response.body));
    if (deleteAccount.status == true) {
      FirebaseNotificationManager.shared
          .unsubscribeToTopic(topic: AppRes.liveStreamingTopic);
    }
    return deleteAccount;
  }

  Future<StoreFileGivePath> getStoreFileGivePath({File? image}) async {
    var request =
        http.MultipartRequest(Urls.post, Uri.parse(Urls.aStorageFileGivePath));
    request.headers.addAll(authHeaders());
    if (image != null) {
      request.files.add(
        http.MultipartFile(
            Urls.aFile, image.readAsBytes().asStream(), image.lengthSync(),
            filename: image.path.split("/").last),
      );
    }
    var response = await request.send();
    var respStr = await response.stream.bytesToString();

    final responseJson = jsonDecode(respStr);
    StoreFileGivePath applyForVerification =
        StoreFileGivePath.fromJson(responseJson);

    return applyForVerification;
  }

  Future<MinusCoinFromWallet> minusCoinFromWallet(int? amount) async {
    http.Response response = await _http.post(
        Uri.parse(Urls.aMinusCoinsFromWallet),
        headers: authHeaders(),
        body: {
          Urls.userId: myUserId.toString(),
          Urls.aAmount: amount.toString()
        });
    getProfile();
    return MinusCoinFromWallet.fromJson(jsonDecode(response.body));
  }

  Future<MinusCoinFromWallet> addCoinFromWallet(num? amount) async {
    http.Response response = await _http.post(
      Uri.parse(Urls.aAddCoinsToWallet),
      headers: authHeaders(),
      body: {Urls.userId: myUserId.toString(), Urls.aAmount: amount.toString()},
    );

    return MinusCoinFromWallet.fromJson(jsonDecode(response.body));
  }

  Future<GetDiamondPack> getDiamondPack() async {
    http.Response response = await http
        .post(Uri.parse(Urls.aGetDiamondPacks), headers: authHeaders(), body: {
      Urls.userId: myUserId.toString(),
      Urls.aStart: '0',
      Urls.aCount: '${AppRes.paginationLimit}'
    });
    return GetDiamondPack.fromJson(jsonDecode(response.body));
  }

  Future<AddLiveStreamHistory> addLiveStreamHistory(
      {required String streamFor,
      required String startedAt,
      required String amountCollected}) async {
    http.Response response = await _http.post(
        Uri.parse(Urls.aAddLiveStreamHistory),
        headers: authHeaders(),
        body: {
          Urls.userId: myUserId.toString(),
          Urls.aStreamedFor: streamFor,
          Urls.aStartedAt: startedAt,
          Urls.aAmountCollected: amountCollected
        });
    return AddLiveStreamHistory.fromJson(jsonDecode(response.body));
  }

  Future<UserModel> getRandomProfile({required int gender}) async {
    http.Response response = await _http.post(Uri.parse(Urls.aGetRandomProfile),
        headers: authHeaders(),
        body: {
          Urls.userId: myUserId.toString(),
          Urls.gender: gender.toString()
        });

    return UserModel.fromJson(jsonDecode(response.body));
  }

  Future<GetExploreScreen> getExplorePageProfileList(
      {List<int> excludeIds = const []}) async {
    http.Response response = await _http.post(
        Uri.parse(Urls.aGetExplorePageProfileList),
        headers: authHeaders(),
        body: {
          Urls.userId: myUserId.toString(),
          if (excludeIds.isNotEmpty)
            'exclude_ids': excludeIds.take(1000).join(',')
        }).timeout(const Duration(seconds: 15));

    return GetExploreScreen.fromJson(jsonDecode(response.body));
  }

  Future<FetchRedeemRequest> fetchRedeemRequest() async {
    http.Response response = await _http.post(
        Uri.parse(Urls.aFetchMyRedeemRequests),
        headers: authHeaders(),
        body: {Urls.userId: myUserId.toString()});
    return FetchRedeemRequest.fromJson(jsonDecode(response.body));
  }

  Future<UserModel> updateBlockList(int? blockProfileId) async {
    var userData = SessionManager.instance.getUser();
    String? blockProfile = userData?.blockedUsers;
    List<int> blockProfileList = [];
    if (blockProfile != null &&
        blockProfile.isNotEmpty &&
        !blockProfile.contains(blockProfileId.toString())) {
      blockProfile += ',$blockProfileId';
    } else {
      if (blockProfile == null || blockProfile.isEmpty) {
        blockProfile = blockProfileId.toString();
      } else if (blockProfile.contains(blockProfileId.toString())) {
        for (int i = 0; i < blockProfile.split(',').length; i++) {
          blockProfileList.add(int.parse(blockProfile.split(',')[i]));
        }
        for (int i = 0; i < blockProfile.split(',').length; i++) {
          if (blockProfile.split(',')[i] == blockProfileId.toString()) {
            blockProfileList.removeAt(i);
            break;
          }
        }
        blockProfile = blockProfileList.join(",");
      }
    }

    http.Response response = await _http.post(Uri.parse(Urls.aUpdateBlockList),
        headers: authHeaders(),
        body: {
          Urls.userId: myUserId.toString(),
          Urls.aBlockedUsers: blockProfile
        });
    UserModel updateBlockProfile =
        UserModel.fromJson(jsonDecode(response.body));
    SessionManager.instance.setUser(updateBlockProfile.data);
    return updateBlockProfile;
  }

  Future<FetchUserCoordinate> getUserByLatLong(
      {required double latitude,
      required double longitude,
      required int km}) async {
    http.Response response = await _http.post(
        Uri.parse(Urls.aFetchUsersByCoordinates),
        headers: authHeaders(),
        body: {
          Urls.lat: latitude.toString(),
          Urls.long: longitude.toString(),
          Urls.aKm: km.toString()
        });
    return FetchUserCoordinate.fromJson(jsonDecode(response.body));
  }

  Future<void> pushNotification({
    String? token,
    String? topic,
    num? deviceType,
    required String title,
    required String body,
    String? conversationId,
    bool isLiveStreaming = false,
    Map<String, dynamic>? liveStreamUserData,
  }) async {
    final bool isIOS = deviceType == 2;

    // Prepare base notification data
    final Map<String, dynamic> messageData = {
      "apns": {
        "headers": {"apns-priority": "10"},
        "payload": {
          "aps": {"sound": "default", "content-available": 1}
        }
      },
      "data": isLiveStreaming
          ? (liveStreamUserData ?? {})
          : {
              if (conversationId != null) Urls.aConversationId: conversationId,
              "body": body,
              "title": title
            },
    };

    // iOS needs explicit notification payload
    if (isIOS) {
      messageData["notification"] = {
        "body": body,
        "title": title,
      };
    }

    // Set target
    if (token != null && token.isNotEmpty) {
      messageData["token"] = token;
    } else if (isLiveStreaming && topic != null && topic.isNotEmpty) {
      messageData["topic"] = topic;
    } else {
      return;
    }

    final Map<String, dynamic> inputData = {"message": messageData};

    try {
      final response = await _http.post(
        Uri.parse(Urls.aNotificationUrl),
        headers: authHeaders(),
        body: json.encode(inputData),
      );
    } catch (e) {}
  }

  Future<void> sendLocalizedPushNotification({
    required String key,
    required UserData? userData,
    required String? deviceToken,
  }) async {
    final languageCode =
        (userData?.appLanguage ?? Platform.localeName.split('_').first)
            .toLowerCase();
    if (!S.delegate.isSupported(Locale(languageCode))) return;

    try {
      final data =
          await rootBundle.loadString('lib/l10n/intl_$languageCode.arb');
      final translations = jsonDecode(data) as Map<String, dynamic>;

      pushNotification(
        title: userData?.fullname ?? '',
        body: translations[key] ?? '',
        deviceType: userData?.deviceType,
        token: deviceToken,
      );
    } catch (e) {}
  }

  Future<Report> logoutUser() async {
    http.Response response = await _http.post(Uri.parse(Urls.aLogoutUser),
        headers: authHeaders(), body: {Urls.userId: myUserId.toString()});
    Report report = Report.fromJson(jsonDecode(response.body));
    if (report.status == true) {
      FirebaseNotificationManager.shared
          .unsubscribeToTopic(topic: AppRes.liveStreamingTopic);
    }
    return report;
  }

  Future<Agora> agoraListStreamingCheck(
      String channelName, String authToken, String agoraAppId) async {
    http.Response response = await _http.get(
        Uri.parse(
            'https://api.agora.io/dev/v1/channel/user/$agoraAppId/$channelName'),
        headers: {'Authorization': 'Basic $authToken'});
    return Agora.fromJson(jsonDecode(response.body));
  }

  Future<SearchUser> fetchSavedProfiles() async {
    http.Response response = await _http.post(
        Uri.parse(Urls.aFetchSavedProfiles),
        headers: authHeaders(),
        body: {Urls.userId: myUserId.toString()});
    return SearchUser.fromJson(jsonDecode(response.body));
  }

  Future<SearchUser> fetchLikedProfiles() async {
    http.Response response = await _http.post(
        Uri.parse(Urls.aFetchLikedProfiles),
        headers: authHeaders(),
        body: {Urls.userId: myUserId});
    return SearchUser.fromJson(jsonDecode(response.body));
  }

  Future<SearchUser> fetchBlockedProfiles() async {
    http.Response response = await _http.post(
        Uri.parse(Urls.aFetchBlockedProfiles),
        headers: authHeaders(),
        body: {Urls.userId: myUserId.toString()});
    // print(response.body);
    return SearchUser.fromJson(jsonDecode(response.body));
  }

  Map<String, String> headersForUrl(String url) {
    final target = Uri.parse(url), api = Uri.parse(ConstRes.aBaseUrl);
    return target.scheme == api.scheme &&
            target.host == api.host &&
            target.port == api.port
        ? authHeaders()
        : <String, String>{};
  }

  Future<void> callPost({
    required Function(Object response) completion,
    required String url,
    Map<String, dynamic>? param,
  }) async {
    Map<String, String> params = {};
    param?.forEach((key, value) {
      params[key] = "$value";
    });
    // K17: enforce the network egress allowlist. Block any app-authored call
    // to a host the client is not permitted to contact (no third-party IP
    // geolocation, ad networks, analytics, etc.).
    if (!NetworkGuard.isAllowed(url)) {
      completion({
        'status': false,
        'message': 'Request blocked by network policy.',
        'data': []
      });
      return;
    }
    Object result;
    try {
      final value = await (client?.post(Uri.parse(url),
                  headers: headersForUrl(url), body: params) ??
              _http.post(Uri.parse(url),
                  headers: headersForUrl(url), body: params))
          .timeout(const Duration(seconds: 20));
      final decoded = jsonDecode(value.body);
      result = decoded is Map<String, dynamic>
          ? decoded
          : {
              'status': false,
              'message': 'Unexpected server response.',
              'data': []
            };
    } catch (_) {
      result = {
        'status': false,
        'message': 'Unable to connect. Please try again.',
        'data': []
      };
    }
    completion(result);
  }

  Future<void> multiPartCallApi(
      {required String url,
      Map<String, dynamic>? param,
      Map<String, List<XFile?>>? filesMap,
      required Function(Object response) completion}) async {
    // K17: enforce the network egress allowlist on the upload path too.
    if (!NetworkGuard.isAllowed(url)) {
      completion({
        'status': false,
        'message': 'Request blocked by network policy.',
        'data': []
      });
      return;
    }
    var request = http.MultipartRequest('POST', Uri.parse(url));

    Map<String, String> params = {};
    param?.forEach((key, value) {
      if (value is List) {
        for (int i = 0; i < value.length; i++) {
          params['$key[$i]'] = value[i];
        }
      } else {
        params[key] = "$value";
      }
    });

    request.fields.addAll(params);
    request.headers.addAll(headersForUrl(url));
    if (filesMap != null) {
      filesMap.forEach((keyName, files) {
        for (var xFile in files) {
          if (xFile != null && xFile.path.isNotEmpty) {
            File file = File(xFile.path);
            var multipartFile = http.MultipartFile(
                keyName, file.readAsBytes().asStream(), file.lengthSync(),
                filename: xFile.name);
            request.files.add(multipartFile);
          }
        }
      });
    }
    Object result;
    try {
      final value = await request.send().timeout(const Duration(seconds: 90));
      result = jsonDecode(await value.stream
          .bytesToString()
          .timeout(const Duration(seconds: 30)));
    } catch (_) {
      result = {
        'status': false,
        'message': 'Upload failed. Please try again.',
        'data': []
      };
    }
    completion(result);
  }
}

/// K17: an [http.Client] wrapper that enforces the [NetworkGuard] egress
/// allowlist on every request. A request to a non-allowlisted host throws
/// [_BlockedRequestError] instead of ever hitting the network, so even the
/// many direct dispatch sites in [ApiProvider] are covered by one policy.
class _GuardedClient extends http.BaseClient {
  _GuardedClient(this._inner);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (!NetworkGuard.isAllowed(request.url.toString())) {
      throw _BlockedRequestError(request.url.toString());
    }
    return _inner.send(request);
  }
}

class _BlockedRequestError extends Error {
  _BlockedRequestError(this.url);
  final String url;
  @override
  String toString() => 'Blocked request to non-allowlisted host: $url';
}
