import 'package:flutter/material.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/common/common_fun.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ketua_ui/screen/commerce/commerce_api.dart';
import 'package:ketua_ui/utils/color_res.dart';

const placeCategories = {
  'date': 'Dating',
  'stay': 'AirStay',
  'spa': 'Massage & spa'
};
String placeMoney(num amount, String currency) => NumberFormat.currency(
        symbol: '$currency ', decimalDigits: currency == 'UGX' ? 0 : 2)
    .format(currency == 'UGX' ? amount : amount / 100);

class PlacesScreen extends StatefulWidget {
  final String category;
  const PlacesScreen({super.key, required this.category});
  @override
  State<PlacesScreen> createState() => _PlacesState();
}

class _PlacesState extends State<PlacesScreen> {
  final min = TextEditingController(),
      max = TextEditingController(),
      district = TextEditingController();
  List<dynamic> items = [];
  bool busy = false;
  bool restored = false;
  String? error;
  @override
  void initState() {
    super.initState();
    restore();
  }

  Future<void> restore() async {
    final cached =
        await SessionManager.instance.readSnapshot('places_${widget.category}');
    if (!mounted) return;
    if (cached != null)
      setState(() {
        items = cached['data'] ?? [];
        restored = true;
      });
    await load();
  }

  @override
  void dispose() {
    min.dispose();
    max.dispose();
    district.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (busy) return;
    final lower = int.tryParse(min.text), upper = int.tryParse(max.text);
    if ((min.text.isNotEmpty && lower == null) ||
        (max.text.isNotEmpty && upper == null) ||
        (lower != null && upper != null && lower > upper)) {
      setState(() => error = 'Enter a valid budget range.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    final owner = SessionManager.instance.getUserID();
    try {
      final q = Uri(queryParameters: {
        'category': widget.category,
        'currency': 'UGX',
        if (lower != null) 'budget_min': '$lower',
        if (upper != null) 'budget_max': '$upper',
        if (district.text.trim().isNotEmpty) 'district': district.text.trim()
      }).query;
      final r = await commerceRequest('places?$q');
      if (!mounted || owner != SessionManager.instance.getUserID()) return;
      if (r['status'] != true) throw StateError('Unavailable');
      if (mounted)
        setState(() {
          items = r['data'] ?? [];
          restored = false;
        });
      if (min.text.isEmpty && max.text.isEmpty && district.text.isEmpty)
        await SessionManager.instance.writeSnapshot(
            'places_${widget.category}', {'data': r['data'] ?? []});
    } catch (_) {
      if (mounted)
        setState(() => error = 'Unable to load places. Your filters are kept.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: ColorRes.bgDark,
      appBar: AppBar(title: Text(placeCategories[widget.category]!)),
      body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, 24 + MediaQuery.paddingOf(context).bottom),
          children: [
            Text(
                widget.category == 'date'
                    ? 'A date within your budget.'
                    : widget.category == 'stay'
                        ? 'A night away. Or a week.'
                        : 'Make time to unwind.',
                style: const TextStyle(
                    fontSize: 26, height: 1.2, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const Text(
                'Choose a place, check availability, send a request. Confirmation comes from the venue. Budget is per person, night or session.',
                style: TextStyle(color: ColorRes.textSecondaryDark)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: min,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'From · UGX'))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                      controller: max,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'To · UGX')))
            ]),
            const SizedBox(height: 16),
            TextField(
                controller: district,
                decoration:
                    const InputDecoration(labelText: 'District (optional)')),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: busy ? null : load,
                icon: const Icon(Icons.search),
                label: const Text('Find places')),
            const SizedBox(height: 16),
            if (busy) const LinearProgressIndicator(),
            if ((busy || error != null) && items.isNotEmpty && !restored)
              const Text(
                  'Showing previous results while your search refreshes.',
                  style: TextStyle(color: ColorRes.textSecondaryDark)),
            if (restored)
              const Text(
                  'Saved places · availability is checked when you open a listing.',
                  style: TextStyle(color: ColorRes.textSecondaryDark)),
            if (error != null) TextButton(onPressed: load, child: Text(error!)),
            if (!busy && error == null && items.isEmpty)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(children: [
                    const Icon(Icons.travel_explore, size: 50),
                    const SizedBox(height: 12),
                    const Text('No places available for this search yet.'),
                    TextButton(
                        onPressed: () =>
                            Get.to(() => const ListingRequestScreen()),
                        child: const Text('Have a place? Submit it for review'))
                  ])),
            for (final p in items)
              Card(
                  margin: const EdgeInsets.only(top: 16),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  child: InkWell(
                      onTap: () => Get.to(() => PlaceDetailScreen(
                          place: Map<String, dynamic>.from(p))),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (p['image_url'] != null)
                              Image.network(p['image_url'],
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                      height: 60,
                                      child: Center(
                                          child: Icon(Icons.landscape)))),
                            Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 16),
                                      Text(p['title'],
                                          style: const TextStyle(
                                              fontSize: 23,
                                              fontWeight: FontWeight.w800)),
                                      Text('${p['town']} · ${p['district']}'),
                                      const SizedBox(height: 8),
                                      Text(
                                          '${placeMoney(p['price_min'], p['currency_code'])} – ${placeMoney(p['price_max'], p['currency_code'])} / ${p['price_unit']}'),
                                      Text(p['includes'],
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color:
                                                  ColorRes.textSecondaryDark)),
                                      const SizedBox(height: 10),
                                      const Text('View place & availability →')
                                    ]))
                          ]))),
          ]));
}

class PlaceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> place;
  const PlaceDetailScreen({super.key, required this.place});
  @override
  State<PlaceDetailScreen> createState() => _DetailState();
}

class _DetailState extends State<PlaceDetailScreen> {
  late Map<String, dynamic> currentPlace;
  List<dynamic> slots = [];
  final Set<int> picked = {};
  int quantity = 1;
  bool loading = true, busy = false;
  String? error;
  final key = purchaseKey();
  @override
  void initState() {
    super.initState();
    currentPlace = Map<String, dynamic>.from(widget.place);
    load();
  }

  Future<void> load() async {
    try {
      final r = await commerceRequest('places/${widget.place['id']}/slots');
      if (r['status'] != true) throw StateError('Unavailable');
      if (mounted)
        setState(() {
          slots = r['data'] ?? [];
          picked.removeWhere(
              (id) => !slots.any((s) => s['id'] == id && s['remaining'] > 0));
          if (r['listing'] is Map)
            currentPlace = Map<String, dynamic>.from(r['listing']);
          error = null;
        });
    } catch (_) {
      if (mounted) setState(() => error = 'Unable to load availability.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  num get total => slots
      .where((s) => picked.contains(s['id']))
      .fold<num>(0, (sum, s) => sum + s['amount_minor'] * quantity);
  Future<void> reserve() async {
    if (busy || loading || error != null || picked.isEmpty) return;
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Request reservation?'),
                content: Text(
                    '${currentPlace['title']}\n${placeMoney(total, currentPlace['currency_code'])} total for $quantity ${currentPlace['price_unit']}(s).\n\nNo payment is taken. Wait for venue confirmation before traveling.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Back')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Send request'))
                ]));
    if (ok != true || !mounted) return;
    setState(() => busy = true);
    try {
      final r = await commerceRequest('reservations/request', body: {
        'listing_id': widget.place['id'],
        'slot_ids': picked.toList()..sort(),
        'quantity': quantity,
        'request_key': key
      });
      if (!mounted) return;
      if (r['status'] == true) {
        Get.off(() => const ReservationsScreen());
      } else
        setState(() => error = r['message'] ?? 'Unable to reserve.');
    } catch (_) {
      if (mounted)
        setState(() => error =
            'Unable to send request. Retry safely with the same selection.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = currentPlace;
    return Scaffold(
        backgroundColor: ColorRes.bgDark,
        appBar: AppBar(title: Text(p['title'])),
        body: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, 24 + MediaQuery.paddingOf(context).bottom),
            children: [
              if (p['image_url'] != null)
                ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(p['image_url'],
                        height: 210,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox())),
              const SizedBox(height: 16),
              Text(p['title'],
                  style: const TextStyle(
                      fontSize: 26, height: 1.2, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('${p['address']} · ${p['town']}, ${p['district']}'),
              TextButton.icon(
                  onPressed: () => launchUrl(
                      Uri.https('www.google.com', '/maps/search/', {
                        'api': '1',
                        'query': '${p['latitude']},${p['longitude']}'
                      }),
                      mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('View on map')),
              const SizedBox(height: 12),
              Text(p['description'], style: const TextStyle(height: 1.5)),
              const SizedBox(height: 20),
              const Text('What’s included',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(p['includes'], style: const TextStyle(height: 1.5)),
              const SizedBox(height: 20),
              Text(
                  p['category'] == 'stay'
                      ? 'Choose 1–7 consecutive nights'
                      : 'Choose a time',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              if (loading) const LinearProgressIndicator(),
              if (!loading && error == null && slots.isEmpty)
                const Text('No availability published yet. Check back soon.'),
              for (final s in slots)
                CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: picked.contains(s['id']),
                    onChanged: busy || s['remaining'] <= 0
                        ? null
                        : (v) {
                            setState(() {
                              if (v == true) {
                                if (p['category'] != 'stay') picked.clear();
                                if (picked.length < 7) picked.add(s['id']);
                              } else
                                picked.remove(s['id']);
                            });
                          },
                    title: Text(DateFormat('EEE d MMM · HH:mm')
                        .format(DateTime.parse(s['starts_at']).toLocal())),
                    subtitle: Text(
                        '${placeMoney(s['amount_minor'], p['currency_code'])} · ${s['remaining']} left')),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                  initialValue: quantity,
                  decoration: InputDecoration(
                      labelText: p['category'] == 'stay'
                          ? 'Rooms / units'
                          : 'People / sessions'),
                  items: [
                    for (var i = 1; i <= 20; i++)
                      DropdownMenuItem(value: i, child: Text('$i'))
                  ],
                  onChanged:
                      busy ? null : (v) => setState(() => quantity = v ?? 1)),
              const SizedBox(height: 20),
              Text('${placeMoney(total, p['currency_code'])} total',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              if (error != null)
                TextButton(onPressed: busy ? null : load, child: Text(error!)),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: busy || loading || error != null || picked.isEmpty
                      ? null
                      : reserve,
                  child: Text(busy ? 'Sending…' : 'Request reservation')),
              const SizedBox(height: 12),
              const Text(
                  'No online payment taken. Your request holds selected capacity for up to 24 hours while the venue reviews it.',
                  style: TextStyle(color: ColorRes.textSecondaryDark))
            ]));
  }
}

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});
  @override
  State<ReservationsScreen> createState() => _ReservationsState();
}

class _ReservationsState extends State<ReservationsScreen> {
  List<dynamic>? items;
  String? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final r = await commerceRequest('reservations');
      if (r['status'] != true) throw StateError('Unavailable');
      if (mounted)
        setState(() {
          items = r['data'] ?? [];
          error = null;
        });
    } catch (_) {
      if (mounted) setState(() => error = 'Unable to load reservations.');
    }
  }

  Future<void> cancel(int id) async {
    if (busy) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Cancel this reservation?'),
                content: const Text(
                    'This releases your reserved capacity. You can make a new request if availability remains.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Keep reservation')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Cancel reservation'))
                ]));
    if (confirmed != true || !mounted || busy) return;
    setState(() => busy = true);
    try {
      final r = await commerceRequest('reservations/cancel', body: {'id': id});
      if (r['status'] != true) throw StateError('Unavailable');
      await load();
    } catch (_) {
      if (mounted) setState(() => error = 'Cancellation failed. Retry.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: ColorRes.bgDark,
      appBar: AppBar(title: const Text('Reservations')),
      body: RefreshIndicator(
          onRefresh: load,
          child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, 24 + MediaQuery.paddingOf(context).bottom),
              children: [
                if (error != null)
                  TextButton(onPressed: load, child: Text(error!)),
                if (items == null && error == null)
                  const LinearProgressIndicator(),
                if (items?.isEmpty == true)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                          'Your date plans, stays and spa reservations will appear here.')),
                for (final r in items ?? [])
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r['title'],
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800)),
                                Text(
                                    '${r['status'].toString().toUpperCase()} · ${placeMoney(r['total_minor'], r['currency_code'])}'),
                                Text('${r['address']} · ${r['town']}'),
                                if (r['starts_at'] != null)
                                  Text(
                                      '${DateFormat('EEE d MMM · HH:mm').format(DateTime.parse(r['starts_at']).toLocal())} → ${DateFormat('EEE d MMM · HH:mm').format(DateTime.parse(r['ends_at']).toLocal())}'),
                                Text('Reference: ${r['reference']}'),
                                if (r['review_note'] != null)
                                  Text(r['review_note']),
                                if (r['status'] == 'requested')
                                  const Text(
                                      'Waiting for venue confirmation. No payment taken.'),
                                if (['requested', 'confirmed']
                                    .contains(r['status']))
                                  TextButton(
                                      onPressed:
                                          busy ? null : () => cancel(r['id']),
                                      child: const Text('Cancel reservation'))
                              ])))
              ])));
}

class ListingRequestScreen extends StatefulWidget {
  const ListingRequestScreen({super.key});
  @override
  State<ListingRequestScreen> createState() => _ListingState();
}

class _ListingState extends State<ListingRequestScreen> {
  final fields = {
    for (final key in [
      'title',
      'description',
      'country',
      'district',
      'town',
      'address',
      'latitude',
      'longitude',
      'price_min',
      'price_max',
      'includes',
      'image_url'
    ])
      key: TextEditingController()
  };
  String category = 'stay';
  bool busy = false;
  String? message;
  List<dynamic> submissions = [];
  List<dynamic> ownerBookings = [];
  @override
  void initState() {
    super.initState();
    fields['country']!.text = 'Uganda';
    load();
  }

  @override
  void dispose() {
    for (final f in fields.values) f.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final r = await commerceRequest('places/mine');
      final bookings = await commerceRequest('places/owner-reservations');
      if (mounted && bookings['status'] == true)
        setState(() => ownerBookings = bookings['data'] ?? []);
      if (mounted && r['status'] == true)
        setState(() => submissions = r['data'] ?? []);
    } catch (_) {}
  }

  Future<void> locate() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final fix = await CommonFun.getUserCurrentLocation(
          shouldUpdateInProfileData: false);
      if (fix == null) throw StateError('Unavailable');
      fields['latitude']!.text = fix.latitude.toString();
      fields['longitude']!.text = fix.longitude.toString();
      final marks = await Geocoding()
          .placemarkFromCoordinates(fix.latitude, fix.longitude)
          .timeout(const Duration(seconds: 10));
      if (marks.isNotEmpty) {
        final p = marks.first;
        fields['country']!.text = p.country ?? '';
        fields['district']!.text = (p.isoCountryCode == 'UG'
                ? p.subAdministrativeArea
                : p.administrativeArea) ??
            '';
        fields['town']!.text = p.locality ?? p.subLocality ?? '';
        fields['address']!.text = [p.street, p.locality]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .join(', ');
      }
      if (mounted)
        setState(() => message =
            'Map location detected. Check that this is your listing’s location.');
    } catch (_) {
      if (mounted)
        setState(() => message =
            'Unable to detect the venue. Enter its address and map coordinates.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> findAddress() async {
    if (busy) return;
    if (fields['address']!.text.trim().isEmpty ||
        fields['town']!.text.trim().isEmpty) {
      setState(() => message =
          'Enter the venue’s street address and town before finding its map pin.');
      return;
    }
    setState(() => busy = true);
    try {
      final query = ['address', 'town', 'district', 'country']
          .map((k) => fields[k]!.text.trim())
          .where((v) => v.isNotEmpty)
          .join(', ');
      if (query.isEmpty) throw StateError('Enter an address');
      final results = await Geocoding()
          .locationFromAddress(query)
          .timeout(const Duration(seconds: 10));
      if (results.isEmpty) throw StateError('Unavailable');
      fields['latitude']!.text = results.first.latitude.toString();
      fields['longitude']!.text = results.first.longitude.toString();
      if (mounted)
        setState(() => message =
            'Address found. Open the map to check your venue’s pin before submitting.');
    } catch (_) {
      if (mounted)
        setState(() => message =
            'Address not found. Add a fuller address or use your location at the venue.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> submit() async {
    if (busy) return;
    if (fields['latitude']!.text.trim().isEmpty ||
        fields['longitude']!.text.trim().isEmpty) {
      setState(() => message =
          'Find your venue’s address on the map, or use your location while at the venue, before submitting.');
      return;
    }
    setState(() => busy = true);
    try {
      final r = await commerceRequest('places/submit', body: {
        for (final f in fields.entries)
          if (f.value.text.trim().isNotEmpty) f.key: f.value.text.trim(),
        'category': category,
        'price_unit': category == 'stay'
            ? 'night'
            : category == 'date'
                ? 'person'
                : 'session',
        'currency_code': 'UGX'
      });
      if (mounted)
        setState(() => message = r['status'] == true
            ? 'Submitted for review. It is not public yet.'
            : r['message'] ?? 'Check your listing details.');
      if (r['status'] == true) await load();
    } catch (_) {
      if (mounted)
        setState(() => message =
            'Unable to submit. Check required details and try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: ColorRes.bgDark,
      appBar: AppBar(title: const Text('List your place')),
      body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, 24 + MediaQuery.paddingOf(context).bottom),
          children: [
            const Text('Welcome people to your place.',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            const Text(
                'Tell us about your venue, stay or spa. An administrator reviews every listing before it appears in Explore.'),
            TextButton.icon(
                onPressed: busy ? null : locate,
                icon: const Icon(Icons.my_location),
                label: const Text('Use this location for my place')),
            DropdownButtonFormField<String>(
                initialValue: category,
                items: [
                  for (final e in placeCategories.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value))
                ],
                onChanged: busy
                    ? null
                    : (v) => setState(() => category = v ?? 'stay')),
            for (final e in fields.entries.where(
                (e) => !['latitude', 'longitude', 'image_url'].contains(e.key)))
              Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextField(
                      controller: e.value,
                      keyboardType: [
                        'latitude',
                        'longitude',
                        'price_min',
                        'price_max'
                      ].contains(e.key)
                          ? const TextInputType.numberWithOptions(
                              decimal: true, signed: true)
                          : TextInputType.text,
                      decoration: InputDecoration(
                          labelText: {
                                'price_min': 'From price · UGX',
                                'price_max': 'To price · UGX',
                                'includes': 'What’s included',
                                'image_url': 'Photo URL · HTTPS (optional)',
                                'latitude': 'Map latitude',
                                'longitude': 'Map longitude'
                              }[e.key] ??
                              e.key.replaceAll('_', ' ')))),
            TextButton.icon(
                onPressed: busy ? null : findAddress,
                icon: const Icon(Icons.place_outlined),
                label: const Text('Find this address on the map')),
            if (fields['latitude']!.text.isNotEmpty &&
                fields['longitude']!.text.isNotEmpty)
              TextButton.icon(
                  onPressed: () => launchUrl(
                      Uri.https('www.google.com', '/maps/search/', {
                        'api': '1',
                        'query':
                            "${fields['latitude']!.text},${fields['longitude']!.text}"
                      }),
                      mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Check my venue’s map pin')),
            ExpansionTile(
                title: const Text('More details (optional)'),
                children: [
                  for (final key in ['latitude', 'longitude', 'image_url'])
                    TextField(
                        controller: fields[key],
                        decoration: InputDecoration(
                            labelText: {
                          'latitude': 'Map latitude',
                          'longitude': 'Map longitude',
                          'image_url': 'Photo link · HTTPS'
                        }[key]))
                ]),
            if (message != null) Text(message!),
            FilledButton(
                onPressed: busy ? null : submit,
                child: Text(busy ? 'Sending…' : 'Submit for review')),
            const SizedBox(height: 24),
            const Text('Reservations at your places',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const Text(
                'Admin confirms these requests with your venue. No online payment has been taken.'),
            if (ownerBookings.isEmpty)
              const Text('No reservation requests yet.'),
            for (final booking in ownerBookings)
              ListTile(
                  title: Text('${booking['title']} · ${booking['status']}'),
                  subtitle: Text(
                      '${booking['currency_code']} ${booking['total_minor']} · ${booking['quantity']} guests/rooms\n${booking['review_note'] ?? ''}')),
            const SizedBox(height: 24),
            const Text('Your submissions',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            for (final p in submissions)
              ListTile(
                  title: Text(p['title']),
                  subtitle: Text(
                      '${p['status']}${p['review_note'] == null ? '' : ' · ${p['review_note']}'}'))
          ]));
}
