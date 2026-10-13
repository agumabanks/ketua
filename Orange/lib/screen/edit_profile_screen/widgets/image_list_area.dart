import 'package:ketua_ui/utils/font_res.dart';
import 'package:ketua_ui/common/ketua_copy.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ketua_ui/common/custom_image.dart';
import 'package:ketua_ui/screen/edit_profile_screen/edit_profile_screen_view_model.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/const_res.dart';

class ImageListArea extends StatelessWidget {
  final EditProfileScreenViewModel model;
  const ImageListArea({super.key, required this.model});
  Future<void> _actions(BuildContext context, int index) async {
    if (model.isSaving || model.isPicking) return;
    final action = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: ColorRes.surfaceDark,
        showDragHandle: true,
        builder: (context) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: Text(KetuaCopy.label('Crop & filters')),
                  onTap: () => Navigator.pop(context, 'edit')),
              if (index != 0)
                ListTile(
                    leading: const Icon(Icons.star_rounded),
                    title: Text(KetuaCopy.label('Make cover photo')),
                    onTap: () => Navigator.pop(context, 'cover')),
              ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent),
                  title: Text(KetuaCopy.label('Remove photo')),
                  onTap: () => Navigator.pop(context, 'remove'))
            ])));
    if (action == 'edit') await model.editPhoto(index);
    if (action == 'cover') model.makeCover(index);
    if (action == 'remove' && context.mounted) {
      final yes = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: Text(KetuaCopy.label('Remove this photo?')),
                  content: Text(KetuaCopy.label(
                      'The change is applied when you save your profile.')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(KetuaCopy.label('Keep photo'))),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(KetuaCopy.label('Remove')))
                  ]));
      if (yes == true) model.onImageRemove(model.imageList[index], index);
    }
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(KetuaCopy.label('Your photos'),
                  style: const TextStyle(
                      fontSize: 22,
                      fontFamily: FontRes.bold,
                      fontWeight: FontWeight.w800))),
          Text(KetuaCopy.label('${model.imageList.length}/6'),
              style: const TextStyle(
                  color: ColorRes.textSecondaryDark,
                  fontFamily: FontRes.bold,
                  fontWeight: FontWeight.w700))
        ]),
        const SizedBox(height: 8),
        Text(
            KetuaCopy.label(
                'Your first photo is your cover. Tap a photo to edit, move it to the front or remove it.'),
            style: const TextStyle(
                color: ColorRes.textSecondaryDark, height: 1.4)),
        const SizedBox(height: 16),
        GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: .75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10),
            itemBuilder: (context, index) {
              final occupied = index < model.imageList.length;
              return Semantics(
                  button: true,
                  label: occupied
                      ? 'Photo ${index + 1}, edit options'
                      : 'Add photo ${index + 1}',
                  child: InkWell(
                      onTap: model.isPicking || model.isSaving
                          ? null
                          : () => occupied
                              ? _actions(context, index)
                              : model.selectImages(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                          decoration: BoxDecoration(
                              color: ColorRes.surfaceDark2,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: occupied
                                      ? ColorRes.borderDark
                                      : ColorRes.ketuaAccent
                                          .withValues(alpha: .4))),
                          child: occupied
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(fit: StackFit.expand, children: [
                                    if (model.imageList[index].id == -1)
                                      Image.file(
                                          File(model.imageList[index].image!),
                                          fit: BoxFit.cover)
                                    else
                                      CustomImage(
                                          image:
                                              '${ConstRes.aImageBaseUrl}${model.imageList[index].image}',
                                          showShimmer: false,
                                          cacheWidth: 480),
                                    Positioned(
                                        left: 8,
                                        top: 8,
                                        child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 5),
                                            decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            child: Text(
                                                index == 0
                                                    ? KetuaCopy.label('Cover')
                                                    : '${index + 1}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w800)))),
                                    const Positioned(
                                        right: 8,
                                        bottom: 8,
                                        child: const CircleAvatar(
                                            radius: 14,
                                            backgroundColor: Colors.black54,
                                            child: const Icon(
                                                Icons.tune_rounded,
                                                size: 16,
                                                color: Colors.white)))
                                  ]))
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      const Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: ColorRes.ketuaAccent,
                                          size: 30),
                                      const SizedBox(height: 10),
                                      Text(KetuaCopy.label('Add photo'),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color:
                                                  ColorRes.textSecondaryDark))
                                    ]))));
            }),
        if (model.isPicking)
          const Padding(
              padding: const EdgeInsets.only(top: 12),
              child: const LinearProgressIndicator())
      ]);
}
