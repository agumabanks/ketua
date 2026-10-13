import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/utils/const_res.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'commerce_api.dart';

class PaidContentScreen extends StatefulWidget {
  const PaidContentScreen({super.key});
  @override
  State<PaidContentScreen> createState() => _ContentState();
}

class _ContentState extends State<PaidContentScreen> {
  List<Map<String, dynamic>>? items;
  String? error;
  bool busy = false;
  final Map<int, String> keys = {};
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final r = await commerceRequest('premium/content');
      if (r['status'] != true) throw StateError('Unavailable');
      if (mounted)
        setState(() {
          items = List<Map<String, dynamic>>.from(r['data'] ?? []);
          error = null;
        });
    } catch (_) {
      if (mounted) setState(() => error = 'Unable to load content.');
    }
  }

  Future<void> open(Map<String, dynamic> p) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      if (p['unlocked'] != true) {
        final ok = await confirmAccountPurchase(context,
            title: 'Unlock · ${p['title']}',
            kind: 'content',
            itemId: '${p['id']}',
            currency: p['currency_code'],
            amount: p['amount_minor'],
            idempotencyKey: keys.putIfAbsent(p['id'], purchaseKey));
        if (!ok) return;
        keys.remove(p['id']);
        await load();
      }
      final r = await http
          .get(
              Uri.parse('${ConstRes.aBaseUrl}premium/content/${p['id']}/media'),
              headers: ApiProvider().authHeaders())
          .timeout(const Duration(seconds: 30));
      if (r.statusCode != 200 || r.bodyBytes.length > 26 * 1024 * 1024)
        throw StateError('Unavailable');
      if (!mounted) return;
      if ('${p['mime']}'.startsWith('image/'))
        await Get.to(() => Scaffold(
            appBar: AppBar(title: Text(p['title'])),
            body: Center(
                child: InteractiveViewer(child: Image.memory(r.bodyBytes)))));
      else {
        final dir = await getTemporaryDirectory();
        final f = File('${dir.path}/ketua_private_${purchaseKey()}.mp4');
        await f.writeAsBytes(r.bodyBytes);
        try {
          await Get.to(() => _PrivateVideo(file: f, title: p['title']));
        } finally {
          if (await f.exists()) await f.delete();
        }
      }
    } catch (_) {
      if (mounted)
        setState(() =>
            error = 'Content could not be opened. Your purchase is retained.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: ColorRes.bgDark,
      appBar: AppBar(title: const Text('Creator exclusives')),
      body: RefreshIndicator(
          onRefresh: load,
          child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, 24 + MediaQuery.paddingOf(context).bottom),
              children: [
                const Text('A closer look at their world.',
                    style: TextStyle(
                        fontSize: 26,
                        height: 1.2,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                if (items == null && error == null)
                  const Center(child: CircularProgressIndicator()),
                if (error != null)
                  TextButton(onPressed: load, child: Text(error!)),
                if (items?.isEmpty == true)
                  const Text('Creator exclusives will appear here.'),
                for (final p in items ?? [])
                  Card(
                      margin: const EdgeInsets.only(top: 16),
                      child: ListTile(
                          contentPadding: const EdgeInsets.all(20),
                          leading: Icon(
                              p['unlocked'] == true
                                  ? Icons.lock_open
                                  : Icons.lock_outline,
                              color: const Color(0xFFE7BC43)),
                          title: Text('${p['title']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(
                              '${p['description']}\n${NumberFormat.currency(symbol: '${p['currency_code']} ', decimalDigits: p['currency_code'] == 'USD' ? 2 : 0).format((p['amount_minor'] as num) / (p['currency_code'] == 'USD' ? 100 : 1))} · ${p['unlocked'] == true ? 'Unlocked' : 'One-time access'}'),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: busy ? null : () => open(p)))
              ])));
}

class _PrivateVideo extends StatefulWidget {
  final File file;
  final String title;
  const _PrivateVideo({required this.file, required this.title});
  @override
  State<_PrivateVideo> createState() => _PrivateVideoState();
}

class _PrivateVideoState extends State<_PrivateVideo> {
  late final VideoPlayerController c;
  @override
  void initState() {
    super.initState();
    c = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
          child: c.value.isInitialized
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  AspectRatio(
                      aspectRatio: c.value.aspectRatio, child: VideoPlayer(c)),
                  IconButton(
                      onPressed: () {
                        setState(
                            () => c.value.isPlaying ? c.pause() : c.play());
                      },
                      icon: Icon(
                          c.value.isPlaying ? Icons.pause : Icons.play_arrow))
                ])
              : const CircularProgressIndicator()));
}
