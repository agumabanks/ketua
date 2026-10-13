import 'dart:ui';
import 'package:get/get.dart';
import 'plans_view.dart';

import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/font_res.dart';
import 'package:ketua_ui/utils/style_res.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionSheet extends StatelessWidget {
  const SubscriptionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlansView();
  }
}

class SubscriptionBG extends StatelessWidget {
  final Widget widget;

  const SubscriptionBG({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: double.infinity,
          width: double.infinity,
          color: ColorRes.bgDark,
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorRes.ketuaAccent.withValues(alpha: .35)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 300, sigmaY: 300),
                    child: const SizedBox(
                      width: 200,
                      height: 200,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorRes.ketuaAccent2.withValues(alpha: .35)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 300, sigmaY: 300),
                    child: const SizedBox(
                      width: 200,
                      height: 200,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        widget
      ],
    );
  }
}

class SubscribeIconWithText extends StatelessWidget {
  final String title;
  final Color? color;

  const SubscribeIconWithText({super.key, required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 5,
      children: [
        Icon(
          CupertinoIcons.checkmark_alt_circle_fill,
          color: color ?? ColorRes.ketuaAccent,
          size: 20,
        ),
        Text(
          title,
          style: TextStyle(
            fontFamily: FontRes.medium,
            fontSize: 16,
            color: color ?? ColorRes.textPrimaryDark,
          ),
        )
      ],
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  final String title;
  final String price;
  final String badgeText;
  final bool isBestChoice;
  final VoidCallback onTap;
  final bool isSelected;

  const SubscriptionCard({
    super.key,
    required this.title,
    required this.price,
    this.badgeText = 'Best Choice',
    this.isBestChoice = false,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: !isBestChoice ? 70 : 85,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 70,
              width: double.infinity,
              margin: const EdgeInsets.only(top: 15),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: ShapeDecoration(
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 20,
                    cornerSmoothing: 1,
                  ),
                  side: BorderSide(
                      color: isSelected
                          ? ColorRes.ketuaAccent
                          : ColorRes.borderDark),
                ),
                color: ColorRes.surfaceDark,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: FontRes.semiBold,
                        fontSize: 20,
                        color: ColorRes.themeColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    price,
                    style: const TextStyle(
                      fontFamily: FontRes.bold,
                      fontSize: 20,
                      color: ColorRes.themeColor,
                    ),
                  )
                ],
              ),
            ),
            if (isBestChoice)
              Align(
                alignment: AlignmentDirectional.topStart,
                child: FittedBox(
                  child: Container(
                    height: 30,
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: ShapeDecoration(
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(
                          cornerRadius: 30,
                          cornerSmoothing: 1,
                        ),
                      ),
                      gradient: StyleRes.linearGradient,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        fontFamily: FontRes.semiBold,
                        fontSize: 14,
                        color: ColorRes.white,
                      ),
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class SubscribeText extends StatelessWidget {
  final String text;

  const SubscribeText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          color: ColorRes.white,
          fontSize: 16,
          fontFamily: FontRes.medium,
          letterSpacing: 1.5),
    );
  }
}

class PremiumText extends StatelessWidget {
  const PremiumText({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      S.of(context).premium.toUpperCase(),
      style: const TextStyle(
        color: ColorRes.white,
        fontSize: 50,
        fontFamily: FontRes.gilroyHeavyItalic,
      ),
    );
  }
}

class SubscribeLine extends StatelessWidget {
  const SubscribeLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1, // thickness of the line
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            ColorRes.white.withValues(alpha: 0),
            Colors.white,
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.0, .5, 1],
        ),
      ),
    );
  }
}

extension RevenueCatProduct on Package {
  SubscriptionDetail get getDetail {
    final StoreProduct product = storeProduct;

    String getTrialDescription() {
      final intro = product.introductoryPrice;
      if (intro == null) return '';
      final count = intro.periodNumberOfUnits;
      return S.current.freeTrialDescription
          .trParams({'count': '$count', 'get_period': getPeriod});
    }

    String getBilledDescription(String unitLabel, int months) {
      final trial = getTrialDescription();
      return trial.isEmpty
          ? months <= 1
              ? ''
              : S.current.subscriptionDescription.trParams(
                  {'price': calculatePrice(months), 'unit_label': unitLabel})
          : trial;
    }

    return switch (packageType) {
      PackageType.unknown || PackageType.custom => SubscriptionDetail(),
      PackageType.lifetime => SubscriptionDetail(
          title: S.current.lifetime.tr,
        ),
      PackageType.annual => SubscriptionDetail(
          title: S.current.annual.tr,
          description: getBilledDescription(S.current.annually.tr, 12)),
      PackageType.sixMonth => SubscriptionDetail(
          title: S.current.sixMonth.tr,
          description: getBilledDescription(S.current.semiAnnually.tr, 6)),
      PackageType.threeMonth => SubscriptionDetail(
          title: S.current.threeMonth.tr,
          description: getBilledDescription(S.current.threeMonths.tr, 3)),
      PackageType.twoMonth => SubscriptionDetail(
          title: S.current.twoMonth.tr,
          description: getBilledDescription(S.current.twoMonths.tr, 2)),
      PackageType.monthly => SubscriptionDetail(
          title: S.current.monthly.tr,
          description: getBilledDescription(S.current.monthly.tr, 1)),
      PackageType.weekly => SubscriptionDetail(
          title: S.current.weekly.tr, description: S.current.giveItATry.tr),
    };
  }

  String calculatePrice(int months) {
    if (months <= 1) return '';
    final perMonth = storeProduct.price / months;
    final currencySymbol = storeProduct.priceString[0];
    return '$currencySymbol${perMonth.toStringAsFixed(2)}';
  }

  String get getPeriod {
    final intro = storeProduct.introductoryPrice;
    final unit = intro?.periodUnit;
    final cycles = intro?.cycles ?? 1;

    return switch (unit) {
      PeriodUnit.day => S.current.day.tr.trPlural(S.current.days.tr, cycles),
      PeriodUnit.week => S.current.week.tr.trPlural(S.current.weeks.tr, cycles),
      PeriodUnit.month =>
        S.current.month.tr.trPlural(S.current.months.tr, cycles),
      PeriodUnit.year => S.current.year.tr.trPlural(S.current.years.tr, cycles),
      _ => '',
    };
  }
}

class SubscriptionDetail {
  String title;
  String description;

  SubscriptionDetail({this.title = '', this.description = ''});
}
