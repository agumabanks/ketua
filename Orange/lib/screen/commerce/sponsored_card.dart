import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'commerce_api.dart';

class SponsoredCard extends StatelessWidget {
  final Map<String, dynamic> ad;
  const SponsoredCard({super.key, required this.ad});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          color: ColorRes.surfaceDark, borderRadius: BorderRadius.circular(28)),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Icon(Icons.campaign_outlined),
                  const SizedBox(width: 8),
                  const Text('Sponsored',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Expanded(
                      child: Text('${ad['title']}',
                          maxLines: 1, overflow: TextOverflow.ellipsis))
                ])),
            Flexible(
                fit: FlexFit.loose,
                child: Image.network('${ad['image_url']}',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox(
                        height: 140,
                        child: Center(
                            child: Icon(Icons.campaign_rounded, size: 50))))),
            Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${ad['description']}'),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: () async {
                            final u = Uri.tryParse('${ad['target_url']}');
                            if (u?.scheme == 'https')
                              await launchUrl(u!,
                                  mode: LaunchMode.externalApplication);
                          },
                          child: const Text('Learn more'))
                    ]))
          ]));
}

class CommunityAds extends StatefulWidget {
  const CommunityAds({super.key});
  @override
  State<CommunityAds> createState() => _AdsState();
}

class _AdsState extends State<CommunityAds> {
  List<Map<String, dynamic>> ads = [];
  @override
  void initState() {
    super.initState();
    commerceRequest('ads?placement=feed').then((r) {
      if (mounted)
        setState(() => ads = List<Map<String, dynamic>>.from(r['data'] ?? []));
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) =>
      Column(children: [for (final a in ads.take(2)) SponsoredCard(ad: a)]);
}
