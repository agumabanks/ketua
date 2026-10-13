import 'package:flutter/material.dart';
import 'package:ketua_ui/common/ketua_copy.dart';
import 'package:ketua_ui/utils/color_res.dart';

class UpdatesEmpty extends StatelessWidget {
  final bool platform;
  const UpdatesEmpty({super.key, this.platform = false});
  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
        children: [
          Center(
              child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorRes.ketuaAccent.withValues(alpha: .10)),
                  child: const Icon(Icons.notifications_none_rounded,
                      size: 32, color: ColorRes.ketuaAccent))),
          const SizedBox(height: 24),
          Text(KetuaCopy.text(context, 'No updates yet'),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(
              KetuaCopy.text(
                  context,
                  platform
                      ? 'KETUA announcements will appear here.'
                      : 'Your likes, matches and booking updates will appear here.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: ColorRes.textSecondaryDark, height: 1.5)),
        ],
      );
}
