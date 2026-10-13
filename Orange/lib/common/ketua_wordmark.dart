import 'package:flutter/material.dart';

import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/font_res.dart';
import 'package:ketua_ui/utils/ketua_theme.dart';

/// Reusable KETUA brand wordmark.
///
/// Renders "KETUA" UPPERCASE with a real font weight of 900 (gilroy_heavy) and
/// tight tracking. When [gradient] is true it uses the brand gradient fill.
class KetuaWordmark extends StatelessWidget {
  final double size;
  final bool gradient;
  final Color color;
  final double letterSpacing;

  const KetuaWordmark({
    super.key,
    this.size = 32,
    this.gradient = true,
    this.color = ColorRes.textPrimaryDark,
    this.letterSpacing = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      KetuaTheme.brandName, // "KETUA" — uppercase, weight 900
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: FontRes.heavy,
        fontWeight: FontWeight.w900,
        fontSize: size,
        height: 1.0,
        letterSpacing: letterSpacing,
        color: color,
      ),
    );

    if (!gradient) return text;

    return ShaderMask(
      shaderCallback: (bounds) => KetuaTheme.brandGradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: text,
    );
  }
}
