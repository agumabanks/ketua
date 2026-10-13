import 'package:flutter/material.dart';
import 'package:ketua_ui/common/custom_image.dart';
import 'package:ketua_ui/model/setting_model.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/const_res.dart';
class AnimatedGiftCard extends StatefulWidget {
  final Gifts gift;
  final VoidCallback onTap;
  const AnimatedGiftCard({super.key, required this.gift, required this.onTap});
  @override
  State<AnimatedGiftCard> createState() => _GiftCardState();
}
class _GiftCardState extends State<AnimatedGiftCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  @override
  void didChangeDependencies() { super.didChangeDependencies(); if (MediaQuery.disableAnimationsOf(context)) { _controller.stop(); } else { _controller.repeat(reverse: true); } }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Material(color: ColorRes.surfaceDark2, borderRadius: BorderRadius.circular(24), child: InkWell(onTap: widget.onTap, borderRadius: BorderRadius.circular(24), child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
    Expanded(child: AnimatedBuilder(animation: _controller, builder: (_, child) => Transform.translate(offset: Offset(0, -5 * _controller.value), child: child), child: widget.gift.image?.isNotEmpty == true ? CustomImage(image: '${ConstRes.aImageBaseUrl}${widget.gift.image}', width: 75, height: 75, showShimmer: false, cacheWidth: 240) : const Icon(Icons.card_giftcard_rounded, size: 52, color: ColorRes.ketuaAccent))),
    Text(widget.gift.name ?? 'Gift', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
    const SizedBox(height: 5), Text('${widget.gift.coinPrice} coins', style: const TextStyle(color: Color(0xFFE7BC43))),
  ]))));
}
