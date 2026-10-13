import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/utils/const_res.dart';
import 'package:ketua_ui/screen/notification_screen/notification_screen.dart';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ketua_ui/screen/chat_screen/chat_screen_view_model.dart';
import 'package:ketua_ui/utils/app_res.dart';
import 'package:ketua_ui/utils/urls.dart';
import 'package:ketua_ui/service/session_manager.dart';

class FirebaseNotificationManager {
  static var shared = FirebaseNotificationManager();
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  AndroidNotificationChannel channel = const AndroidNotificationChannel(
      'ketua', // id
      AppRes.appName, // title
      playSound: true,
      enableLights: true,
      enableVibration: true,
      showBadge: false,
      importance: Importance.max);

  FirebaseNotificationManager() {
    init().catchError((_) {});
  }

  String? notificationId;

  Future<void> init() async {
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationSettingsIOS = const DarwinInitializationSettings(
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: false);

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    // The plugin must be initialized before checking Android permissions.
    await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (_) => _openNotifications());
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _openNotifications());
    final initial = await firebaseMessaging.getInitialMessage();
    if (initial != null)
      Future.delayed(const Duration(seconds: 2), () => _openNotifications());
    firebaseMessaging.onTokenRefresh.listen((token) => _saveToken(token));
    final token = await firebaseMessaging.getToken();
    if (token != null) await _saveToken(token);
    await firebaseMessaging.requestPermission(
        alert: true, badge: false, sound: true);
    if (SessionManager.instance.getUser()?.isNotification == 1)
      subscribeToTopic();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // If Notification has gone twice
      if (SessionManager.instance.getUser() == null) return;
      if (notificationId == message.messageId) return;
      notificationId = message.messageId;
      if (SessionManager.instance.getUser()?.isNotification == 0) return;
      if (ChatScreenViewModel.conversationID.isNotEmpty &&
          message.data[Urls.aConversationId] ==
              ChatScreenViewModel.conversationID) return;
      showNotification(message);
    });

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _openNotifications([int attempts = 0]) {
    if (SessionManager.instance.getUser() == null) return;
    final route = Get.currentRoute.toLowerCase();
    if (Get.context == null ||
        route.isEmpty ||
        route == '/' ||
        route.contains('splash')) {
      if (attempts < 30)
        Future.delayed(
            const Duration(seconds: 1), () => _openNotifications(attempts + 1));
      return;
    }
    if (!route.contains('notification'))
      Get.to(() => const NotificationScreen());
  }

  Future<void> _saveToken(String token) async {
    if (SessionManager.instance.getUser() == null || token.isEmpty) return;
    try {
      final headers = ApiProvider().authHeaders()
        ..['Content-Type'] = 'application/json';
      await http
          .post(Uri.parse('${ConstRes.aBaseUrl}notifications/device-token'),
              headers: headers, body: jsonEncode({'token': token}))
          .timeout(const Duration(seconds: 10));
    } catch (_) {/* A later token refresh or sign-in retries registration. */}
  }

  void showNotification(RemoteMessage message) {
    int notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);
    flutterLocalNotificationsPlugin.show(
      id: notificationId,
      title: message.data['title'] ?? message.notification?.title,
      body: message.data['body'] ?? message.notification?.body,
      notificationDetails: NotificationDetails(
          iOS: const DarwinNotificationDetails(
              presentSound: true, presentAlert: true, presentBadge: false),
          android: AndroidNotificationDetails(channel.id, channel.name)),
    );
  }

  void getNotificationToken(Function(String token) completion) async {
    try {
      await FirebaseMessaging.instance.getToken().then((value) {
        if (value != null) _saveToken(value);
        completion(value ?? 'No Token');
      });
    } catch (e) {
      completion('No Token');
      log(e.toString());
    }
  }

  void unsubscribeToTopic({String? topic}) async {
    log('Topic UnSubscribe');
    await firebaseMessaging.unsubscribeFromTopic(topic ??
        '${AppRes.subscribeTopic}_${Platform.isIOS ? 'ios' : 'android'}');
  }

  void subscribeToTopic({String? topic}) async {
    log('Topic Subscribe');
    await firebaseMessaging.subscribeToTopic(topic ??
        '${AppRes.subscribeTopic}_${Platform.isIOS ? 'ios' : 'android'}');
  }
}
