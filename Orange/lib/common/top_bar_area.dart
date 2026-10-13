import 'package:flutter/material.dart';
import 'package:ketua_ui/common/button/round_icon_button.dart';
import 'package:ketua_ui/common/custom_border.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/font_res.dart';

class TopBarArea extends StatelessWidget {
  final String? title;
  final String? title2;

  const TopBarArea({super.key, this.title, this.title2});

  @override
  Widget build(BuildContext context) {
    final background = Scaffold.maybeOf(context)?.widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    final textColor = ThemeData.estimateBrightnessForColor(background) == Brightness.dark ? ColorRes.textPrimaryDark : ColorRes.black;
    return SafeArea(
      bottom: false,
      minimum: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          spacing: 10,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10,
              children: [
                const RoundIconButton(),
                Flexible(
                  child: RichText(
                    text: TextSpan(
                      text: title ?? '',
                      style: TextStyle(
                        fontSize: 17,
                        color: textColor,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: ' ${title2 ?? ' '}',
                          style: TextStyle(
                            fontSize: 17,
                            color: textColor,
                            fontFamily: FontRes.bold,
                          ),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 37),
              ],
            ),
            const CustomBorder(
              color: ColorRes.grey5,
            )
          ],
        ),
      ),
    );
  }
}
