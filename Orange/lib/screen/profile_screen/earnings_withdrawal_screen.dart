import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ketua_ui/screen/commerce/commerce_api.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/font_res.dart';

class EarningsWithdrawalScreen extends StatefulWidget {
  const EarningsWithdrawalScreen({super.key});
  @override
  State<EarningsWithdrawalScreen> createState() => _EarningsState();
}

class _EarningsState extends State<EarningsWithdrawalScreen> {
  Map<String, dynamic>? data;
  String? error;
  bool busy = false;
  final details = TextEditingController();
  final note = TextEditingController();
  String currency = 'UGX', method = 'mobile_money';
  String key = purchaseKey();
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    details.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final r = await commerceRequest('earnings');
      if (r['status'] != true)
        throw StateError('${r['message'] ?? 'Unavailable'}');
      if (mounted)
        setState(() {
          data = Map<String, dynamic>.from(r['data']);
          error = null;
        });
    } catch (_) {
      if (mounted)
        setState(() => error = 'Could not load earnings. Pull to retry.');
    }
  }

  Future<void> submit(bool apply) async {
    if (busy) return;
    final balances = List<Map<String, dynamic>>.from(
        (data?['balances'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e)));
    final balance =
        balances.where((e) => e['currency_code'] == currency).firstOrNull;
    final amount = (balance?['available_minor'] as num? ?? 0).toInt();
    if (apply && note.text.trim().length < 10) {
      setState(() => error =
          'Tell us what you plan to earn from (at least 10 characters).');
      return;
    }
    if (!apply && (details.text.trim().length < 5 || amount <= 0)) {
      setState(() => error =
          'Enter payout details and choose a currency with available cash earnings.');
      return;
    }
    if (!apply) {
      final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
                  title: const Text('Request withdrawal'),
                  content: Text(
                      'Request ${cash(currency, amount, (balance?['decimals'] as num? ?? 0).toInt())} to your ${method == 'bank' ? 'bank' : 'mobile money'} account? This reserves your released earnings. Admin approval and external payment are required.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Request'))
                  ]));
      if (ok != true || !mounted) return;
    }
    setState(() => busy = true);
    try {
      final r =
          await commerceRequest(apply ? 'earnings/apply' : 'earnings/withdraw',
              body: apply
                  ? {'note': note.text.trim()}
                  : {
                      'request_key': key,
                      'currency_code': currency,
                      'expected_amount_minor': amount,
                      'method': method,
                      'destination': details.text.trim()
                    });
      if (r['status'] != true)
        throw StateError('${r['message'] ?? 'Request failed'}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(apply
                ? 'Application received'
                : 'Withdrawal requested. No payment sent yet.')));
        key = purchaseKey();
        details.clear();
        await load();
      }
    } catch (e) {
      if (mounted)
        setState(() => error = e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String cash(String code, num amount, int decimals) =>
      '$code ${NumberFormat.currency(symbol: '', decimalDigits: decimals).format(amount / pow10(decimals)).trim()}';
  String label(String value) =>
      {
        'not_requested': 'Ready to apply',
        'pending': 'Application under review',
        'approved': 'Approved creator',
        'suspended': 'Earning access paused',
        'requested': 'Awaiting review',
        'paid': 'Paid',
        'rejected': 'Returned to earnings'
      }[value] ??
      value;
  int pow10(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: ColorRes.bgDark,
      appBar: AppBar(title: const Text('Earnings & withdrawals')),
      body: RefreshIndicator(
          onRefresh: load,
          child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                  22, 16, 22, 24 + MediaQuery.paddingOf(context).bottom),
              children: [
                const Text('Your earnings',
                    style: TextStyle(fontFamily: FontRes.bold, fontSize: 26)),
                const SizedBox(height: 16),
                const Text(
                    'Earn from paid content and funded gifts. Your released balance is ready to request; pending earnings are still under review.'),
                if (error != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(error!,
                          style: const TextStyle(color: Colors.pinkAccent))),
                if (data == null)
                  TextButton(
                      onPressed: load, child: const Text('Load earnings')),
                if (data != null) ...[
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Earning status'),
                      subtitle: Text(label('${data!['earner_status']}'))),
                  for (final b in data!['balances'] as List)
                    Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                            title: Text(
                                '${cash('${b['currency_code']}', b['available_minor'] as num, (b['decimals'] as num).toInt())} available'),
                            subtitle: Text(
                                '${cash('${b['currency_code']}', b['pending_minor'] as num, (b['decimals'] as num).toInt())} pending review'))),
                  const SizedBox(height: 12),
                  if (data!['earner_status'] == 'not_requested') ...[
                    TextField(
                        controller: note,
                        maxLength: 500,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            labelText: 'Tell us about your creator work')),
                    FilledButton(
                        onPressed: busy ? null : () => submit(true),
                        child: const Text('Request earning status'))
                  ],
                  if (data!['withdrawals_enabled'] != true)
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                            'Withdrawals are awaiting administrator payout setup.')),
                  if (data!['earner_status'] == 'approved' &&
                      data!['withdrawals_enabled'] == true) ...[
                    const SizedBox(height: 20),
                    const Text('Withdraw released cash earnings',
                        style:
                            TextStyle(fontFamily: FontRes.bold, fontSize: 20)),
                    DropdownButtonFormField<String>(
                        initialValue: currency,
                        items: [
                          for (final b in data!['balances'] as List)
                            DropdownMenuItem(
                                value: '${b['currency_code']}',
                                child: Text('${b['currency_code']}'))
                        ],
                        onChanged:
                            busy ? null : (v) => setState(() => currency = v!)),
                    DropdownButtonFormField<String>(
                        initialValue: method,
                        items: const [
                          DropdownMenuItem(
                              value: 'mobile_money',
                              child: Text('Mobile money')),
                          DropdownMenuItem(
                              value: 'bank', child: Text('Bank account'))
                        ],
                        onChanged:
                            busy ? null : (v) => setState(() => method = v!)),
                    TextField(
                        controller: details,
                        maxLength: 500,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            labelText: 'Account name, number and provider',
                            helperText:
                                'Shared privately with the administrator for payout.')),
                    FilledButton(
                        onPressed: busy ? null : () => submit(false),
                        child: Text(busy ? 'Submitting…' : 'Review withdrawal'))
                  ],
                  const SizedBox(height: 24),
                  const Text('Withdrawal history',
                      style: TextStyle(fontFamily: FontRes.bold, fontSize: 20)),
                  if ((data!['withdrawals'] as List).isEmpty)
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child:
                            Text('Your withdrawal requests will appear here.')),
                  for (final w in data!['withdrawals'] as List)
                    Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                            title: Text(
                                '${cash('${w['currency_code']}', w['amount_minor'] as num, (data!['balances'] as List).where((b) => b['currency_code'] == w['currency_code']).firstOrNull?['decimals'] ?? (w['currency_code'] == 'USD' ? 2 : 0))} · ${label('${w['status']}')}'),
                            subtitle: Text(
                                '${w['review_note'] ?? 'Awaiting review'}${w['payment_reference'] == null ? '' : '\nReference: ${w['payment_reference']}'}'))),
                  const SizedBox(height: 16),
                  Text('${data!['message']}',
                      style: const TextStyle(color: ColorRes.textSecondaryDark))
                ]
              ])));
}
