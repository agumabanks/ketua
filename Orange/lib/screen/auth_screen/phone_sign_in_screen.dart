import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/common/ketua_wordmark.dart';
import 'package:ketua_ui/screen/auth_screen/auth_screen_view_model.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/utils/color_res.dart';

class PhoneSignInScreen extends StatefulWidget {
  final bool initialRegistration;
  const PhoneSignInScreen({super.key, this.initialRegistration = true});
  @override
  State<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends State<PhoneSignInScreen> {
  final phone = TextEditingController(text: '+256');
  final password = TextEditingController();
  final confirmation = TextEditingController();
  final name = TextEditingController();
  bool register = true;
  @override
  void initState() {
    super.initState();
    register = widget.initialRegistration;
  }

  bool resolved = false;
  bool showPassword = false;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    for (final c in [phone, password, confirmation, name]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    if (!resolved) {
      final number = phone.text.replaceAll(RegExp(r'[\s()-]'), '');
      if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(number)) {
        setState(() => error =
            'Enter your phone number with its country code, for example +256…');
        return;
      }
      setState(() {
        busy = true;
        error = null;
      });
      try {
        final r = await ApiProvider().resolvePhone(number);
        if (mounted)
          setState(() {
            if (r['status'] == true) {
              resolved = true;
              register = r['next'] == 'create';
            } else {
              error = r['message'] ?? 'Please try again.';
            }
          });
      } catch (_) {
        if (mounted)
          setState(() =>
              error = 'Unable to connect. Your number is kept. Try again.');
      } finally {
        if (mounted) setState(() => busy = false);
      }
      return;
    }

    final number = phone.text.replaceAll(RegExp(r'[\s()-]'), '');
    String? validation;
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(number)) {
      validation =
          'Enter your phone number with its country code, for example +256…';
    } else if (register && name.text.trim().length < 2) {
      validation = 'Enter your name.';
    } else if (password.text.isEmpty ||
        (register && password.text.length < 12)) {
      validation = register
          ? 'Use a password of at least 12 characters.'
          : 'Enter your password.';
    } else if (register && confirmation.text != password.text) {
      validation = 'Your passwords must match.';
    }
    if (validation != null) {
      setState(() => error = validation);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      String? push;
      try {
        push = await FirebaseMessaging.instance
            .getToken()
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
      final result = await ApiProvider().phoneAccount(
          phone: number,
          password: password.text,
          register: register,
          fullname: name.text.trim(),
          confirmation: confirmation.text,
          deviceToken: push);
      if (result.status != true) {
        if (mounted)
          setState(() => error = result.message ?? 'Unable to sign in.');
        return;
      }
      password.clear();
      confirmation.clear();
      SessionManager.instance.setBool(key: SessionKeys.isLogin, value: true);
      if (mounted)
        await AuthScreenViewModel().navigateScreen(userData: result.data);
    } catch (_) {
      if (mounted)
        setState(() => error = 'Unable to connect. Please try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: ColorRes.bgDark,
      appBar: AppBar(title: const Text('Continue with phone')),
      body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
        const KetuaWordmark(size: 36),
        const SizedBox(height: 8),
        const Text('Meet. Vibe. Connect.',
            style: TextStyle(color: ColorRes.textSecondaryDark)),
        const SizedBox(height: 20),
        if (!resolved)
          SizedBox(
              height: 110,
              child: Row(children: [
                for (final i in [1, 3, 4, 5])
                  Expanded(
                      child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                  'assets/images/ketua_auth_$i.jpg',
                                  height: 110,
                                  fit: BoxFit.cover,
                                  cacheWidth: 240))))
              ])),
        const SizedBox(height: 20),
        Text(
            !resolved
                ? 'One number. More connections.'
                : register
                    ? 'Make it yours.'
                    : 'Welcome back.',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        const Text(
            'Enter your number to continue. Protect your account with a password. Phone ownership is not verified by SMS.',
            style: TextStyle(color: ColorRes.textSecondaryDark, height: 1.5)),
        const SizedBox(height: 24),
        TextField(
            controller: phone,
            enabled: !busy && !resolved,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: const InputDecoration(
                labelText: 'Phone number with country code')),
        if (resolved && register)
          Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextField(
                  controller: name,
                  enabled: !busy,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(labelText: 'Your name'))),
        const SizedBox(height: 16),
        if (resolved)
          TextField(
              controller: password,
              enabled: !busy,
              obscureText: !showPassword,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                  suffixIcon: IconButton(
                      tooltip: showPassword ? 'Hide password' : 'Show password',
                      onPressed: () =>
                          setState(() => showPassword = !showPassword),
                      icon: Icon(showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined)),
                  labelText: register
                      ? 'Password · at least 12 characters'
                      : 'Password')),
        if (resolved && register)
          Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextField(
                  controller: confirmation,
                  enabled: !busy,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration:
                      const InputDecoration(labelText: 'Confirm password'))),
        if (error != null)
          Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(error!,
                  style: const TextStyle(color: Color(0xFFFF8798)))),
        const SizedBox(height: 24),
        ElevatedButton(
            onPressed: busy ? null : submit,
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(!resolved
                    ? 'Continue'
                    : register
                        ? 'Create account'
                        : 'Continue')),
        if (resolved)
          TextButton(
              onPressed: busy
                  ? null
                  : () => setState(() {
                        resolved = false;
                        password.clear();
                        confirmation.clear();
                        error = null;
                      }),
              child: const Text('Use a different number')),
      ])));
}
