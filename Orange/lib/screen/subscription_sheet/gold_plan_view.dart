import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/service/subscription/subscription_manager.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/ketua_theme.dart';
import 'subscription_sheet_controller.dart';

class GoldPlanView extends StatelessWidget {
  const GoldPlanView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SubscriptionSheetController>();
    return Material(
      color: ColorRes.bgDark,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(children: [
              IconButton(tooltip: 'Close plans', onPressed: () => Get.back(), icon: const Icon(Icons.close)),
              const Spacer(),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text('KETUA', style: KetuaTheme.brandWordmark(size: 28, letterSpacing: -.8)))),
              const SizedBox(width: 10),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: const Color(0xFFE7BC43), borderRadius: BorderRadius.circular(20)),
                child: const Text('GOLD', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900))),
              const Spacer(),
            ]),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.all(24), children: [
            const Text('Make room for\nsomething real.', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, height: 1.12)),
            const SizedBox(height: 12),
            const Text('Choose your plan. Your next connection starts with you.', style: TextStyle(color: ColorRes.textSecondaryDark, fontSize: 16, height: 1.5)),
            const SizedBox(height: 28),
            const Text('Select a plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.packages.isEmpty) {
                return Container(padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: ColorRes.surfaceDark, borderRadius: BorderRadius.circular(28), border: Border.all(color: ColorRes.borderDark)),
                  child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.workspace_premium_outlined, color: Color(0xFFE7BC43), size: 36),
                    SizedBox(height: 16), Text('Plans are coming soon', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    SizedBox(height: 8), Text('Purchases are unavailable right now. You can continue using KETUA.', style: TextStyle(color: ColorRes.textSecondaryDark, height: 1.5)),
                  ]));
              }
              return SizedBox(height: 200, child: ListView.separated(scrollDirection: Axis.horizontal,
                itemCount: controller.packages.length, separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, index) {
                  final package = controller.packages[index];
                  return Obx(() {
                    final selected = controller.selectedPackage.value?.identifier == package.identifier;
                    return Semantics(selected: selected, button: true, child: InkWell(
                      borderRadius: BorderRadius.circular(28), onTap: () => controller.onSubscriptionTap(package),
                      child: AnimatedContainer(duration: const Duration(milliseconds: 180), width: 250, padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: ColorRes.surfaceDark, borderRadius: BorderRadius.circular(28), border: Border.all(color: selected ? const Color(0xFFE7BC43) : ColorRes.borderDark, width: selected ? 2 : 1)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [Expanded(child: Text(package.storeProduct.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))), if (selected) const Icon(Icons.check_circle, color: Color(0xFFE7BC43))]),
                          const Spacer(), Text(package.storeProduct.priceString, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4), const Text('Store price · recurring plan', style: TextStyle(color: ColorRes.textSecondaryDark)),
                        ]))));
                  });
                }));
            }),
            const SizedBox(height: 28),
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: ColorRes.surfaceDark, borderRadius: BorderRadius.circular(28), border: Border.all(color: ColorRes.borderDark)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('A little more possibility', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                SizedBox(height: 16), Text('Your available benefits and billing terms are shown with your store plan.', style: TextStyle(color: ColorRes.textSecondaryDark, height: 1.5)),
                SizedBox(height: 16), Row(children: [Icon(Icons.verified_user_outlined, color: Color(0xFFE7BC43)), SizedBox(width: 12), Expanded(child: Text('Identity verification is separate from Gold.', style: TextStyle(height: 1.5)))]),
              ])),
            TextButton(onPressed: () async { await SubscriptionManager.shared.restorePurchase(); }, child: const Text('Restore purchases')),
          ])),
          Container(padding: const EdgeInsets.fromLTRB(24, 16, 24, 16), decoration: const BoxDecoration(border: Border(top: BorderSide(color: ColorRes.borderDark))),
            child: Column(children: [
              const Text('Recurring billing. Manage or cancel in your store settings. Review the billing period and renewal terms before confirming.', style: TextStyle(color: ColorRes.textSecondaryDark, fontSize: 12, height: 1.5)),
              const SizedBox(height: 12),
              Obx(() => SizedBox(width: double.infinity, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE7BC43), foregroundColor: Colors.black, disabledBackgroundColor: ColorRes.surfaceDark2),
                onPressed: controller.selectedPackage.value == null ? null : () => controller.onMakePurchase(controller.selectedPackage.value),
                child: Text(controller.selectedPackage.value == null ? 'Purchases unavailable' : 'Continue · ${controller.selectedPackage.value!.storeProduct.priceString}', style: const TextStyle(fontWeight: FontWeight.w800)),
              ))),
            ])),
        ]),
      ),
    );
  }
}
