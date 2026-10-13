import 'package:ketua_ui/screen/commerce/commerce_api.dart';
import 'package:ketua_ui/common/ketua_copy.dart';
import 'package:flutter/material.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/utils/color_res.dart';

class ExperiencesScreen extends StatefulWidget {
  final String? category;
  final bool ticketsOnly;
  final bool tonight;
  const ExperiencesScreen(
      {super.key,
      this.category,
      this.ticketsOnly = false,
      this.tonight = false});
  @override
  State<ExperiencesScreen> createState() => _ExperiencesState();
}

class _ExperiencesState extends State<ExperiencesScreen> {
  List<Map<String, dynamic>> _events = [], _tickets = [];
  bool _loading = true, _failed = false, _saved = false;
  int? _busy;
  final Map<int, String> purchaseKeys = {};
  @override
  void initState() {
    super.initState();
    restore();
  }

  Future<void> restore() async {
    if (!widget.ticketsOnly) {
      final cached = await SessionManager.instance
          .readSnapshot('events_${widget.category ?? "all"}_${widget.tonight}');
      if (!mounted) return;
      if (cached != null)
        setState(() {
          _events = List<Map<String, dynamic>>.from(cached['data'] ?? []);
          _loading = false;
          _saved = true;
        });
    }
    await _load();
  }

  Future<void> _load() async {
    final owner = SessionManager.instance.getUserID();
    try {
      final r = await Future.wait([
        ApiProvider().experiences(category: widget.category),
        ApiProvider().experienceTickets()
      ]).timeout(const Duration(seconds: 15));
      if (!mounted || owner != SessionManager.instance.getUserID()) return;
      if (r.any((x) => x['status'] != true)) throw StateError('Unavailable');
      if (mounted)
        setState(() {
          _events = List<Map<String, dynamic>>.from(r[0]['data'] ?? []);
          if (widget.tonight) {
            final now = DateTime.now();
            final until = DateTime(now.year, now.month, now.day + 1, 6);
            _events.removeWhere((e) {
              final start = DateTime.tryParse('${e['starts_at']}')?.toLocal();
              return start == null || start.isAfter(until);
            });
          }
          _tickets = List<Map<String, dynamic>>.from(r[1]['data'] ?? []);
          _loading = false;
          _failed = false;
          _saved = false;
        });
      await SessionManager.instance.writeSnapshot(
          'events_${widget.category ?? "all"}_${widget.tonight}',
          {'data': _events});
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _failed = true;
        });
    }
  }

  String _price(Map<String, dynamic> e) {
    final amount = num.tryParse('${e['amount_minor']}') ?? 0;
    final decimals = int.tryParse('${e['decimals']}') ?? 0;
    final scale = decimals == 0
        ? 1
        : decimals == 2
            ? 100
            : decimals == 3
                ? 1000
                : decimals == 4
                    ? 10000
                    : 10;
    return amount == 0
        ? KetuaCopy.text(context, 'Free')
        : '${e['currency_code']} ${(amount / scale).toStringAsFixed(decimals)}';
  }

  Future<void> _reserve(Map<String, dynamic> e) async {
    if (_busy != null) return;
    if ((e['amount_minor'] as num) > 0) {
      setState(() => _busy = e['id']);
      final ok = await confirmAccountPurchase(context,
          title: 'Ticket · ${e['title']}',
          kind: 'ticket',
          itemId: '${e['id']}',
          currency: e['currency_code'],
          amount: e['amount_minor'],
          idempotencyKey: purchaseKeys.putIfAbsent(e['id'], purchaseKey));
      if (ok) {
        purchaseKeys.remove(e['id']);
        await _load();
      }
      if (mounted) setState(() => _busy = null);
      return;
    }
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(KetuaCopy.text(context, 'Reserve your place?')),
                content: Text('${e['title']} · ${_price(e)}'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(KetuaCopy.text(context, 'Cancel'))),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(KetuaCopy.text(context, 'Reserve')))
                ]));
    if (ok != true || !mounted) return;
    setState(() => _busy = e['id'] as int);
    try {
      final r = await ApiProvider()
          .reserveExperience(e['id'] as int)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r['status'] == true
              ? 'Your ticket is confirmed.'
              : '${r['message'] ?? 'Unable to reserve'}')));
      if (r['status'] == true) await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                KetuaCopy.text(context, 'Check My tickets before retrying.'))));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: ColorRes.bgDark,
      appBar: AppBar(
          title: Text(KetuaCopy.text(
              context,
              widget.ticketsOnly
                  ? 'My tickets'
                  : widget.category == 'party'
                      ? 'Parties'
                      : widget.category == 'live'
                          ? 'Live events'
                          : 'Experiences'))),
      body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, 24 + MediaQuery.paddingOf(context).bottom),
              children: [
                Text(
                    KetuaCopy.text(
                        context,
                        widget.ticketsOnly
                            ? 'My tickets'
                            : 'Find your next shared moment.'),
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                if (_saved)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                          'Saved experiences · availability and prices checked at checkout',
                          style: const TextStyle(
                              color: ColorRes.textSecondaryDark))),
                if (_loading) const Center(child: CircularProgressIndicator()),
                if (_failed)
                  TextButton(
                      onPressed: _load,
                      child: Text(KetuaCopy.text(
                          context, 'Unable to load experiences. Retry'))),
                if (!_loading && !_failed && _events.isEmpty)
                  Text(KetuaCopy.text(context,
                      'New experiences will appear here. Come back soon.')),
                ...(_events.where((e) {
                  final start =
                      DateTime.tryParse('${e['starts_at']}')?.toLocal();
                  return !widget.ticketsOnly &&
                      start != null &&
                      start.isAfter(DateTime.now()) &&
                      (!widget.tonight ||
                          start.isBefore(DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day + 1,
                              6)));
                })).map((e) {
                  final demo = e['is_demo'] == true || e['is_demo'] == 1;
                  final paid = (num.tryParse('${e['amount_minor']}') ?? 0) > 0;
                  final ticket = _tickets
                      .where((t) => t['experience_id'] == e['id'])
                      .firstOrNull;
                  final date =
                      DateTime.tryParse('${e['starts_at']}')?.toLocal();
                  return Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(colors: [
                            Color(0xFF30203D),
                            ColorRes.surfaceDark
                          ])),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(
                                  e['category'] == 'party'
                                      ? Icons.celebration_rounded
                                      : e['category'] == 'live'
                                          ? Icons.sensors_rounded
                                          : Icons.event_rounded,
                                  color: const Color(0xFFC684FF),
                                  size: 40),
                              const Spacer(),
                              Chip(
                                  label: Text(demo
                                      ? KetuaCopy.text(context, 'Preview')
                                      : _price(e)))
                            ]),
                            const SizedBox(height: 20),
                            Text('${e['title']}',
                                style: const TextStyle(
                                    fontSize: 23, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text('${e['description']}',
                                style: const TextStyle(
                                    color: ColorRes.textSecondaryDark)),
                            const SizedBox(height: 16),
                            Text('${e['venue']}'),
                            if (!demo && date != null)
                              Text(
                                  '${date.day}/${date.month}/${date.year} · ${date.hour}:${date.minute.toString().padLeft(2, '0')}'),
                            const SizedBox(height: 12),
                            Text('${_price(e)} · ${e['remaining']} places',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 14),
                            if (ticket != null)
                              SelectableText('Ticket: ${ticket['ticket_code']}')
                            else
                              SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                      onPressed: demo ||
                                              _busy != null ||
                                              (e['remaining'] ?? 0) == 0
                                          ? null
                                          : () => _reserve(e),
                                      child: Text(KetuaCopy.text(
                                          context,
                                          demo
                                              ? 'Preview · tickets unavailable'
                                              : paid
                                                  ? 'Buy ticket'
                                                  : _busy == e['id']
                                                      ? 'Reserving…'
                                                      : (e['remaining'] ?? 0) ==
                                                              0
                                                          ? 'Sold out'
                                                          : 'Reserve free ticket')))),
                          ]));
                }),
                if (!_loading &&
                    !_failed &&
                    widget.ticketsOnly &&
                    _tickets.isEmpty)
                  Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(KetuaCopy.text(context,
                          'Your confirmed tickets will appear here.'))),
                if (_tickets.isNotEmpty) ...[
                  Text(KetuaCopy.text(context, 'My tickets'),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  ..._tickets.map((t) => Card(
                      child: ListTile(
                          title: Text('${t['title']}'),
                          subtitle: SelectableText('${t['ticket_code']}'))))
                ],
              ])));
}
