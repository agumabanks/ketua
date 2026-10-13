import 'package:flutter/material.dart';
import 'package:ketua_ui/common/top_bar_area.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/screen/livestream_dashboard_screen/livestream_dashboard_screen_view_model.dart';
import 'package:ketua_ui/screen/livestream_dashboard_screen/widgets/center_area_livestream_dashboard.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:stacked/stacked.dart';

class LiveStreamDashBoard extends StatelessWidget {
  const LiveStreamDashBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<LiveStreamDashBoardViewModel>.reactive(
      onViewModelReady: (model) {
        model.init();
      },
      viewModelBuilder: () => LiveStreamDashBoardViewModel(),
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: ColorRes.bgDark,
          body: Column(
            children: [
              TopBarArea(
                  title: S.current.liveStreamCap, title2: S.current.dashboard),
              CenterAreaLiveStreamDashBoard(
                  onRedeemTap: model.onRedeemTap,
                  onHistoryBtnTap: model.onHistoryBtnTap,
                  onRedeemBtnTap: model.onRedeemBtnTap,
                  onAddCoinsBtnTap: model.onAddCoinsBtnTap,
                  onApplyBtnTap: model.onApplyBtnTap,
                  wallet: model.userData?.wallet,
                  totalCollection: model.userData?.totalCollected.toString(),
                  totalStream: model.userData?.totalStreams.toString(),
                  appdata: model.settingAppData,
                  model: model),
              const SizedBox(height: 10),
              const SizedBox(height: 5),
            ],
          ),
        );
      },
    );
  }
}
