import 'dart:async';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/utils/color_res.dart';

class ProfileProgressCard extends StatefulWidget {
  final VoidCallback onEdit;
  final Future<List<Map<String, dynamic>>> Function()? loadProgress;
  final bool Function()? claimDailyNotice;
  const ProfileProgressCard(
      {super.key,
      required this.onEdit,
      this.loadProgress,
      this.claimDailyNotice});
  @override
  State<ProfileProgressCard> createState() => _ProfileProgressCardState();
}

class _ProfileProgressCardState extends State<ProfileProgressCard> {
  int? _streak;
  Timer? _streakTimer;
  bool _streakVisible = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await (widget.loadProgress?.call() ??
              Future.wait([
                Future.value(<String, dynamic>{}),
                ApiProvider().heartbeat()
              ]))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _streak = int.tryParse('${results[1]['milestones']?['streak_days']}');
      });
      // Mark only after a successful response: once per account and local day.
      if (widget.claimDailyNotice != null && _streak != null) {
        _streakVisible = widget.claimDailyNotice!();
      } else if (widget.loadProgress == null && _streak != null) {
        final now = DateTime.now();
        final today = '${now.year}-${now.month}-${now.day}';
        final key = 'streak_seen_${SessionManager.instance.getUserID()}';
        _streakVisible = SessionManager.instance.getString(key: key) != today;
        if (_streakVisible)
          SessionManager.instance.setString(key: key, value: today);
      }
      _streakTimer ??= Timer(const Duration(seconds: 30), () {
        if (mounted) setState(() => _streakVisible = false);
      });
    } catch (_) {
      // Daily celebration is optional; never leave an empty progress card.
    }
  }

  @override
  void dispose() {
    _streakTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_streakVisible || _streak == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColorRes.surfaceDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        const Icon(Icons.local_fire_department_rounded,
            color: ColorRes.ketuaAccent),
        const SizedBox(width: 10),
        Expanded(
            child: Text(
          '$_streak day streak • Next milestone: ${_streak! < 3 ? 3 : 5} days',
          style:
              const TextStyle(color: ColorRes.textSecondaryDark, fontSize: 12),
        )),
      ]),
    );
  }
}
