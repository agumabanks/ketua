import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/utils/const_res.dart';
import 'account_wallet_screen.dart';

final premiumAdsHidden = ValueNotifier<bool>(true);
String purchaseKey() {
  final r = Random.secure();
  final b = List.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 15) | 64;
  b[8] = (b[8] & 63) | 128;
  final h = b.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

Future<Map<String, dynamic>> commerceRequest(String path,
    {Map<String, dynamic>? body}) async {
  final uri = Uri.parse('${ConstRes.aBaseUrl}$path');
  final headers = ApiProvider().authHeaders()
    ..['Content-Type'] = 'application/json';
  final r = await (body == null
          ? http.get(uri, headers: headers)
          : http.post(uri, headers: headers, body: jsonEncode(body)))
      .timeout(const Duration(seconds: 35));
  final data = jsonDecode(r.body);
  if (data is! Map<String, dynamic>) throw StateError('Invalid response');
  if ((path == 'premium/status' || path == 'premium/settings') && data['status'] == true)
    premiumAdsHidden.value = data['data']?['hide_ads'] == true;
  if(path=='commerce/purchase' && data['status']==true) unawaited(commerceRequest('premium/status').catchError((_) => <String,dynamic>{}));
  return data;
}

Future<bool> confirmAccountPurchase(BuildContext context,
    {required String title,
    required String kind,
    required String itemId,
    required String currency,
    required int amount,
    int? periodDays,
    String? idempotencyKey}) async {
  final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
              title: Text(title),
              content: Text(
                  'Pay $currency ${currency == 'USD' ? (amount / 100).toStringAsFixed(2) : amount} from your account balance${periodDays == null ? '' : ' for $periodDays days'}. This is a one-time purchase.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Confirm purchase'))
              ]));
  if (yes != true) return false;
  try {
    final r = await commerceRequest('commerce/purchase', body: {
      'kind': kind,
      'item_id': itemId,
      'currency_code': currency,
      'expected_amount_minor': amount,
      'idempotency_key': idempotencyKey ?? purchaseKey(),
      if (periodDays != null) 'period_days': periodDays
    });
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${r['message'] ?? 'Purchase unavailable'}')));
    if (r['status'] != true && '${r['message']}'.contains('balance'))
      await Get.to(() => const AccountWalletScreen());
    return r['status'] == true;
  } catch (_) {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Connection interrupted. Check your account history before retrying.')));
    return false;
  }
}
