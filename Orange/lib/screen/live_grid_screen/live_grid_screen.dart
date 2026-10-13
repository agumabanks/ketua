import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/screen/livestream_dashboard_screen/livestream_dashboard_screen.dart';
import 'package:ketua_ui/common/common_ui.dart';
import 'package:ketua_ui/screen/live_grid_screen/live_grid_screen_view_model.dart';
import 'package:ketua_ui/screen/live_grid_screen/widgets/custom_grid_view.dart';
import 'package:ketua_ui/screen/live_grid_screen/widgets/live_grid_top_area.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:stacked/stacked.dart';

class LiveGridScreen extends StatelessWidget {
  const LiveGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<LiveGridScreenViewModel>.reactive(
      onViewModelReady: (model) {
        model.init();
      },
      viewModelBuilder: () => LiveGridScreenViewModel(),
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: ColorRes.bgDark,
          body: Column(
            children: [
              LiveGridTopArea(
                onBackBtnTap: model.onBackBtnTap,
                onGoLiveTap: model.goLiveBtnClick,
                userData: model.userData,
              ),
              if (model.liveNotice != null)
                Expanded(
                    child: Center(
                        child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.sensors_off_rounded,
                                      size: 72, color: ColorRes.ketuaAccent),
                                  const SizedBox(height: 24),
                                  const Text('Your stage is getting ready.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 16),
                                  Text(model.liveNotice!,
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 24),
                                  FilledButton(
                                      onPressed: () => Get.to(
                                          () => const LiveStreamDashBoard()),
                                      child: const Text('Hosting dashboard')),
                                  TextButton(
                                      onPressed: model.getLiveUsers,
                                      child:
                                          const Text('Refresh availability')),
                                ]))))
              else if (!model.isLoading)
                CustomGridView(
                  userData: model.liveStreamUsers,
                  onImageTap: model.onLiveStreamProfileTap,
                )
              else
                Expanded(
                  child: CommonUI.lottieWidget(),
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
