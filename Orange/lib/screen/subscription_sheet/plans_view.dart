import 'package:ketua_ui/utils/font_res.dart';
import 'package:ketua_ui/screen/commerce/commerce_api.dart';
import 'package:ketua_ui/screen/commerce/super_likes_screen.dart';
import 'package:ketua_ui/screen/commerce/account_wallet_screen.dart';
import 'package:ketua_ui/screen/commerce/premium_settings_screen.dart';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/common/ketua_copy.dart';
import 'package:ketua_ui/common/ketua_wordmark.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/service/subscription/subscription_manager.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/const_res.dart';

class PlansView extends StatefulWidget {
  const PlansView({super.key});
  @override
  State<PlansView> createState() => _PlansViewState();
}

class _PlansViewState extends State<PlansView> {
  Map<String, dynamic>? catalog;
  String currency = 'UGX';
  String selected = 'gold';
  int periodDays = 30;
  bool buying = false;
  final Map<String, String> purchaseKeys = {};
  bool failed = false;
  bool restoring = false;
  String? currentPlan;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      failed = false;
    });
    try {
      final r = await http
          .get(Uri.parse('${ConstRes.aBaseUrl}catalog'),
              headers: ApiProvider().authHeaders())
          .timeout(const Duration(seconds: 15));
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      if (r.statusCode != 200 || body['status'] != true)
        throw StateError('Catalog unavailable');
      final statusResponse = await http
          .post(Uri.parse('${ConstRes.aBaseUrl}subscription/status'),
              headers: ApiProvider().authHeaders())
          .timeout(const Duration(seconds: 10));
      final status = jsonDecode(statusResponse.body);
      if (statusResponse.statusCode == 200 && status['status'] == true)
        currentPlan = status['active'] == true ? '${status['plan']}' : 'free';
      final saved = SessionManager.instance.getString(key: 'currency');
      final available =
          (body['currencies'] as List).map((v) => v['code']).toList();
      if (mounted)
        setState(() {
          catalog = body;
          currency =
              available.contains(saved) ? saved! : body['default_currency'];
        });
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  String t(String key) => KetuaCopy.text(context, key);
  @override
  Widget build(BuildContext context) {
    final plans = List<dynamic>.from(catalog?['plans'] as List? ?? [])
      ..sort((a, b) => ['gold', 'pro', 'free']
          .indexOf(a['code'])
          .compareTo(['gold', 'pro', 'free'].indexOf(b['code'])));
    final currencies = (catalog?['currencies'] as List?) ?? [];
    final plan = plans.where((v) => v['code'] == selected).firstOrNull;
    final selectedPrice = (plan?['prices'] as List? ?? [])
        .where((p) =>
            p['currency_code'] == currency && p['period_days'] == periodDays)
        .firstOrNull;
    return Material(
        color: ColorRes.bgDark,
        child: SafeArea(
            child: Column(children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                IconButton(
                    onPressed: () => Get.back(),
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: const Icon(Icons.close)),
                const Expanded(child: Center(child: KetuaWordmark(size: 30))),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                        color: selected == 'gold'
                            ? const Color(0xFFE7BC43)
                            : ColorRes.surfaceDark2,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(selected.toUpperCase(),
                        style: TextStyle(
                            color: selected == 'gold'
                                ? Colors.black
                                : Colors.white,
                            fontFamily: FontRes.bold,
                            fontWeight: FontWeight.w800))),
              ])),
          Expanded(
              child: ListView(padding: const EdgeInsets.all(24), children: [
            Text(
                t(selected == 'gold'
                    ? 'See who likes you. Connect with Gold.'
                    : selected == 'pro'
                        ? 'Make more room for connection.'
                        : 'Meet. Vibe. Connect.'),
                style: const TextStyle(
                    fontSize: 34,
                    fontFamily: FontRes.bold,
                    fontWeight: FontWeight.w800,
                    height: 1.15)),
            const SizedBox(height: 12),
            if (currentPlan != null)
              Text('${t('Current plan')}: ${currentPlan!.toUpperCase()}',
                  style: const TextStyle(color: ColorRes.textSecondaryDark)),
            const SizedBox(height: 24),
            if (failed) ...[
              Text(t('Unable to load plans')),
              TextButton(onPressed: load, child: Text(t('Retry')))
            ] else if (catalog == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              DropdownButtonFormField<String>(
                  initialValue: currency,
                  decoration: InputDecoration(labelText: t('Currency')),
                  items: currencies
                      .map((c) => DropdownMenuItem<String>(
                          value: c['code'],
                          child: Text('${c['code']} · ${c['name']}')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => currency = v);
                      SessionManager.instance
                          .setString(key: 'currency', value: v);
                    }
                  }),
              const SizedBox(height: 16),
              Wrap(spacing: 8, children: [
                for (final days in [7, 30, 90])
                  ChoiceChip(
                      label: Text(days == 7
                          ? '1 week'
                          : days == 30
                              ? '1 month'
                              : '3 months'),
                      selected: periodDays == days,
                      onSelected: (_) => setState(() => periodDays = days))
              ]),
              const SizedBox(height: 24),
              SizedBox(
                  height: 240,
                  child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: plans.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, i) {
                        final p = plans[i];
                        final picked = p['code'] == selected;
                        final price = (p['prices'] as List)
                            .where((v) =>
                                v['currency_code'] == currency &&
                                v['period_days'] == periodDays)
                            .firstOrNull;
                        final amount = price?['amount_minor'];
                        final decimal = currencies.firstWhere(
                            (c) => c['code'] == currency)['decimals'] as int;
                        final formatted = p['code'] == 'free'
                            ? t('Free')
                            : amount == null
                                ? t('Price not set')
                                : NumberFormat.currency(
                                        locale: Localizations.localeOf(context)
                                            .toString(),
                                        name: currency,
                                        symbol: currency,
                                        decimalDigits: decimal)
                                    .format((amount as num) /
                                        _power(decimal) /
                                        (periodDays == 30
                                            ? 4
                                            : periodDays == 90
                                                ? 12
                                                : 1));
                        return Semantics(
                            selected: picked,
                            button: true,
                            child: InkWell(
                                borderRadius: BorderRadius.circular(28),
                                onTap: () =>
                                    setState(() => selected = p['code']),
                                child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 230,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                        color: ColorRes.surfaceDark,
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(
                                            color: picked
                                                ? const Color(0xFFE7BC43)
                                                : ColorRes.borderDark,
                                            width: picked ? 2 : 1)),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Expanded(
                                                child: Text(t(p['name']),
                                                    style: const TextStyle(
                                                        fontSize: 30,
                                                        fontWeight:
                                                            FontWeight.w900))),
                                            if (picked)
                                              const Icon(Icons.check_circle,
                                                  color: Color(0xFFE7BC43))
                                          ]),
                                          const Spacer(),
                                          Text(formatted,
                                              style: const TextStyle(
                                                  fontSize: 24,
                                                  fontFamily: FontRes.bold,
                                                  fontWeight: FontWeight.w800)),
                                          if (amount != null &&
                                              p['code'] != 'free')
                                            Text(
                                                '$currency ${(amount / _power(decimal)).toStringAsFixed(decimal)} total · ${periodDays == 7 ? 'weekly' : periodDays == 30 ? 'monthly' : '3 months'}',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: ColorRes
                                                        .textSecondaryDark)),
                                          Text(t('per week'),
                                              style: const TextStyle(
                                                  color: ColorRes
                                                      .textSecondaryDark)),
                                        ]))));
                      })),
              const SizedBox(height: 24),
              Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: ColorRes.surfaceDark,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: ColorRes.borderDark)),
                  child: Column(children: [
                    for (final feature in (plan?['features'] as List?) ?? [])
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.check_rounded),
                          title: Text(t({
                                'matching': 'Matching',
                                'chat': 'Chat',
                                'report_block': 'Report and block',
                                'see_likes': 'See who likes you',
                                'priority_visibility': 'Priority discovery'
                              }[feature] ??
                              feature))),
                  ])),
              const SizedBox(height: 20),
              Text(
                  'Weekly equivalent is based on 4 weeks per monthly package and 12 weeks per 3-month package. You pay the displayed total once for the selected access period.',
                  style: const TextStyle(
                      color: ColorRes.textSecondaryDark, height: 1.5)),
            ],
            const SizedBox(height: 20),
            Wrap(alignment: WrapAlignment.center, children: [
              TextButton(
                  onPressed: () => Get.to(() => const SuperLikesScreen()),
                  child: const Text('Get Super Likes')),
              TextButton(
                  onPressed: () => Get.to(() => const AccountWalletScreen()),
                  child: const Text('Load account')),
              TextButton(
                  onPressed: () => Get.to(() => const PremiumSettingsScreen()),
                  child: const Text('Premium controls'))
            ]),
            TextButton(
                onPressed: isPurchaseConfig && !restoring
                    ? () async {
                        setState(() => restoring = true);
                        try {
                          await SubscriptionManager.shared.restorePurchase();
                        } finally {
                          if (mounted) setState(() => restoring = false);
                        }
                      }
                    : null,
                child: Text(t('Restore purchases'))),
          ])),
          Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: selected == 'free' ||
                                selectedPrice?['amount_minor'] == null ||
                                buying
                            ? null
                            : () async {
                                setState(() => buying = true);
                                final key = '$selected:$currency:$periodDays';
                                final ok = await confirmAccountPurchase(context,
                                    title: 'KETUA ${selected.toUpperCase()}',
                                    kind: 'plan',
                                    itemId: selected,
                                    currency: currency,
                                    amount: selectedPrice!['amount_minor'],
                                    periodDays: periodDays,
                                    idempotencyKey: purchaseKeys.putIfAbsent(
                                        key, purchaseKey));
                                if (ok) {
                                  purchaseKeys.remove(key);
                                  await load();
                                }
                                if (mounted) setState(() => buying = false);
                              },
                        child: Text(buying
                            ? 'Please wait…'
                            : selected == 'free'
                                ? t('Your current plan')
                                : selectedPrice?['amount_minor'] == null
                                    ? t('Price not set')
                                    : 'Choose ${selected.toUpperCase()}'))),
              ])),
        ])));
  }

  num _power(int decimal) {
    num n = 1;
    for (var i = 0; i < decimal; i++) {
      n *= 10;
    }
    return n;
  }
}
