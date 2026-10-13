import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/model/notification/admin_notification.dart';
import 'package:ketua_ui/model/notification/user_notification_model.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/screen/user_detail_screen/user_detail_screen.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:stacked/stacked.dart';

class NotificationScreenViewModel extends BaseViewModel {
  final ApiProvider api;
  final SessionManager session;
  NotificationScreenViewModel({ApiProvider? api, SessionManager? session})
      : api = api ?? ApiProvider(),
        session = session ?? SessionManager.instance;
  String notification = S.current.notification;
  int tabIndex = 0, start = 0, adminStart = 0;
  final userScrollController = ScrollController();
  final adminScrollController = ScrollController();
  bool isLoading = false, isUserLoading = false;
  bool _disposed = false,
      _adminLoaded = false,
      _userEnd = false,
      _adminEnd = false;
  String? refreshError;
  List<AdminNotificationData> adminNotification = [];
  List<UserNotificationData> userNotification = [];
  void changed() {
    if (!_disposed) notifyListeners();
  }

  void init() {
    restore();
    fetchScrollData();
  }

  Future<void> restore() async {
    final snapshot = await session.readSnapshot('notification_personal');
    if (_disposed) return;
    if (snapshot != null) {
      userNotification = UserNotificationModel.fromJson(snapshot).data ?? [];
      changed();
    }
    await getUserNotificationApiCall(reset: true);
  }

  @override
  void dispose() {
    _disposed = true;
    userScrollController.dispose();
    adminScrollController.dispose();
    super.dispose();
  }

  Future<void> getAdminNotificationApiCall({bool reset = false}) async {
    if (isLoading || (_adminEnd && !reset)) return;
    isLoading = true;
    refreshError = null;
    changed();
    final owner = session.getUserID();
    try {
      final value = await api
          .adminNotification(reset ? 0 : adminStart)
          .timeout(const Duration(seconds: 15));
      if (_disposed || owner != session.getUserID()) return;
      if (value.status != true) throw StateError('Unavailable');
      final page = value.data ?? <AdminNotificationData>[];
      if (reset)
        adminNotification = page;
      else
        adminNotification.addAll(page);
      adminStart = adminNotification.length;
      _adminEnd = page.isEmpty;
      _adminLoaded = true;
    } catch (_) {
      if (!_disposed)
        refreshError = 'Updates could not refresh. Pull down to retry.';
    } finally {
      isLoading = false;
      changed();
    }
  }

  Future<void> getUserNotificationApiCall({bool reset = false}) async {
    if (isUserLoading || (_userEnd && !reset)) return;
    isUserLoading = true;
    refreshError = null;
    changed();
    final owner = session.getUserID();
    try {
      final value = await api
          .getUserNotification(reset ? 0 : start)
          .timeout(const Duration(seconds: 15));
      if (_disposed || owner != session.getUserID()) return;
      if (value.status != true) throw StateError('Unavailable');
      final page = value.data ?? <UserNotificationData>[];
      if (reset)
        userNotification = page;
      else
        userNotification.addAll(page);
      start = userNotification.length;
      _userEnd = page.isEmpty;
      await session.writeSnapshot('notification_personal',
          UserNotificationModel(status: true, data: userNotification).toJson());
    } catch (_) {
      if (!_disposed)
        refreshError = 'Updates could not refresh. Pull down to retry.';
    } finally {
      isUserLoading = false;
      changed();
    }
  }

  Future<void> refresh() => tabIndex == 0
      ? getUserNotificationApiCall(reset: true)
      : getAdminNotificationApiCall(reset: true);
  void fetchScrollData() {
    userScrollController.addListener(() {
      if (userScrollController.position.extentAfter < 160)
        getUserNotificationApiCall();
    });
    adminScrollController.addListener(() {
      if (adminScrollController.position.extentAfter < 160)
        getAdminNotificationApiCall();
    });
  }

  void onUserTap(UserData? data) {
    if (data != null) Get.to(() => UserDetailScreen(userData: data));
  }

  void onTabChange(int index) {
    if (tabIndex == index) return;
    tabIndex = index;
    refreshError = null;
    if (index == 1 && !_adminLoaded) getAdminNotificationApiCall(reset: true);
    changed();
  }
}
