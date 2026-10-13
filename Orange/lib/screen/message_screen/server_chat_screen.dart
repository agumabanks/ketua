import 'package:ketua_ui/utils/font_res.dart';
import 'package:ketua_ui/common/chat_composer.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ketua_ui/screen/commerce/account_wallet_screen.dart';
import 'package:ketua_ui/screen/commerce/commerce_api.dart';
import 'package:ketua_ui/screen/explore_screen/places_screen.dart';
import 'package:ketua_ui/common/ketua_copy.dart';
import 'dart:async';
import 'package:ketua_ui/common/animated_gift_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/utils/color_res.dart';

class ServerMessagesScreen extends StatefulWidget {
  const ServerMessagesScreen({super.key});
  @override
  State<ServerMessagesScreen> createState() => _ServerMessagesScreenState();
}

class _ServerMessagesScreenState extends State<ServerMessagesScreen> {
  List<Map<String, dynamic>> _conversations = [], _matches = [];
  bool _loading = true;
  bool _failed = false;
  bool _fetching = false;
  bool _loadedFresh = false;
  void _activated() {
    if (SessionManager.instance.activeTab.value == 3) _load();
  }

  @override
  void initState() {
    super.initState();
    SessionManager.instance.activeTab.addListener(_activated);
    _restore();
  }

  Future<void> _restore() async {
    final saved = await SessionManager.instance.readSnapshot('inbox');
    if (!mounted) return;
    if (saved != null && !_loadedFresh)
      setState(() {
        _conversations =
            List<Map<String, dynamic>>.from(saved['conversations'] ?? []);
        _matches = List<Map<String, dynamic>>.from(saved['matches'] ?? []);
        _loading = false;
      });
    await _load();
  }

  Future<void> _load() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final results = await Future.wait(
              [ApiProvider().chatConversations(), ApiProvider().myMatches()])
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (results.any((r) => r['status'] != true))
        throw StateError('Unable to load');
      setState(() {
        _loadedFresh = true;
        _conversations =
            List<Map<String, dynamic>>.from(results[0]['data'] ?? []);
        _matches = List<Map<String, dynamic>>.from(results[1]['data'] ?? []);
        _loading = false;
        _failed = false;
      });
      unawaited(SessionManager.instance.writeSnapshot(
          'inbox', {'conversations': _conversations, 'matches': _matches}));
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _failed = true;
        });
    } finally {
      _fetching = false;
    }
  }

  @override
  void dispose() {
    SessionManager.instance.activeTab.removeListener(_activated);
    super.dispose();
  }

  Future<void> _open(Map<String, dynamic> person,
      [String? conversationId]) async {
    await Get.to(() => ServerChatScreen(
        receiverId: int.parse('${person['id']}'),
        name: '${person['fullname'] ?? 'Connection'}',
        conversationId: conversationId));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(KetuaCopy.text(context, 'Chat'),
              style: const TextStyle(
                  fontSize: 32,
                  fontFamily: FontRes.bold,
                  fontWeight: FontWeight.w800)),
          if (_loading)
            const Padding(
                padding: const EdgeInsets.all(30),
                child: const Center(child: const CircularProgressIndicator())),
          if (_failed)
            TextButton(
                onPressed: _load,
                child: Text(
                    KetuaCopy.text(context, 'Unable to load messages. Retry'))),
          if (_matches.isNotEmpty) ...[
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(KetuaCopy.text(context, 'Your matches'),
                    style: const TextStyle(
                        fontFamily: FontRes.bold,
                        fontWeight: FontWeight.w700))),
            SizedBox(
                height: 100,
                child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _matches.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (_, i) {
                      final p = _matches[i];
                      return InkWell(
                          onTap: () => _open(p),
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                              width: 84,
                              child: Column(children: [
                                CircleAvatar(
                                    radius: 28,
                                    backgroundColor: ColorRes.ketuaAccent
                                        .withValues(alpha: .18),
                                    child: const Icon(Icons.favorite_rounded,
                                        color: ColorRes.ketuaAccent)),
                                const SizedBox(height: 8),
                                Text('${p['fullname'] ?? 'Match'}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center)
                              ])));
                    })),
          ],
          if (!_loading && !_failed && _conversations.isEmpty)
            const Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: const Text(
                    'Say hello to a match. Your conversations will appear here.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: ColorRes.textSecondaryDark))),
          ..._conversations.map((c) {
            final p = Map<String, dynamic>.from(c['other_user'] ?? {});
            return Card(
                color: ColorRes.surfaceDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22)),
                child: ListTile(
                    onTap: () => _open(p, '${c['conversation_id']}'),
                    leading: const CircleAvatar(
                        child: Icon(Icons.person_outline_rounded)),
                    title: Text('${p['fullname'] ?? 'Connection'}',
                        style: const TextStyle(
                            fontFamily: FontRes.bold,
                            fontWeight: FontWeight.w700)),
                    subtitle: Text('${c['last_message'] ?? ''}',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: (c['unread_count'] ?? 0) > 0
                        ? Badge(label: Text('${c['unread_count']}'))
                        : const Icon(Icons.chevron_right_rounded)));
          }),
        ]));
  }
}

class ServerChatScreen extends StatefulWidget {
  final int receiverId;
  final String name;
  final String? conversationId;
  const ServerChatScreen(
      {super.key,
      required this.receiverId,
      required this.name,
      this.conversationId});
  @override
  State<ServerChatScreen> createState() => _ServerChatScreenState();
}

class _ServerChatScreenState extends State<ServerChatScreen>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  String? _id;
  final int _owner = SessionManager.instance.getUserID();
  List<Map<String, dynamic>> _messages = [];
  Timer? _timer;
  Map<String, dynamic>? _reply;
  String? _pendingKey, _pendingBody;
  int? _pendingReply;
  final Map<int, String> _giftKeys = {};
  final Map<int, String> _coinKeys = {};
  bool _olderBusy = false, _hasOlder = true;
  String _search = '';
  bool _showSearch = false;
  String get _draftKey => 'chat_draft_${_owner}_${widget.receiverId}';
  bool _sending = false,
      _loading = false,
      _failed = false,
      _giftLoading = false;
  bool _blocked = false, _muted = false, _canSend = true, _menuBusy = false;
  bool _hasConversation = false;
  int _wallpaper = 0;
  int? _lastReadId;
  String get _wallpaperKey =>
      "chat_wallpaper_${SessionManager.instance.getUserID()}_${widget.receiverId}";
  @override
  void initState() {
    super.initState();
    final ids = [SessionManager.instance.getUserID(), widget.receiverId]
      ..sort();
    _id = widget.conversationId ?? '${ids[0]}_${ids[1]}';
    _wallpaper = SessionManager.instance.storage.read<int>(_wallpaperKey) ?? 0;
    WidgetsBinding.instance.addObserver(this);
    _canSend = false;
    _restoreHistory();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _timer?.cancel();
    if (state == AppLifecycleState.resumed) {
      _load();
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
    }
  }

  Future<void> _restoreHistory() async {
    final draft = await SessionManager.instance.readSnapshot(_draftKey);
    if (mounted && _text.text.isEmpty && draft != null)
      _text.text = '${draft['text'] ?? ''}';
    final saved = await SessionManager.instance.readSnapshot('chat_${_id}');
    if (!mounted) return;
    if (saved != null)
      setState(() {
        _messages = List<Map<String, dynamic>>.from(saved['data'] ?? []);
        _hasConversation = true;
      });
    await _load();
  }

  Future<void> _load() async {
    if (_id == null || _loading) return;
    _loading = true;
    try {
      final r = await ApiProvider()
          .chatMessages(_id!)
          .timeout(const Duration(seconds: 12));
      if (!mounted || _owner != SessionManager.instance.getUserID()) return;
      if (r['status'] != true && r['message'] == 'Conversation not found.') {
        if (mounted)
          setState(() {
            _messages = [];
            _failed = false;
            _hasConversation = false;
            _canSend = false;
          });
        unawaited(
            SessionManager.instance.writeSnapshot('chat_${_id}', {'data': []}));
        return;
      }
      if (r['status'] != true) throw StateError('Unable to load');
      unawaited(SessionManager.instance.writeSnapshot('chat_${_id}', r));
      final messages = List<Map<String, dynamic>>.from(r['data'] ?? []);
      messages.sort(
          (a, b) => int.parse('${a['id']}').compareTo(int.parse('${b['id']}')));
      if (!mounted) return;
      final changed = _messages.isEmpty ||
          (messages.isNotEmpty && _messages.last['id'] != messages.last['id']);
      final older = _messages
          .where((m) =>
              messages.isNotEmpty &&
              int.parse('${m['id']}') < int.parse('${messages.first['id']}'))
          .toList();
      setState(() {
        _messages = [...older, ...messages];
        _hasConversation = true;
        _failed = false;
        _blocked = r['is_blocked'] == true;
        _muted = r['is_muted'] == true;
        _canSend = r['can_send'] != false;
      });
      if (messages.isNotEmpty &&
          _lastReadId != int.parse('${messages.last["id"]}')) {
        final readResult = await ApiProvider()
            .chatMarkRead(_id!, int.parse('${messages.last['id']}'))
            .timeout(const Duration(seconds: 12));
        if (readResult['status'] == true)
          _lastReadId = int.parse('${messages.last["id"]}');
      }
      if (changed &&
          (!_scroll.hasClients ||
              _scroll.position.maxScrollExtent - _scroll.offset < 180))
        _scrollToEnd();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      _loading = false;
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients)
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (_sending || !_canSend || body.isEmpty) return;
    setState(() => _sending = true);
    try {
      if (_pendingBody != body || _pendingReply != _reply?['id']) {
        _pendingKey = purchaseKey();
        _pendingBody = body;
        _pendingReply = _reply?['id'];
      }
      final r = await ApiProvider()
          .chatSend(widget.receiverId, body,
              clientKey: _pendingKey, replyToId: _pendingReply)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (r['status'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${r['message'] ?? 'Could not send'}')));
        return;
      }
      _id = '${r['conversation_id'] ?? r['data']?['conversation_id']}';
      _text.clear();
      await SessionManager.instance.writeSnapshot(_draftKey, {'text': ''});
      _pendingKey = null;
      _pendingBody = null;
      _pendingReply = null;
      if (mounted) setState(() => _reply = null);
      await _load();
      _scrollToEnd();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: const Text(
                'Message delivery could not be confirmed. Refresh before retrying.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _gift() async {
    if (_giftLoading) return;
    setState(() => _giftLoading = true);
    try {
      final catalog = await ApiProvider()
          .getSettingData()
          .timeout(const Duration(seconds: 12));
      if (catalog.status != true) throw StateError('Catalog unavailable');
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(KetuaCopy.text(
                context, 'Unable to refresh gifts. Please try again.'))));
      return;
    } finally {
      if (mounted) setState(() => _giftLoading = false);
    }
    if (!mounted) return;
    final gifts = SessionManager.instance
            .getSettings()
            ?.gifts
            ?.where((g) => g.id != null && (g.coinPrice ?? 0) > 0)
            .toList() ??
        [];
    if (gifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(KetuaCopy.text(context, 'No gifts are available yet.'))));
      return;
    }
    final gift = await showModalBottomSheet<int>(
        context: context,
        builder: (context) => SafeArea(
                child: ListView(shrinkWrap: true, children: [
              ListTile(
                  leading: const Icon(Icons.stars_rounded),
                  title: const Text('Share gift coins'),
                  subtitle:
                      const Text('Send coins directly to your connection'),
                  onTap: () {
                    Navigator.pop(context);
                    _shareCoins();
                  }),
              ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Reload & buy gift coins'),
                  subtitle:
                      const Text('Account funds and gift coins are separate'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Get.to(() => const AccountWalletScreen());
                    if (mounted && _canSend) _gift();
                  }),
              Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(KetuaCopy.text(context, 'Send a gift'),
                      style: const TextStyle(
                          fontSize: 24,
                          fontFamily: FontRes.bold,
                          fontWeight: FontWeight.w800))),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: gifts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisExtent: 155,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10),
                      itemBuilder: (_, i) => AnimatedGiftCard(
                          gift: gifts[i],
                          onTap: () => Navigator.pop(context, gifts[i].id)))),
            ])));
    if (gift == null || !mounted) return;
    final selected = gifts.firstWhere((g) => g.id == gift);
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(KetuaCopy.text(context, 'Confirm gift')),
                content: Text(
                    'Send ${selected.name ?? 'this gift'} for ${selected.coinPrice} coins? The server confirms the current price and balance.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(KetuaCopy.text(context, 'Cancel'))),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(KetuaCopy.text(context, 'Send gift')))
                ]));
    if (confirmed != true || !mounted) return;
    try {
      final result = await ApiProvider()
          .sendGift(gift, widget.receiverId,
              expectedCoinPrice: selected.coinPrice,
              clientKey: _giftKeys.putIfAbsent(gift, purchaseKey))
          .timeout(const Duration(seconds: 15));
      if (result['status'] == true) {
        _giftKeys.remove(gift);
        await _load();
        _scrollToEnd();
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${result['message'] ?? 'Unable to send gift'}')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: const Text(
                'Gift delivery could not be confirmed. Check your balance before retrying.')));
    }
  }

  Future<void> _older() async {
    if (_olderBusy || _messages.isEmpty) return;
    setState(() => _olderBusy = true);
    try {
      final r = await ApiProvider()
          .chatMessages(_id!, beforeId: int.parse('${_messages.first['id']}'))
          .timeout(const Duration(seconds: 12));
      if (r['status'] != true) throw StateError('Unavailable');
      final rows = List<Map<String, dynamic>>.from(r['data'] ?? []);
      rows.sort(
          (a, b) => int.parse('${a['id']}').compareTo(int.parse('${b['id']}')));
      if (mounted)
        setState(() {
          _hasOlder = rows.length == 50;
          final ids = _messages.map((m) => m['id']).toSet();
          _messages = [
            ...rows.where((m) => !ids.contains(m['id'])),
            ..._messages
          ];
        });
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not load earlier messages. Try again.')));
    } finally {
      if (mounted) setState(() => _olderBusy = false);
    }
  }

  Future<void> _attachments() async {
    FocusScope.of(context).unfocus();
    final choice = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        backgroundColor: ColorRes.surfaceDark,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        builder: (c) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Expanded(
                            child: Text('Share a little more',
                                style: TextStyle(
                                    fontSize: 21,
                                    fontFamily: FontRes.bold,
                                    fontWeight: FontWeight.w700))),
                        IconButton(
                            tooltip: 'Close attachments',
                            onPressed: () => Navigator.pop(c),
                            icon: const Icon(Icons.close_rounded))
                      ]),
                      const Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: Text('A photo, a thoughtful gift, or coins.',
                              style: TextStyle(
                                  color: ColorRes.textSecondaryDark))),
                      Row(children: [
                        for (final item in [
                          (
                            'photo',
                            Icons.photo_library_rounded,
                            'Gallery',
                            const Color(0xFF8CB7FF)
                          ),
                          (
                            'gift',
                            Icons.card_giftcard_rounded,
                            'Gifts',
                            const Color(0xFFFF88BD)
                          ),
                          (
                            'wallet',
                            Icons.account_balance_wallet_rounded,
                            'Wallet',
                            const Color(0xFFEBCB76)
                          )
                        ])
                          Expanded(
                              child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Material(
                                      color: ColorRes.surfaceDark2,
                                      borderRadius: BorderRadius.circular(22),
                                      child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          onTap: () =>
                                              Navigator.pop(c, item.$1),
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 22),
                                              child: Column(children: [
                                                Icon(item.$2,
                                                    color: item.$4, size: 30),
                                                const SizedBox(height: 12),
                                                Text(item.$3,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600))
                                              ]))))))
                      ]),
                      const SizedBox(height: 12),
                      ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          leading: const Icon(Icons.auto_awesome_rounded,
                              color: Color(0xFFEBCB76)),
                          title: const Text('Share gift coins'),
                          subtitle: const Text(
                              'Send from your available coin balance'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.pop(c, 'coins')),
                      ListTile(
                          leading: const Icon(Icons.restaurant_rounded),
                          title: const Text('Plan a date'),
                          subtitle:
                              const Text('Find a place within your budget'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.pop(c, 'date'))
                    ]))));
    if (!mounted) return;
    switch (choice) {
      case 'date':
        await Get.to(() => const PlacesScreen(category: 'date'));
      case 'photo':
        await _photo();
      case 'gift':
        await _gift();
      case 'coins':
        await _shareCoins();
      case 'wallet':
        await Get.to(() => const AccountWalletScreen());
    }
  }

  Future<void> _photo() async {
    if (_sending || !_canSend) return;
    XFile? image;
    try {
      if (Platform.isAndroid) {
        final path = await const MethodChannel('ketua/photos')
            .invokeMethod<String>('pick');
        if (path != null) image = XFile(path);
      } else {
        image = await ImagePicker().pickImage(
            source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not open your photos. Please try again.')));
      return;
    }
    if (image == null) return;
    final selected = image;
    try {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
                  title: const Text('Send this photo?'),
                  content: Image.file(File(selected.path),
                      height: 240, fit: BoxFit.contain),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Send'))
                  ]));
      if (confirmed != true || !mounted) return;
      setState(() => _sending = true);
      try {
        final r = await ApiProvider()
            .chatSend(widget.receiverId, null,
                messageType: 'image',
                media: File(selected.path),
                clientKey: purchaseKey(),
                replyToId: _reply?['id'])
            .timeout(const Duration(seconds: 35));
        if (r['status'] != true) throw StateError('Failed');
        if (mounted) setState(() => _reply = null);
        await _load();
        _scrollToEnd();
      } catch (_) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Photo delivery could not be confirmed. Refresh before retrying.')));
      } finally {
        if (mounted) setState(() => _sending = false);
      }
    } finally {
      if (Platform.isAndroid) {
        try {
          await File(selected.path).delete();
        } catch (_) {}
      }
    }
  }

  Future<void> _messageActions(Map<String, dynamic> m) async {
    final mine = '${m['sender_id']}' == '$_owner';
    await showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (c) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  leading: const Icon(Icons.reply_rounded),
                  title: const Text('Reply'),
                  onTap: () {
                    Navigator.pop(c);
                    setState(() => _reply = m);
                  }),
              if ((m['body'] ?? '').toString().isNotEmpty)
                ListTile(
                    leading: const Icon(Icons.copy_rounded),
                    title: const Text('Copy text'),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: '${m['body']}'));
                      Navigator.pop(c);
                    }),
              if (mine)
                ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Delete for everyone'),
                    onTap: () async {
                      Navigator.pop(c);
                      final yes = await showDialog<bool>(
                          context: context,
                          builder: (d) => AlertDialog(
                                  title: const Text('Delete this message?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(d, false),
                                        child: const Text('Cancel')),
                                    FilledButton(
                                        onPressed: () => Navigator.pop(d, true),
                                        child: const Text('Delete'))
                                  ]));
                      if (yes == true) {
                        try {
                          final result = await ApiProvider()
                              .chatDeleteMessage(int.parse('${m['id']}'));
                          if (result['status'] == true && mounted)
                            setState(() => _messages
                                .removeWhere((row) => row['id'] == m['id']));
                          await _load();
                        } catch (_) {}
                      }
                    }),
            ])));
  }

  Future<void> _shareCoins() async {
    if (!_canSend || _sending) return;
    final input = TextEditingController();
    final amount = await showDialog<int>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Share gift coins'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                      'Send coins to ${widget.name}. These are gift coins, not cash. Maximum 10,000 per transfer.'),
                  const SizedBox(height: 12),
                  TextField(
                      controller: input,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Number of coins'))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        final n = int.tryParse(input.text);
                        if (n != null && n > 0 && n <= 10000)
                          Navigator.pop(c, n);
                      },
                      child: const Text('Review'))
                ]));
    input.dispose();
    if (amount == null || !mounted) return;
    final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text('Send $amount gift coins?'),
                content: Text(
                    'To ${widget.name}. Coins leave your balance only after the server confirms delivery.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Send coins'))
                ]));
    if (yes != true || !mounted) return;
    setState(() => _sending = true);
    try {
      final r = await commerceRequest('coins/share', body: {
        'receiver_id': widget.receiverId,
        'coins': amount,
        'request_key': _coinKeys.putIfAbsent(amount, purchaseKey)
      });
      if (r['status'] == true) {
        _coinKeys.remove(amount);
        await _load();
        _scrollToEnd();
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${r['message'] ?? 'Unable to share coins.'}')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Delivery could not be confirmed. Check this chat before retrying.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _settings() async {
    await showModalBottomSheet<void>(
        context: context,
        backgroundColor: ColorRes.surfaceDark,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
                child: ListView(shrinkWrap: true, children: [
              ListTile(
                  title: Text(KetuaCopy.text(context, 'Chat settings'),
                      style: const TextStyle(
                          fontSize: 24,
                          fontFamily: FontRes.bold,
                          fontWeight: FontWeight.w800)),
                  subtitle: Text(
                      KetuaCopy.text(context, 'Make this conversation yours'))),
              for (var i = 0; i < 3; i++)
                ListTile(
                    leading: Icon([
                      Icons.auto_awesome_rounded,
                      Icons.nights_stay_rounded,
                      Icons.favorite_rounded
                    ][i]),
                    title: Text(KetuaCopy.text(
                        context,
                        [
                          'Vibe · default wallpaper',
                          'Midnight · plain',
                          'Rose · soft glow'
                        ][i])),
                    trailing: _wallpaper == i
                        ? const Icon(Icons.check_circle_rounded,
                            color: ColorRes.ketuaAccent)
                        : null,
                    onTap: () async {
                      await SessionManager.instance.storage
                          .write(_wallpaperKey, i);
                      if (mounted) setState(() => _wallpaper = i);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    }),
              const Divider(),
              for (final action in [
                _muted ? 'Unmute' : 'Mute',
                _blocked ? 'Unblock' : 'Block',
                'Clear history'
              ])
                ListTile(
                    enabled: _hasConversation && !_menuBusy,
                    title: Text(KetuaCopy.text(context, action)),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _menu(action);
                    }),
            ])));
  }

  Future<void> _menu(String action) async {
    if (_id == null || _menuBusy) return;
    final explanation = action == 'Clear history'
        ? 'This removes existing messages from your view. The other person keeps their copy, and new messages can still arrive.'
        : action == 'Block'
            ? 'This person will be blocked across discovery, chat and gifts. You can unblock them later.'
            : action == 'Mute'
                ? 'Messages can still arrive, but this conversation will not send push alerts.'
                : null;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('$action?'),
                content: explanation == null ? null : Text(explanation),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(KetuaCopy.text(context, 'Cancel'))),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(KetuaCopy.text(context, 'Confirm')))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => _menuBusy = true);
    try {
      final r = await (action == 'Block' || action == 'Unblock'
              ? ApiProvider()
                  .chatBlock(_id!, action == 'Block' ? 'block' : 'unblock')
              : action == 'Mute' || action == 'Unmute'
                  ? ApiProvider()
                      .chatMute(_id!, action == 'Mute' ? 'mute' : 'unmute')
                  : ApiProvider().chatDeleteConversation(_id!))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${r['message'] ?? action}')));
      if (r['status'] == true && action == 'Clear history') {
        Navigator.pop(context);
      } else if (r['status'] == true) {
        await _load();
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: const Text(
                'The change could not be confirmed. Refresh before retrying.')));
    } finally {
      if (mounted) setState(() => _menuBusy = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_owner == SessionManager.instance.getUserID())
      SessionManager.instance.writeSnapshot(_draftKey, {'text': _text.text});
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = SessionManager.instance.getUserID();
    return Scaffold(
        backgroundColor: ColorRes.bgDark,
        appBar: AppBar(
            title:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontFamily: FontRes.bold, fontSize: 18)),
              const Text('Your connection',
                  style: TextStyle(
                      fontSize: 12, color: ColorRes.textSecondaryDark))
            ]),
            actions: [
              IconButton(
                  tooltip: 'Search chat',
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () => setState(() {
                        _showSearch = !_showSearch;
                        if (!_showSearch) _search = '';
                      })),
              IconButton(
                  tooltip: KetuaCopy.text(context, 'Chat settings'),
                  onPressed: _settings,
                  icon: const Icon(Icons.tune_rounded)),
            ]),
        body: Container(
            decoration: BoxDecoration(
                gradient: _wallpaper == 1
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _wallpaper == 2
                            ? const [
                                Color(0xFF281522),
                                ColorRes.bgDark,
                                Color(0xFF21152B)
                              ]
                            : const [
                                Color(0xFF161D2C),
                                ColorRes.bgDark,
                                Color(0xFF22172E)
                              ])),
            child: Stack(children: [
              if (_wallpaper != 1)
                Positioned.fill(
                    child: IgnorePointer(
                        child: CustomPaint(
                            painter:
                                _ChatWallpaperPainter(rose: _wallpaper == 2)))),
              Column(children: [
                if (_showSearch)
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: TextField(
                          onChanged: (v) =>
                              setState(() => _search = v.toLowerCase()),
                          decoration: const InputDecoration(
                              hintText: 'Search this conversation',
                              prefixIcon: Icon(Icons.search),
                              isDense: true))),
                if (_hasOlder && _messages.length >= 50)
                  TextButton(
                      onPressed: _olderBusy ? null : _older,
                      child: Text(_olderBusy
                          ? 'Loading earlier…'
                          : 'Earlier messages')),
                if (!_canSend)
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                          KetuaCopy.text(
                              context,
                              _blocked
                                  ? 'This conversation is blocked.'
                                  : 'Checking your connection…'),
                          style: const TextStyle(
                              color: ColorRes.textSecondaryDark))),
                if (_muted)
                  Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                          KetuaCopy.text(context, 'Notifications muted'),
                          style: const TextStyle(
                              color: ColorRes.textSecondaryDark))),
                if (_failed)
                  TextButton(
                      onPressed: _load,
                      child: Text(KetuaCopy.text(
                          context, 'Connection interrupted. Retry'))),
                Expanded(
                    child: _messages.isEmpty
                        ? Center(
                            child: Text(
                                KetuaCopy.text(
                                    context, 'Start with a thoughtful hello.'),
                                style: TextStyle(
                                    color: ColorRes.textSecondaryDark)))
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) {
                              final m = _messages[i];
                              if (_search.isNotEmpty &&
                                  !('${m['body'] ?? ''}'
                                      .toLowerCase()
                                      .contains(_search)))
                                return const SizedBox.shrink();
                              final mine = '${m['sender_id']}' == '$me';
                              return GestureDetector(
                                  onLongPress: () => _messageActions(m),
                                  child: Align(
                                      alignment: mine
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                          constraints: BoxConstraints(
                                              maxWidth:
                                                  MediaQuery.sizeOf(context)
                                                          .width *
                                                      .84),
                                          margin:
                                              const EdgeInsets.only(bottom: 10),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                              color: mine
                                                  ? const Color(0xFF503044)
                                                  : ColorRes.surfaceDark2,
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (m['message_type'] == 'gift')
                                                  const Padding(
                                                      padding: EdgeInsets.only(
                                                          bottom: 8),
                                                      child: Icon(
                                                          Icons
                                                              .card_giftcard_rounded,
                                                          size: 36,
                                                          color: Color(
                                                              0xFFE7BC43))),
                                                if (m['reply_to_id'] != null)
                                                  Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      margin:
                                                          const EdgeInsets.only(
                                                              bottom: 8),
                                                      decoration: BoxDecoration(
                                                          color: Colors.black12,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10)),
                                                      child: Text(
                                                          '${m["reply_preview"] ?? "Reply"}',
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      12))),
                                                if (m['media_url'] != null && m['message_type'] == 'image')
                                                  InkWell(
                                                      onTap: () => showDialog(
                                                          context: context,
                                                          builder: (c) => Dialog(
                                                              child: InteractiveViewer(
                                                                  child: Image.network(
                                                                      '${m["media_url"]}',
                                                                      headers: ApiProvider()
                                                                          .authHeaders())))),
                                                      child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  12),
                                                          child: Image.network(
                                                              '${m["media_url"]}',
                                                              headers: ApiProvider().authHeaders(),
                                                              height: 190,
                                                              width: 240,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (_, __, ___) => const Text('Photo unavailable')))),
                                                Text(
                                                    '${m['body'] ?? (m['media'] != null ? 'Media attachment' : '')}',
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        height: 1.4,
                                                        fontWeight:
                                                            FontWeight.w400)),
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 6),
                                                    child: Text(
                                                        DateFormat('HH:mm').format(
                                                            (DateTime.tryParse(
                                                                        '${m['created_at']}') ??
                                                                    DateTime
                                                                        .now())
                                                                .toLocal()),
                                                        style: const TextStyle(
                                                            fontSize: 10,
                                                            color: Colors
                                                                .white70))),
                                                if (mine)
                                                  Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 6),
                                                      child: Text(
                                                          m['is_read'] ==
                                                                      true ||
                                                                  m['is_read'] ==
                                                                      1
                                                              ? 'Read'
                                                              : 'Delivered',
                                                          style: const TextStyle(
                                                              fontSize: 10,
                                                              color: Colors
                                                                  .white70)))
                                              ]))));
                            })),
                if (_reply != null)
                  ListTile(
                      dense: true,
                      leading: const Icon(Icons.reply),
                      title: Text('${_reply!['body'] ?? 'Photo'}',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                          onPressed: () => setState(() => _reply = null),
                          icon: const Icon(Icons.close))),
                ChatComposer(
                    controller: _text,
                    enabled: _canSend,
                    busy: _sending || _giftLoading,
                    onAttach: _attachments,
                    onSend: _send),
              ])
            ])));
  }
}

class _ChatWallpaperPainter extends CustomPainter {
  final bool rose;
  const _ChatWallpaperPainter({required this.rose});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (rose ? ColorRes.ketuaAccent : const Color(0xFFC684FF))
          .withValues(alpha: .09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    // Original, quiet line art: connection, conversation and little sparks.
    for (var row = 0; row * 100 < size.height; row++) {
      for (var col = 0; col * 88 < size.width; col++) {
        canvas.save();
        canvas.translate(
            col * 88.0 + 28 + (row.isOdd ? 24 : 0), row * 100.0 + 35);
        canvas.rotate(((row + col) % 3 - 1) * .22);
        switch ((row * 3 + col) % 4) {
          case 0:
            final heart = Path()
              ..moveTo(0, 12)
              ..cubicTo(-25, -3, -12, -20, 0, -8)
              ..cubicTo(12, -20, 25, -3, 0, 12);
            canvas.drawPath(heart, paint);
          case 1:
            canvas.drawRRect(
                RRect.fromRectAndRadius(const Rect.fromLTWH(-16, -12, 32, 23),
                    const Radius.circular(8)),
                paint);
            canvas.drawPath(
                Path()
                  ..moveTo(-8, 11)
                  ..lineTo(-11, 18)
                  ..lineTo(0, 11),
                paint);
            for (var dot = -8; dot <= 8; dot += 8) {
              canvas.drawCircle(Offset(dot.toDouble(), 0), 1, paint);
            }
          case 2:
            final spark = Path()
              ..moveTo(0, -16)
              ..quadraticBezierTo(3, -3, 14, 0)
              ..quadraticBezierTo(3, 3, 0, 16)
              ..quadraticBezierTo(-3, 3, -14, 0)
              ..quadraticBezierTo(-3, -3, 0, -16);
            canvas.drawPath(spark, paint);
          case 3:
            canvas.drawCircle(const Offset(-6, -3), 10, paint);
            canvas.drawCircle(const Offset(6, 3), 10, paint);
        }
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_ChatWallpaperPainter oldDelegate) =>
      oldDelegate.rose != rose;
}
