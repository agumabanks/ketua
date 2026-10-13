import 'package:flutter/material.dart';
import 'package:ketua_ui/common/custom_image.dart';
import 'package:ketua_ui/model/social/short_video/short_video_model.dart';
import 'package:ketua_ui/screen/short_video_screen/short_video_view_model.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/const_res.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stacked/stacked.dart';
import 'package:video_player/video_player.dart';
import 'create_moment_screen.dart';

class ShortVideoScreen extends StatefulWidget {
  const ShortVideoScreen({super.key});
  @override
  State<ShortVideoScreen> createState() => _ShortVideoScreenState();
}

class _ShortVideoScreenState extends State<ShortVideoScreen> {
  int active = 0;

  @override
  Widget build(BuildContext context) => ViewModelBuilder<ShortVideoViewModel>.reactive(
    viewModelBuilder: () => ShortVideoViewModel(),
    onViewModelReady: (vm) => vm.init(),
    builder: (context, vm, child) => Scaffold(
      backgroundColor: ColorRes.bgDark,
      body: Stack(children: [
        if (vm.videos.isEmpty)
          Center(child: vm.isLoading
            ? const CircularProgressIndicator(color: ColorRes.ketuaAccent)
            : Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.movie_creation_outlined, size: 64, color: ColorRes.ketuaAccent),
                const SizedBox(height: 18),
                Text(vm.failed ? 'Moments could not load' : 'Your next moment is coming', textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(vm.failed ? 'Check your connection and try again.' : 'Short videos from the community will appear here.', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(onPressed: () => vm.fetchFeed(reset: true), child: const Text('Refresh')),
              ])))
        else PageView.builder(
          scrollDirection: Axis.vertical, itemCount: vm.videos.length,
          onPageChanged: (i) { setState(() => active = i); if (i >= vm.videos.length - 3) vm.fetchFeed(); },
          itemBuilder: (_, index) => _ShortVideoCard(key: ValueKey(vm.videos[index].id), video: vm.videos[index],
            active: active == index, onLike: () => vm.toggleLike(vm.videos[index]),
            onPlayed: () => vm.recordView(vm.videos[index]), onShared: () => vm.recordShare(vm.videos[index])),
        ),
        SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          IconButton.filledTonal(tooltip: 'Back', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
          const SizedBox(width: 12), const Text('Moments', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.white)),
          const Spacer(),
          IconButton.filledTonal(tooltip: 'Create a moment', onPressed: () async {
            setState(() => active = -1);
            final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const CreateMomentScreen()));
            if (!mounted) return;
            if (created == true) await vm.fetchFeed(reset: true);
            setState(() => active = 0);
          }, icon: const Icon(Icons.add)),
        ]))),
      ]),
    ),
  );
}

class _ShortVideoCard extends StatefulWidget {
  final ShortVideoModel video;
  final bool active;
  final VoidCallback onLike, onPlayed, onShared;
  const _ShortVideoCard({super.key, required this.video, required this.active, required this.onLike, required this.onPlayed, required this.onShared});
  @override
  State<_ShortVideoCard> createState() => _ShortVideoCardState();
}

class _ShortVideoCardState extends State<_ShortVideoCard> with WidgetsBindingObserver {
  VideoPlayerController? player;
  bool failed = false, loading = false, muted = false, pausedByUser = false, sharing = false;
  bool foreground = true;

  Uri? get mediaUri {
    final path = widget.video.video;
    if (path == null || path.isEmpty) return null;
    final uri = Uri.tryParse(path.startsWith('https://') ? path : '${ConstRes.aImageBaseUrl}$path');
    return uri?.scheme == 'https' ? uri : null;
  }

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); if (widget.active) initialize(); }

  Future<void> initialize() async {
    if (loading || player != null) return;
    final uri = mediaUri;
    if (uri == null) { setState(() => failed = true); return; }
    setState(() { loading = true; failed = false; });
    final next = VideoPlayerController.networkUrl(uri);
    player = next;
    try {
      await next.initialize().timeout(const Duration(seconds: 20));
      if (!mounted || player != next) return;
      await next.setLooping(true);
      await next.setVolume(muted ? 0 : 1);
      syncPlayback();
    } catch (_) {
      if (mounted && player == next) setState(() => failed = true);
    } finally { if (mounted && player == next) setState(() => loading = false); }
  }

  void syncPlayback() {
    final p = player;
    if (p == null || !p.value.isInitialized) return;
    if (widget.active && foreground && !pausedByUser && !sharing && !failed) { p.play(); widget.onPlayed(); }
    else { p.pause(); }
  }

  @override
  void didUpdateWidget(covariant _ShortVideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && player == null) initialize();
    syncPlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { foreground = state == AppLifecycleState.resumed; syncPlayback(); }

  Future<void> retry() async {
    final old = player;
    player = null;
    await old?.dispose();
    if (mounted) initialize();
  }

  Future<void> share() async {
    final uri = mediaUri;
    if (uri == null || sharing) return;
    sharing = true;
    syncPlayback();
    try {
      final box = context.findRenderObject() as RenderBox?;
      final result = await SharePlus.instance.share(ShareParams(text: '${widget.video.caption ?? 'A KETUA moment'}\n$uri',
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size));
      if (result.status == ShareResultStatus.success) widget.onShared();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing is unavailable. Please try again.')));
    } finally { sharing = false; if (mounted) syncPlayback(); }
  }

  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); player?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = player;
    final user = widget.video.user;
    return Stack(fit: StackFit.expand, children: [
      if (p?.value.isInitialized == true && !failed)
        GestureDetector(onTap: () { setState(() => pausedByUser = !pausedByUser); syncPlayback(); },
          onDoubleTap: widget.onLike, child: Center(child: AspectRatio(aspectRatio: p!.value.aspectRatio, child: VideoPlayer(p))))
      else if (widget.video.thumbnail?.isNotEmpty == true)
        CustomImage(image: '${ConstRes.aImageBaseUrl}${widget.video.thumbnail}', fullname: user?.fullname, width: double.infinity, height: double.infinity, radius: 0)
      else const ColoredBox(color: ColorRes.surfaceDark),
      if (loading) const Center(child: CircularProgressIndicator())
      else if (failed) Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('This moment could not play'), const SizedBox(height: 12),
        FilledButton(onPressed: retry, child: const Text('Retry')),
      ]))
      else if (pausedByUser) const IgnorePointer(child: Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 72))),
      Positioned(left: 0, right: 0, bottom: 0, child: IgnorePointer(child: Container(
        padding: const EdgeInsets.fromLTRB(20, 65, 88, 40),
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(user?.fullname ?? 'KETUA creator', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10), Text(widget.video.caption ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ]),
      ))),
      Positioned(right: 12, bottom: 100, child: Column(children: [
        _action(widget.video.isLiked == true ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          '${widget.video.likesCount ?? 0}', 'Like moment', widget.onLike, widget.video.isLiked == true ? ColorRes.ketuaAccent : Colors.white),
        const SizedBox(height: 20), _action(Icons.share_rounded, '${widget.video.sharesCount ?? 0}', 'Share moment', share, Colors.white),
        const SizedBox(height: 20), _action(muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, '', 'Mute or unmute', () {
          setState(() => muted = !muted); player?.setVolume(muted ? 0 : 1);
        }, Colors.white),
      ])),
      if (p?.value.isInitialized == true) Positioned(left: 0, right: 0, bottom: 0,
        child: VideoProgressIndicator(p!, allowScrubbing: true, colors: const VideoProgressColors(playedColor: ColorRes.ketuaAccent))),
    ]);
  }

  Widget _action(IconData icon, String label, String tooltip, VoidCallback callback, Color color) => Column(children: [
    IconButton(tooltip: tooltip, iconSize: 34, onPressed: callback, icon: Icon(icon, color: color)),
    if (label.isNotEmpty) Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
  ]);
}
