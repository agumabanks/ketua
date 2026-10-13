import 'earnings_withdrawal_screen.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/screen/explore_screen/places_screen.dart';
import 'package:ketua_ui/screen/commerce/account_wallet_screen.dart';
import 'package:ketua_ui/screen/commerce/paid_content_screen.dart';
import 'package:ketua_ui/common/ketua_copy.dart';
import 'package:flutter/material.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/utils/color_res.dart';

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});
  @override
  State<EarnScreen> createState() => _EarnState();
}

class _EarnState extends State<EarnScreen> {
  Map<String, dynamic>? _data;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ApiProvider()
          .creatorEarn()
          .timeout(const Duration(seconds: 15));
      if (r['status'] != true) throw StateError('Unavailable');
      if (mounted)
        setState(() {
          _data = Map<String, dynamic>.from(r['data']);
          _failed = false;
        });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: ColorRes.bgDark,
      appBar: AppBar(title: Text(KetuaCopy.text(context, 'Earn'))),
      body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                  22, 16, 22, 24 + MediaQuery.paddingOf(context).bottom),
              children: [
                Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                            colors: [Color(0xFF472852), Color(0xFF202536)])),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              color: const Color(0xFFE7BC43), size: 42),
                          const SizedBox(height: 16),
                          Text(
                              KetuaCopy.text(
                                  context, 'Your personality.\nYour audience.'),
                              style: const TextStyle(
                                  fontSize: 30, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 12),
                          Text(KetuaCopy.text(context,
                              'Share moments, build meaningful connections and receive gifts from your community.'))
                        ])),
                const SizedBox(height: 22),
                ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: const Text('Earnings & withdrawals'),
                    subtitle: const Text(
                        'Apply to earn, request payout and track its status'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () =>
                        Get.to(() => const EarningsWithdrawalScreen())),
                ListTile(
                    leading: const Icon(Icons.add_business),
                    title: const Text('List a stay, date venue or spa'),
                    subtitle: const Text(
                        'Submit your place for administrator approval'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => Get.to(() => const ListingRequestScreen())),
                ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: const Text('Your account · Load with mobile money'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => Get.to(() => const AccountWalletScreen())),
                ListTile(
                    leading: const Icon(Icons.lock_open),
                    title: const Text('Creator exclusives'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => Get.to(() => const PaidContentScreen())),
                if (_data == null && !_failed)
                  const Center(child: CircularProgressIndicator()),
                if (_failed)
                  TextButton(
                      onPressed: _load,
                      child: Text(KetuaCopy.text(
                          context, 'Unable to load creator stats. Retry'))),
                if (_data != null) ...[
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(children: [
                            _stat('Gifts received',
                                '${_data!['received_gifts']}'),
                            _stat('Gift coins received',
                                '${_data!['received_coins']}'),
                            _stat('Current wallet',
                                "${_data!['wallet_coins']} ${KetuaCopy.text(context, 'coins')}")
                          ]))),
                  const SizedBox(height: 20),
                  Text(KetuaCopy.text(context, 'Creator roadmap'),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  ListTile(
                      leading: Icon(_data!['verified'] == true
                          ? Icons.verified_rounded
                          : Icons.shield_outlined),
                      title: Text(KetuaCopy.text(context, 'Verified identity')),
                      subtitle: Text(KetuaCopy.text(
                          context,
                          _data!['verified'] == true
                              ? 'Verified'
                              : 'Complete verification from profile settings'))),
                  ListTile(
                      leading: const Icon(Icons.video_library_outlined),
                      title:
                          Text(KetuaCopy.text(context, 'Share your moments')),
                      subtitle: Text(KetuaCopy.text(context,
                          'Create original short videos and grow your audience in Explore'))),
                  ListTile(
                      leading: const Icon(Icons.account_balance_outlined),
                      title: Text(
                          KetuaCopy.text(context, 'Creator cash earnings')),
                      subtitle: const Text(
                          'View Earnings & withdrawals for eligibility and requests')),
                  Text('${_data!['message']}',
                      style:
                          const TextStyle(color: ColorRes.textSecondaryDark)),
                ],
              ])));
  Widget _stat(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(child: Text(KetuaCopy.text(context, label))),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))
      ]));
}
