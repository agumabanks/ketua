import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/common/ketua_copy.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:video_player/video_player.dart';

class CreateMomentScreen extends StatefulWidget {
  const CreateMomentScreen({super.key});
  @override
  State<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends State<CreateMomentScreen> {
  final caption = TextEditingController();
  VideoPlayerController? preview;
  File? file;
  bool busy = false;
  String? error;
  String t(String key) => KetuaCopy.text(context, key);

  Future<void> choose(ImageSource source) async {
    if (busy) return;
    setState(() { busy = true; error = null; });
    VideoPlayerController? next;
    try {
      final picked = await ImagePicker().pickVideo(source: source, maxDuration: const Duration(minutes: 10));
      if (picked == null || !mounted) return;
      final selected = File(picked.path);
      if (await selected.length() > 50 * 1024 * 1024) throw StateError('Choose a video smaller than 50 MB.');
      next = VideoPlayerController.file(selected);
      await next.initialize().timeout(const Duration(seconds: 20));
      if (!mounted) { await next.dispose(); return; }
      if (next.value.duration > const Duration(minutes: 10) || next.value.duration.inMilliseconds < 1000) {
        throw StateError('Choose a video between 1 second and 10 minutes.');
      }
      await preview?.dispose();
      await next.setLooping(true);
      await next.setVolume(0);
      setState(() { preview = next; file = selected; });
      next.play();
    } catch (e) {
      if (next != preview) await next?.dispose();
      if (mounted) setState(() => error = e is StateError ? e.message.toString() : 'Video unavailable. Check access and try again.');
    } finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> publish() async {
    final selected = file;
    if (selected == null || busy) return;
    setState(() { busy = true; error = null; });
    await preview?.pause();
    try {
      final result = await ApiProvider().shortVideoCreate(videoFile: selected, caption: caption.text.trim(),
        durationSec: preview?.value.duration.inSeconds).timeout(const Duration(seconds: 90));
      if (result['status'] != true) throw StateError(result['message'] ?? 'Upload failed. Try again.');
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => error = e is StateError ? e.message.toString() : 'Upload failed. Try again.');
    } finally { if (mounted) setState(() => busy = false); }
  }

  @override
  void dispose() { caption.dispose(); preview?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => PopScope(canPop: !busy, child: Scaffold(
    backgroundColor: ColorRes.bgDark,
    appBar: AppBar(title: Text(t('Create a moment')), automaticallyImplyLeading: !busy),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      if (preview?.value.isInitialized == true)
        SizedBox(height: 320, child: Center(child: ClipRRect(borderRadius: BorderRadius.circular(24),
          child: AspectRatio(aspectRatio: preview!.value.aspectRatio, child: VideoPlayer(preview!)))))
      else Container(height: 220, decoration: BoxDecoration(color: ColorRes.surfaceDark, borderRadius: BorderRadius.circular(28)),
        child: const Icon(Icons.movie_creation_outlined, size: 64, color: ColorRes.ketuaAccent)),
      const SizedBox(height: 20),
      Wrap(spacing: 12, runSpacing: 12, children: [
        OutlinedButton.icon(onPressed: busy ? null : () => choose(ImageSource.gallery), icon: const Icon(Icons.video_library_outlined), label: Text(t('Choose video'))),
        OutlinedButton.icon(onPressed: busy ? null : () => choose(ImageSource.camera), icon: const Icon(Icons.videocam_outlined), label: Text(t('Record video'))),
      ]),
      const SizedBox(height: 20),
      TextField(controller: caption, enabled: !busy, maxLength: 2200, minLines: 2, maxLines: 5,
        decoration: InputDecoration(labelText: t('Caption'), hintText: t('What is your moment about?'))),
      Text(t('Videos are public. Do not share private details or content you do not have permission to post.'), style: const TextStyle(color: ColorRes.textSecondaryDark)),
      const SizedBox(height: 16),
      if (error != null) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(t(error!), style: const TextStyle(color: ColorRes.ketuaAccent))),
      FilledButton(onPressed: file == null || busy ? null : publish, child: busy
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(t('Publish moment'))),
    ]),
  ));
}
