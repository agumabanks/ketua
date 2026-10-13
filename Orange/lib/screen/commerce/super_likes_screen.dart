import 'package:flutter/material.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'commerce_api.dart';

class SuperLikesScreen extends StatefulWidget {
  const SuperLikesScreen({super.key});
  @override
  State<SuperLikesScreen> createState() => _StarsState();
}

class _StarsState extends State<SuperLikesScreen> {
  Map<String, dynamic>? data;
  bool busy = false;
  String? error;
  final Map<int, String> keys = {};
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final r = await commerceRequest('premium/status');
      if (mounted) setState(() => data = r);
    } catch (_) {
      if (mounted) setState(() => error = 'Unable to load Super Likes.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: ColorRes.bgDark,
      appBar: AppBar(title: const Text('Get Super Likes')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const Icon(Icons.star_rounded, size: 100, color: Color(0xFFAAC8FF)),
        const Text('Show extra interest.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        const Text(
            'Stand out with a Super Like. A match always requires mutual interest.',
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(
            '${data?['data']?['super_likes_remaining'] ?? '…'} Super Likes available',
            textAlign: TextAlign.center),
        if (error != null) TextButton(onPressed: load, child: Text(error!)),
        for (final p in data?['packs'] ?? [])
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Card(
                  child: ListTile(
                      contentPadding: const EdgeInsets.all(20),
                      title: Text('${p['name']}',
                          style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.w800)),
                      subtitle: Text(
                          '${p['currency_code']} ${p['amount_minor']} total · ${p['currency_code']} ${(p['amount_minor'] / p['quantity']).round()} each'),
                      trailing: const Icon(Icons.arrow_forward_rounded),
                      onTap: busy
                          ? null
                          : () async {
                              setState(() => busy = true);
                              final id = p['id'] as int;
                              final ok = await confirmAccountPurchase(context,
                                  title: '${p['name']}',
                                  kind: 'pack',
                                  itemId: '$id',
                                  currency: p['currency_code'],
                                  amount: p['amount_minor'],
                                  idempotencyKey:
                                      keys.putIfAbsent(id, purchaseKey));
                              if (ok) {
                                keys.remove(id);
                                await load();
                              }
                              if (mounted) setState(() => busy = false);
                            })))
      ]));
}
