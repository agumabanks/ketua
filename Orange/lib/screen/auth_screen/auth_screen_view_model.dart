import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/common/common_ui.dart';
import 'package:ketua_ui/common/eula/eula_sheet.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/model/setting_model.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/screen/auth_screen/login_screen/login_screen.dart';
import 'package:ketua_ui/screen/auth_screen/widget/forget_password_view.dart';
import 'package:ketua_ui/screen/create_profile_screen/create_profile_screen.dart';
import 'package:ketua_ui/screen/create_profile_screen/create_profile_screen_view_model.dart';
import 'package:ketua_ui/screen/create_profile_screen/view/add_photos.dart';
import 'package:ketua_ui/screen/create_profile_screen/view/choose_religion.dart';
import 'package:ketua_ui/screen/create_profile_screen/view/find_matches.dart';
import 'package:ketua_ui/screen/create_profile_screen/view/relationship_goal.dart';
import 'package:ketua_ui/screen/create_profile_screen/view/select_interest.dart';
import 'package:ketua_ui/screen/create_profile_screen/view/select_languages.dart';
import 'package:ketua_ui/screen/dashboard/dashboard_screen.dart';
import 'package:ketua_ui/screen/restart_app/restart_app.dart';
import 'package:ketua_ui/service/firebase_notification_manager.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:stacked/stacked.dart';

class AuthScreenViewModel extends BaseViewModel {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  int pageIndex = 0;
  final GoogleSignIn signIn = GoogleSignIn.instance;

  PageController pageController = PageController();

  void init(int index) {
    FirebaseNotificationManager.shared;
    pageController = PageController(initialPage: index);
    openEULASheet();
  }

  void openEULASheet() {
    bool isNotOpen = SessionManager.instance.getBool(key: SessionKeys.eULA);
    if (Platform.isIOS && !isNotOpen) {
      Future.delayed(
        const Duration(milliseconds: 250),
        () {
          Get.bottomSheet(const EulaSheet(),
              isScrollControlled: true, enableDrag: false);
        },
      );
    }
  }

  void onLoginTap(int index) {
    pageIndex = index;
    notifyListeners();
    Get.to(() => LoginScreen(index: index, viewModel: this));
  }

  void onGoogleTap() async {
    CommonUI.lottieLoader();
    UserCredential? credential;
    try {
      credential = await signInWithGoogle();
    } catch (e) {
      log(e.toString());
      Get.back();
      CommonUI.snackBar(
          message: 'Google sign-in could not be completed. Please try again.');
    }

    if (credential?.user == null) return;
    registration(
      email: credential?.user?.email ?? '',
      loginType: LoginType.google.value,
      fullName: credential?.user?.displayName ??
          credential?.user?.email?.split('@')[0] ??
          'Unknown',
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    await signIn.initialize();
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser =
        await signIn.authenticate(scopeHint: ['email']);

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    // Create a new credential
    final credential =
        GoogleAuthProvider.credential(idToken: googleAuth.idToken);

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> registration(
      {bool isRegistration = false,
      required String email,
      required String fullName,
      required int loginType,
      Function(UserData? userData)? onCompletion}) async {
    try {
      String? pushToken;
      try {
        pushToken = await FirebaseMessaging.instance
            .getToken()
            .timeout(const Duration(seconds: 5));
      } catch (_) {/* Notification permission must not prevent sign-in. */}
      final value = await ApiProvider().registration(
          email: email,
          fullName: fullName,
          deviceToken: pushToken ?? '',
          loginType: loginType);
      if (Get.isDialogOpen == true) Get.back();
      if (value.status != true || value.data == null) {
        CommonUI.snackBar(
            message: value.message ?? 'Unable to connect your account.');
        return;
      }
      final language = ['en', 'fr', 'sw'].contains(value.data?.appLanguage)
          ? value.data!.appLanguage!
          : 'en';
      SessionManager.instance
          .setString(key: SessionKeys.languageCode, value: language);
      await Get.updateLocale(Locale(language));
      if (isRegistration) {
        onCompletion?.call(value.data);
      } else {
        SessionManager.instance.setBool(key: SessionKeys.isLogin, value: true);
        await navigateScreen(userData: value.data);
      }
      notifyListeners();
    } catch (error, stack) {
      if (Get.isDialogOpen == true) Get.back();
      log('KETUA account connection failed: ${error.runtimeType}');
      debugPrint(
          'KETUA account connection failed: ${error.runtimeType}\n$stack');
      CommonUI.snackBar(
          message: 'Unable to connect your account. Please try again.');
    }
  }

  void fakeLoginUser({required String email, required String password}) {
    FirebaseNotificationManager.shared.getNotificationToken((token) {
      ApiProvider()
          .fakeUserLogin(email: email, password: password, deviceToken: token)
          .then((value) {
        Get.back();
        if (value.status == true) {
          SessionManager.instance
              .setBool(key: SessionKeys.isLogin, value: true);
          navigateScreen(userData: value.data);
        } else {
          CommonUI.snackBarWidget(value.message);
        }
      });
    });
  }

  void onAppleTap() async {
    CommonUI.lottieLoader();
    UserCredential? credential;
    try {
      credential = await signInWithApple();
      log('EMAIL : ${credential.user?.email} FULLNAME : ${credential.user?.displayName ?? credential.user?.email?.split('@')[0]}');
    } catch (e) {
      log('$e');
      Get.back();
    }
    if (credential?.user == null) return;
    registration(
      email: credential?.user?.email ?? '',
      loginType: LoginType.apple.value,
      fullName: credential?.user?.displayName ??
          credential?.user?.email?.split('@')[0] ??
          'Unknown',
    );
  }

  Future<UserCredential> signInWithApple() async {
    // Request credential for the currently signed in Apple account.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ],
    );

    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode);

    return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  }

  Future<void> navigateScreen({UserData? userData}) async {
    if (userData == null) return;
    Appdata? appData = SessionManager.instance.getSettings()?.appdata;

    // Complete accounts must not depend on onboarding controllers surviving
    // route disposal. Resolve them only when an onboarding step is needed.
    CreateProfileScreenViewModel onboarding() {
      final controller = Get.put(CreateProfileScreenViewModel());
      controller.init(userData);
      return controller;
    }

    if (appData?.isDating == 1) {
      if (_isBasicProfileIncomplete(userData)) {
        onboarding();
        Get.off(() => const CreateProfileScreen());
        return;
      }

      if (_isMatchPreferenceIncomplete(userData)) {
        Get.off(() => FindMatches(userData: userData, model: onboarding()));
        return;
      }

      if (userData.interests == null) {
        Get.off(() => SelectInterest(userData: userData, model: onboarding()));
        return;
      }

      if (userData.relationshipGoalId == null) {
        Get.off(
            () => RelationshipGoal(userData: userData, model: onboarding()));
        return;
      }

      if (userData.religionKey == null) {
        Get.off(() => ChooseReligion(userData: userData, model: onboarding()));
        return;
      }

      if (userData.languageKeys == null) {
        Get.off(() => SelectLanguages(userData: userData, model: onboarding()));
        return;
      }

      if ((userData.images ?? []).isEmpty) {
        Get.off(() => AddPhotos(userData: userData, model: onboarding()));
        return;
      }
    } else {
      if (_isBasicProfileIncomplete(userData)) {
        onboarding();
        Get.off(() => const CreateProfileScreen());
        return;
      }
      if (userData.interests == null) {
        Get.off(() => SelectInterest(userData: userData, model: onboarding()));
        return;
      }
      if ((userData.images ?? []).isEmpty) {
        Get.off(() => AddPhotos(userData: userData, model: onboarding()));
        return;
      }
    }

    Get.offAll(() => const DashboardScreen());
  }

// Helper functions for clarity
  bool _isBasicProfileIncomplete(UserData user) {
    return user.fullname == null ||
        user.bio == null ||
        user.country == null ||
        user.state == null ||
        user.city == null;
  }

  bool _isMatchPreferenceIncomplete(UserData user) {
    return user.agePreferredMin == null ||
        user.agePreferredMax == null ||
        user.distancePreference == null;
  }

  Future<void> onContinueTap() async {
    if (pageIndex == 1) {
      if (fullNameController.text.trim().isEmpty) {
        return CommonUI.snackBar(message: S.current.enterFullName);
      }
    }
    if (emailController.text.trim().isEmpty) {
      return CommonUI.snackBar(message: S.current.enterEmail);
    }
    if (passwordController.text.trim().isEmpty) {
      return CommonUI.snackBar(message: S.current.enterPassword);
    }
    if (pageIndex == 1) {
      if (confirmPasswordController.text.trim().isEmpty) {
        return CommonUI.snackBar(message: S.current.enterConfirmPassword);
      }
      if (passwordController.text.trim() !=
          confirmPasswordController.text.trim()) {
        return CommonUI.snackBar(message: S.current.passwordMismatch);
      }
    }
    CommonUI.lottieLoader();
    UserCredential? userCredential;
    if (pageIndex == 0) {
      if (!GetUtils.isEmail(emailController.text.trim())) {
        fakeLoginUser(
            email: emailController.text.trim(),
            password: passwordController.text.trim());
        return;
      }
      userCredential = await signInWithEmailAndPassword();
    } else {
      userCredential = await createUserWithEmailAndPassword();
    }
    if (userCredential == null) return;
    SessionManager.instance.storage.remove(SessionKeys.password);
    if (pageIndex == 0) {
      if (userCredential.user?.emailVerified == false) {
        Get.back();
        return CommonUI.snackBar(
            message: S.current.pleaseVerifyYourEmailFromYourInbox);
      }
    }
    registration(
        email: emailController.text.trim(),
        fullName: fullNameController.text.trim(),
        loginType: LoginType.email.value,
        isRegistration: pageIndex == 1 ? true : false,
        onCompletion: (userData) {
          pageIndex = 0;
          pageController.animateToPage(pageIndex,
              duration: const Duration(milliseconds: 250),
              curve: Curves.linear);
          userCredential?.user
              ?.updateDisplayName(fullNameController.text.trim());
          userCredential?.user?.sendEmailVerification();
          CommonUI.snackBar(
              message: S.current.aVerificationLinkHasBeenSentToYourEmailPlease);
        });
  }

  Future<UserCredential?> signInWithEmailAndPassword() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim());
      return credential;
    } on FirebaseAuthException catch (e) {
      Get.back();
      if (e.code == 'user-not-found') {
        CommonUI.snackBar(
            message: S.current.noUserFoundWithThatEmailPleaseRegisterWithThis);
      } else if (e.code == 'wrong-password') {
        CommonUI.snackBar(
            message: S.current.incorrectPasswordProvidedForThisUser);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword() async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());
      return credential;
    } on FirebaseAuthException catch (e) {
      Get.back();
      log(e.message.toString());
      if (e.code == 'weak-password') {
        CommonUI.snackBar(message: S.current.thePasswordProvidedIsTooWeak);
      } else if (e.code == 'email-already-in-use') {
        CommonUI.snackBar(
            message: S.current.theAccountAlreadyExistsForThatEmail);
      } else {
        CommonUI.snackBar(message: e.message.toString());
      }
      return null;
    }
  }

  void onForgotPasswordTap() {
    Get.to(() => ForgetPasswordView(viewModel: this));
  }

  void onForgetPassword() async {
    if (emailController.text.trim().isEmpty) {
      return CommonUI.snackBar(message: S.current.enterEmail);
    }
    CommonUI.lottieLoader();
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailController.text.trim());
      Get.back();
      Get.back();
      CommonUI.snackBar(
          message: S.current.aResetPasswordLinkHasBeenSentToYourEmail);
    } on FirebaseAuthException catch (e) {
      Get.back();
      CommonUI.snackBar(
          message: e.message ?? "An error occurred. Please try again.");
    }
  }
}

enum LoginType {
  google(1),
  apple(2),
  facebook(3),
  email(4);

  final int value;

  const LoginType(this.value);
}
