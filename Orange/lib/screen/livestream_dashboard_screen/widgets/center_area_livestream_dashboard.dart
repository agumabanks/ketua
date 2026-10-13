import 'package:flutter/material.dart';
import 'package:ketua_ui/model/setting_model.dart';
import 'package:ketua_ui/screen/livestream_dashboard_screen/livestream_dashboard_screen_view_model.dart';
import 'package:ketua_ui/utils/color_res.dart';

class CenterAreaLiveStreamDashBoard extends StatelessWidget {
  final VoidCallback onRedeemTap,
      onHistoryBtnTap,
      onRedeemBtnTap,
      onAddCoinsBtnTap,
      onApplyBtnTap;
  final int? wallet;
  final String? totalStream, totalCollection;
  final Appdata? appdata;
  final LiveStreamDashBoardViewModel model;
  const CenterAreaLiveStreamDashBoard(
      {super.key,
      required this.onRedeemTap,
      required this.onHistoryBtnTap,
      required this.onRedeemBtnTap,
      required this.onAddCoinsBtnTap,
      required this.onApplyBtnTap,
      required this.wallet,
      required this.totalStream,
      required this.totalCollection,
      this.appdata,
      required this.model});
  @override
  Widget build(BuildContext context) {
    final status = model.eligibility;
    final state = status?['application_state'] ?? 'Checking';
    return Expanded(
        child: RefreshIndicator(
            onRefresh: model.refresh,
            child: ListView(padding: const EdgeInsets.all(24), children: [
              Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF472852), Color(0xFF202536)])),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('KETUA LIVE',
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        const Text('Bring your personality to life.',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        Text('Application: $state'),
                        const SizedBox(height: 8),
                        Text(
                            '${status?['message'] ?? 'Refreshing your eligibility…'}'),
                        if (status?['can_apply'] == true)
                          Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: FilledButton.icon(
                                  onPressed: onApplyBtnTap,
                                  icon: const Icon(Icons.sensors),
                                  label: const Text('Apply to host'))),
                      ])),
              const SizedBox(height: 20),
              if (model.statusError != null)
                TextButton(
                    onPressed: model.refresh, child: Text(model.statusError!)),
              Card(
                  color: ColorRes.surfaceDark,
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your gift coins',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            Text('${wallet ?? 0}',
                                style: const TextStyle(
                                    fontSize: 32, fontWeight: FontWeight.w900)),
                            const Text(
                                'Coins and mobile-money account funds are separate. Creator payouts are not available yet.'),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                                onPressed: onAddCoinsBtnTap,
                                icon: const Icon(
                                    Icons.account_balance_wallet_outlined),
                                label: const Text('Your account')),
                          ]))),
              const SizedBox(height: 20),
              Card(
                  color: ColorRes.surfaceDark,
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${totalStream ?? '0'} streams',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w800)),
                            Text(
                                '${totalCollection ?? '0'} gift coins collected'),
                            ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.history),
                                title: const Text('Stream history'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: onHistoryBtnTap),
                            ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.receipt_long),
                                title: const Text('Previous payout requests'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: onRedeemBtnTap),
                          ]))),
            ])));
  }
}
