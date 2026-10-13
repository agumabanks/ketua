import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'commerce_api.dart';

class AccountWalletScreen extends StatefulWidget {
  final Future<Map<String, dynamic>> Function()? walletLoader;
  const AccountWalletScreen({super.key, this.walletLoader});
  @override
  State<AccountWalletScreen> createState() => _WalletState();
}

class _WalletState extends State<AccountWalletScreen> {
  Map<String, dynamic>? data;
  final amount = TextEditingController(text: '10000');
  bool busy = false;
  String? pendingOrder, pendingKey;
  final Map<int, String> packKeys = {};
  int? pendingAmount;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final r = await (widget.walletLoader?.call() ??
          commerceRequest('account/wallet'));
      if (r['status'] != true) throw StateError('Unavailable');
      if (mounted)
        setState(() {
          data = r;
          error = null;
          final pending = r['pending_orders'] as List? ?? [];
          if (pendingOrder == null && pending.isNotEmpty) {
            pendingOrder = pending.first['id'];
            pendingKey = pending.first['idempotency_key'];
            pendingAmount = pending.first['amount_minor'];
            amount.text = '$pendingAmount';
          }
        });
    } catch (_) {
      if (mounted) setState(() => error = 'Could not load your balance.');
    }
  }

  Future<void> check() async {
    if (pendingOrder == null || busy) return;
    setState(() => busy = true);
    try {
      final r = await commerceRequest('payments/status',
          body: {'order_id': pendingOrder});
      if (mounted) {
        final state = r['data']?['status'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state == 'settled'
                ? 'Payment confirmed. Account updated.'
                : '${r['message'] ?? 'Payment: ${state ?? 'pending'}'}')));
        if (state == 'settled' || state == 'failed' || state == 'reversed') {
          pendingOrder = null;
          pendingKey = null;
          pendingAmount = null;
        }
        await load();
      }
    } catch (_) {
      if (mounted)
        setState(() => error = 'Verification interrupted. Check again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> topup() async {
    if (busy) return;
    final value = int.tryParse(amount.text);
    if (value == null || value < 1000 || value > 1000000) {
      setState(() => error = 'Enter UGX 1,000–1,000,000');
      return;
    }
    if (pendingAmount != null && pendingAmount != value) {
      setState(() =>
          error = 'Check the previous payment before changing its amount.');
      return;
    }
    pendingAmount = value;
    pendingKey ??= purchaseKey();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = await commerceRequest('payments/topup', body: {
        'kind': 'topup',
        'currency_code': 'UGX',
        'amount_minor': value,
        'idempotency_key': pendingKey
      });
      if (r['status'] != true) throw StateError('${r['message']}');
      pendingOrder = r['order_id'];
      final url = Uri.tryParse('${r['checkout_url']}');
      if (url != null &&
          url.scheme == 'https' &&
          ['pay.pesapal.com', 'cybqa.pesapal.com'].contains(url.host))
        await Get.to(() => _Checkout(url: url));
    } catch (_) {
      if (mounted)
        setState(() => error =
            'Checkout unavailable. Retry safely with this same amount.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
    if (mounted && pendingOrder != null) await check();
  }

  String money(dynamic code, dynamic minor) {
    final decimals = code == 'USD' ? 2 : 0;
    return '$code ${NumberFormat.currency(symbol: '', decimalDigits: decimals).format((minor as num) / (decimals == 2 ? 100 : 1)).trim()}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: ColorRes.bgDark,
      appBar: AppBar(title: const Text('Your account')),
      body: RefreshIndicator(
          onRefresh: load,
          child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                  24, 16, 24, 24 + MediaQuery.paddingOf(context).bottom),
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
                          const Text('More ways to connect',
                              style: TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 16),
                          Text(
                              data == null
                                  ? 'Checking your balance…'
                                  : '${NumberFormat.decimalPattern().format(data!['gift_coins'] ?? 0)} gift coins',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFE7BC43))),
                          for (final w in data?['wallets'] ?? [])
                            Text(
                                '${money(w['currency_code'], w['balance_minor'])}${w['frozen'] == true || w['frozen'] == 1 ? ' · Account under review' : ''}',
                                style: const TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w800)),
                          if (data != null && (data?['wallets'] ?? []).isEmpty)
                            const Text('UGX 0',
                                style: TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w800))
                        ])),
                const SizedBox(height: 24),
                const Text('Load your account with mobile money',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                const Text(
                    'Complete payment with Pesapal. Your balance updates only after verified payment. Gift coins and account funds are separate.'),
                const SizedBox(height: 24),
                TextField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Amount in UGX')),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: !busy && data?['payments_available'] == true
                        ? topup
                        : null,
                    child: Text(
                        busy ? 'Please wait…' : 'Continue to mobile money')),
                if (pendingOrder != null)
                  TextButton(
                      onPressed: busy ? null : check,
                      child: const Text('Check payment')),
                if (error != null)
                  TextButton(
                      onPressed: busy ? null : load, child: Text(error!)),
                const SizedBox(height: 24),
                for (final p in data?['coin_packs'] ?? [])
                  ListTile(
                      title: Text(
                          '${p['name']} · ${money(p['currency_code'], p['amount_minor'])}'),
                      subtitle: Text('${p['quantity']} gift coins'),
                      onTap: busy
                          ? null
                          : () async {
                              setState(() => busy = true);
                              final ok = await confirmAccountPurchase(context,
                                  title: '${p['name']}',
                                  kind: 'pack',
                                  itemId: '${p['id']}',
                                  currency: p['currency_code'],
                                  amount: p['amount_minor'],
                                  idempotencyKey: packKeys.putIfAbsent(
                                      p['id'], purchaseKey));
                              if (ok) packKeys.remove(p['id']);
                              await load();
                              if (mounted) setState(() => busy = false);
                            }),
                const Text('Account history',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                for (final t in data?['transactions'] ?? [])
                  ListTile(
                      title: Text(
                          '${t['kind']} · ${money(t['currency_code'], t['amount_minor'])}'),
                      subtitle: Text('${t['created_at']}'))
              ])));
}

class _Checkout extends StatefulWidget {
  final Uri url;
  const _Checkout({required this.url});
  @override
  State<_Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<_Checkout> {
  late final WebViewControllerPlus controller;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    controller = WebViewControllerPlus()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) {
        if (mounted) setState(() => loading = false);
      }, onNavigationRequest: (r) {
        final u = Uri.tryParse(r.url);
        if (u?.host == 'ketua.sanaa.co' &&
            u?.path == '/api/payments/pesapal/return') {
          Navigator.pop(context);
          return NavigationDecision.prevent;
        }
        if (u?.scheme != 'https' ||
            !(u!.host == 'pesapal.com' || u.host.endsWith('.pesapal.com')))
          return NavigationDecision.prevent;
        return NavigationDecision.navigate;
      }))
      ..loadRequest(widget.url);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Secure mobile money')),
      body: Stack(children: [
        WebViewWidget(controller: controller),
        if (loading) const LinearProgressIndicator()
      ]));
}
