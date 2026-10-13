import 'package:flutter/material.dart';
import 'commerce_api.dart';
import 'package:ketua_ui/utils/color_res.dart';

class PremiumSettingsScreen extends StatefulWidget {
  const PremiumSettingsScreen({super.key});
  @override
  State<PremiumSettingsScreen> createState() => _ControlsState();
}

class _ControlsState extends State<PremiumSettingsScreen> {
  Map<String, dynamic>? data;
  String? error;
  bool busy = false;
  final country = TextEditingController();
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    country.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final r = await commerceRequest('premium/status');
      if (mounted)
        setState(() {
          data = r['data'];
          country.text = data?['settings']?['passport_country'] ?? '';
        });
    } catch (_) {
      if (mounted) setState(() => error = 'Unable to load controls.');
    }
  }

  Future<void> save(Map<String, dynamic> values) async {
    setState(() => busy = true);
    try {
      final r = await commerceRequest('premium/settings', body: values);
      if (mounted)
        setState(() {
          if (r['status'] == true)
            data = r['data'];
          else
            error = '${r['message']}';
        });
    } catch (_) {
      if (mounted) setState(() => error = 'Unable to save controls.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: ColorRes.bgDark,
      appBar: AppBar(title: const Text('Premium controls')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const Text('Connect on your terms.',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        if (data?['plan'] == 'free')
          const Text('Upgrade to Gold or Pro to unlock these controls.'),
        if (error != null) Text(error!),
        for (final entry in {
          'hide_ads': 'Hide ads',
          'hide_age': 'Hide age',
          'hide_distance': 'Hide distance',
          'incognito': 'Only people I like can discover me'
        }.entries)
          SwitchListTile(
              title: Text(entry.value),
              value: data?['settings']?[entry.key] == true,
              onChanged: busy || data == null || data?['plan'] == 'free'
                  ? null
                  : (v) => save({entry.key: v})),
        const SizedBox(height: 24),
        const Text('Worldwide discovery',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const Text(
            'Choose a country to discover people there. This never changes your GPS location or the distance shown to other people.'),
        TextField(
            controller: country,
            decoration: const InputDecoration(
                labelText: 'Country name (blank for everywhere)')),
        FilledButton(
            onPressed: busy || data?['plan'] == 'free'
                ? null
                : () => save({
                      'passport_country': country.text.trim().isEmpty
                          ? null
                          : country.text.trim()
                    }),
            child: const Text('Save discovery country'))
      ]));
}
