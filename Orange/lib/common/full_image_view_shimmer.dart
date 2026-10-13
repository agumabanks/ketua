import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ketua_ui/common/custom_image.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/const_res.dart';

class FullImageViewShimmer extends StatefulWidget {
  const FullImageViewShimmer({super.key});
  @override
  State<FullImageViewShimmer> createState() => _RadarState();
}
class _RadarState extends State<FullImageViewShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) { _pulse.stop(); } else { _pulse.repeat(); }
  }
  @override
  void dispose() { _pulse.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final user = SessionManager.instance.getUser();
    final image = user?.images?.isNotEmpty == true ? user!.images!.first.image : null;
    return Expanded(child: Container(margin: const EdgeInsets.all(17), decoration: BoxDecoration(color: ColorRes.surfaceDark, borderRadius: BorderRadius.circular(30)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(height: 250, width: 250, child: AnimatedBuilder(animation: _pulse, builder: (_, __) => Stack(alignment: Alignment.center, children: [
          for (var i = 0; i < 3; i++) Builder(builder: (_) { final t = (_pulse.value + i / 3) % 1; return Container(width: 100 + 140 * t, height: 100 + 140 * t, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ColorRes.ketuaAccent.withValues(alpha: (1-t)*.4), width: 1.5))); }),
          Transform.scale(scale: 1 + .035 * math.sin(_pulse.value * math.pi * 4), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [ColorRes.ketuaAccent, Color(0xFFC684FF)])), child: ClipOval(child: image == null ? const CircleAvatar(radius: 44, backgroundColor: ColorRes.surfaceDark2, child: Icon(Icons.person_rounded, size: 42, color: Colors.white)) : CustomImage(image: '${ConstRes.aImageBaseUrl}$image', width: 88, height: 88, showShimmer: false, cacheWidth: 240)))),
        ]))),
        const Text('Finding your next connection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        const Text('Meet. Vibe. Connect.', style: TextStyle(color: ColorRes.textSecondaryDark)),
      ])));
  }
}
