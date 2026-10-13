import 'package:ketua_ui/common/ketua_copy.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as im;
import 'package:path_provider/path_provider.dart';
import 'package:ketua_ui/utils/color_res.dart';

const photoFilters = ['Original', 'Warm', 'Cool', 'Mono', 'Vivid'];
List<double> photoFilterMatrix(int filter) {
  if (filter == 3)
    return [
      .2126,
      .7152,
      .0722,
      0,
      0,
      .2126,
      .7152,
      .0722,
      0,
      0,
      .2126,
      .7152,
      .0722,
      0,
      0,
      0,
      0,
      0,
      1,
      0
    ];
  if (filter == 4)
    return [
      1.157,
      -.143,
      -.014,
      0,
      0,
      -.043,
      1.057,
      -.014,
      0,
      0,
      -.043,
      -.143,
      1.186,
      0,
      0,
      0,
      0,
      0,
      1,
      0
    ];
  return [
    filter == 1
        ? 1.08
        : filter == 2
            ? 0.94
            : 1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    filter == 1
        ? 0.94
        : filter == 2
            ? 1.08
            : 1,
    0,
    0,
    0,
    0,
    0,
    1,
    0
  ];
}

// Crop and encode away from the UI thread. GPS/EXIF metadata never survives export.
Uint8List exportProfilePhoto(Map<String, dynamic> args) {
  var photo = im.decodeImage(args['bytes'] as Uint8List);
  if (photo == null) throw const FormatException('Unsupported photo');
  photo = im.bakeOrientation(photo);
  if (args['turns'] != 0)
    photo = im.copyRotate(photo, angle: (args['turns'] as int) * 90);
  final rect = List<double>.from(args['rect']);
  final w = (rect[2] * photo.width).round().clamp(1, photo.width);
  final h = (rect[3] * photo.height).round().clamp(1, photo.height);
  final x = (rect[0] * photo.width).round().clamp(0, photo.width - w);
  final y = (rect[1] * photo.height).round().clamp(0, photo.height - h);
  photo = im.copyCrop(photo, x: x, y: y, width: w, height: h);
  if (photo.width > 1200 || photo.height > 1600)
    photo = im.copyResize(photo,
        width: photo.width > 1200 ? 1200 : null,
        height: photo.width > 1200 ? null : 1600);
  photo = photo.convert(format: im.Format.uint8, numChannels: 3);
  final matrix = photoFilterMatrix(args['filter'] as int);
  for (final p in photo) {
    final r = p.r, g = p.g, b = p.b;
    p.r = (matrix[0] * r + matrix[1] * g + matrix[2] * b).clamp(0, 255);
    p.g = (matrix[5] * r + matrix[6] * g + matrix[7] * b).clamp(0, 255);
    p.b = (matrix[10] * r + matrix[11] * g + matrix[12] * b).clamp(0, 255);
  }
  photo.exif = im.ExifData();
  return Uint8List.fromList(im.encodeJpg(photo, quality: 90));
}

class PhotoEditorScreen extends StatefulWidget {
  final String path;
  const PhotoEditorScreen({super.key, required this.path});
  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorState();
}

class _PhotoEditorState extends State<PhotoEditorScreen> {
  final _transform = TransformationController();
  Uint8List? _bytes;
  Size? _imageSize, _base, _viewport;
  int _filter = 0, _turns = 0;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    try {
      final bytes = await File(widget.path).readAsBytes();
      final size = await compute(_dimensions, bytes);
      if (mounted)
        setState(() {
          _bytes = bytes;
          _imageSize = Size(size[0].toDouble(), size[1].toDouble());
        });
    } catch (_) {
      if (mounted) setState(() => _error = 'This photo could not be opened.');
    }
  }

  static List<int> _dimensions(Uint8List bytes) {
    final image = im.decodeImage(bytes);
    if (image == null) throw const FormatException();
    final upright = im.bakeOrientation(image);
    return [upright.width, upright.height];
  }

  void _reset() {
    _base = null;
    setState(() {});
  }

  Future<void> _save() async {
    if (_bytes == null || _base == null || _viewport == null || _saving) return;
    setState(() => _saving = true);
    try {
      final top = _transform.toScene(Offset.zero);
      final scale = _transform.value.getMaxScaleOnAxis();
      final encoded = await compute(exportProfilePhoto, {
        'bytes': _bytes!,
        'turns': _turns,
        'filter': _filter,
        'rect': [
          top.dx / _base!.width,
          top.dy / _base!.height,
          _viewport!.width / (scale * _base!.width),
          _viewport!.height / (scale * _base!.height)
        ]
      });
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/ketua_photo_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await file.writeAsBytes(encoded);
      if (mounted) Navigator.pop(context, file.path);
    } catch (_) {
      if (mounted)
        setState(
            () => _error = 'Unable to export this photo. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: ColorRes.bgDark,
      appBar: AppBar(title: Text(KetuaCopy.label('Make it yours')), actions: [
        TextButton(
            onPressed: _saving ? null : _save,
            child: Text(KetuaCopy.label(_saving ? 'Saving…' : 'Use photo')))
      ]),
      body: SafeArea(
          child: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
                KetuaCopy.label('Pinch to zoom. Drag to frame your photo.'),
                style: const TextStyle(color: ColorRes.textSecondaryDark))),
        Expanded(
            child: _imageSize == null
                ? Center(
                    child: _error != null
                        ? Text(_error!)
                        : const CircularProgressIndicator())
                : LayoutBuilder(builder: (context, c) {
                    final width = (c.maxHeight * .75)
                        .clamp(1, c.maxWidth - 32)
                        .toDouble();
                    final viewport = Size(width, width / 0.75);
                    if (_base == null || _viewport != viewport) {
                      final size = _turns.isOdd
                          ? Size(_imageSize!.height, _imageSize!.width)
                          : _imageSize!;
                      final factor = (viewport.width / size.width).clamp(
                          viewport.height / size.height, double.infinity);
                      _base = Size(size.width * factor, size.height * factor);
                      _viewport = viewport;
                      _transform.value = Matrix4.identity()
                        ..translateByDouble((viewport.width - _base!.width) / 2,
                            (viewport.height - _base!.height) / 2, 0, 1);
                    }
                    return Center(
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: SizedBox(
                                width: viewport.width,
                                height: viewport.height,
                                child: Stack(children: [
                                  InteractiveViewer(
                                      transformationController: _transform,
                                      constrained: false,
                                      minScale: 1,
                                      maxScale: 4,
                                      child: SizedBox(
                                          width: _base!.width,
                                          height: _base!.height,
                                          child: ColorFiltered(
                                              colorFilter: ColorFilter.matrix(
                                                  photoFilterMatrix(_filter)),
                                              child: RotatedBox(
                                                  quarterTurns: _turns,
                                                  child: Image.memory(_bytes!,
                                                      fit: BoxFit.fill))))),
                                  const IgnorePointer(child: _CropGuides())
                                ]))));
                  })),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.redAccent))),
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton.icon(
                  onPressed: _saving
                      ? null
                      : () {
                          _turns = (_turns + 1) % 4;
                          _reset();
                        },
                  icon: const Icon(Icons.rotate_right),
                  label: Text(KetuaCopy.label('Rotate'))),
              TextButton.icon(
                  onPressed: _saving ? null : _reset,
                  icon: const Icon(Icons.center_focus_strong),
                  label: Text(KetuaCopy.label('Reset crop')))
            ])),
        SizedBox(
            height: 62,
            child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: photoFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ChoiceChip(
                    label: Text(KetuaCopy.label(photoFilters[i])),
                    selected: _filter == i,
                    onSelected:
                        _saving ? null : (_) => setState(() => _filter = i)))),
      ])));
}

class _CropGuides extends StatelessWidget {
  const _CropGuides();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _GuidesPainter());
}

class _GuidesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(Offset(size.width * i / 3, 0),
          Offset(size.width * i / 3, size.height), p);
      canvas.drawLine(Offset(0, size.height * i / 3),
          Offset(size.width, size.height * i / 3), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
