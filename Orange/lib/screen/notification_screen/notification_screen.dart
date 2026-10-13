import 'package:flutter/material.dart';
import 'package:ketua_ui/common/common_ui.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/screen/notification_screen/widgets/admin_notificaiton_page.dart';
import 'package:ketua_ui/screen/notification_screen/widgets/personal_notification.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/font_res.dart';
import 'package:stacked/stacked.dart';
import 'notification_screen_view_model.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<NotificationScreenViewModel>.reactive(
      viewModelBuilder: () => NotificationScreenViewModel(),
      onViewModelReady: (model) => model.init(),
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: ColorRes.bgDark,
          appBar: AppBar(title: Text(S.current.notification)),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildTabBar(model),
              const SizedBox(height: 8),
              if (model.refreshError != null)
                Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: TextButton(
                        onPressed: model.refresh,
                        child: Text(model.refreshError!))),
              if ((model.isLoading && model.adminNotification.isNotEmpty) ||
                  (model.isUserLoading && model.userNotification.isNotEmpty))
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                  child: RefreshIndicator(
                      onRefresh: model.refresh, child: _buildContent(model))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar(NotificationScreenViewModel model) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.all(5),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: ColorRes.surfaceDark2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
              child: _buildTabItem(
            title: S.current.personal,
            isSelected: model.tabIndex == 0,
            onTap: () => model.onTabChange(0),
          )),
          Expanded(
              child: _buildTabItem(
            title: S.current.platform,
            isSelected: model.tabIndex == 1,
            onTap: () => model.onTabChange(1),
          )),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? ColorRes.surfaceDark : ColorRes.surfaceDark2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? ColorRes.white : ColorRes.textSecondaryDark,
              fontFamily: FontRes.regular,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(NotificationScreenViewModel model) {
    if (model.isLoading &&
        model.tabIndex == 1 &&
        model.adminNotification.isEmpty) {
      return CommonUI.lottieWidget();
    }

    if (model.tabIndex == 0) {
      // Personal notifications
      return model.isUserLoading && model.userNotification.isEmpty
          ? CommonUI.lottieWidget()
          : PersonalNotificationPage(
              userNotification: model.userNotification,
              controller: model.userScrollController,
              onUserTap: model.onUserTap,
            );
    } else {
      // Platform/admin notifications
      return AdminNotificationPage(
        adminNotification: model.adminNotification,
        controller: model.adminScrollController,
      );
    }
  }
}
