import 'package:flutter/material.dart';
import 'package:ketua_ui/utils/asset_res.dart';
import 'package:ketua_ui/utils/color_res.dart';

class LiveIcon extends StatelessWidget {
  const LiveIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AssetRes.icLive,
      color: ColorRes.themeColor,
    );
  }
}
