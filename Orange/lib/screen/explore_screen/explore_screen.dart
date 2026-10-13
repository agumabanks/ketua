import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/screen/preference_screen/preference_screen.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/screen/explore_screen/explore_screen_view_model.dart';
import 'package:ketua_ui/screen/explore_screen/widgets/bottom_bottons.dart';
import 'package:ketua_ui/screen/explore_screen/widgets/full_image_view.dart';
import 'package:stacked/stacked.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ExploreScreenViewModel>.reactive(
      onViewModelReady: (model) {
        model.init();
      },
      viewModelBuilder: () => ExploreScreenViewModel(),
      builder: (context, model, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(children: [
                Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                        color: ColorRes.surfaceDark2,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: ColorRes.borderDark)),
                    child: const Text('For you',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                IconButton(
                    tooltip: 'Discovery preferences',
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: () async {
                      final saved =
                          await Get.to(() => const PreferenceScreen());
                      if (saved == true) model.resetDiscovery();
                    }),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(
                        model.failedSwipeCount > 0
                            ? '${model.failedSwipeCount} swipe(s) were not saved.'
                            : model.actionPending
                                ? 'Confirming action…'
                                : model.pendingSwipeCount > 0
                                    ? 'Saving ${model.pendingSwipeCount} swipe(s)…'
                                    : 'Find your kind of connection',
                        style: const TextStyle(
                            color: ColorRes.textSecondaryDark, fontSize: 12))),
                if (model.failedSwipeCount > 0)
                  IconButton(
                      tooltip: 'Retry unsaved swipes',
                      onPressed: model.retryFailedSwipes,
                      icon: const Icon(Icons.sync_rounded)),
                IconButton(
                    tooltip: 'Boost',
                    onPressed: model.onBoostTap,
                    icon: const Icon(Icons.bolt_rounded,
                        color: ColorRes.ketuaAccent)),
              ]),
            ),
            FullImageView(model: model),
            if (model.combinedList.isNotEmpty && !model.deckExhausted)
              BottomButtons(model: model),
          ],
        );
      },
    );
  }
}
