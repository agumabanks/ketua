import 'package:flutter/material.dart';
import 'package:ketua_ui/common/ketua_copy.dart';
import 'package:ketua_ui/screen/like_profiles_screen/incoming_likes_screen.dart';
import 'package:ketua_ui/screen/explore_screen/explore_hub.dart';
import 'package:ketua_ui/common/dashboard_top_bar.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/screen/dashboard/dashboard_screen_view_model.dart';
import 'package:ketua_ui/screen/explore_screen/explore_screen.dart';
import 'package:ketua_ui/screen/feed_screen/feed_screen.dart';
import 'package:ketua_ui/screen/message_screen/server_chat_screen.dart';
import 'package:ketua_ui/screen/profile_screen/profile_screen.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/utils/asset_res.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/font_res.dart';
import 'package:stacked/stacked.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DashboardScreenViewModel>.reactive(
      onViewModelReady: (model) => model.init(),
      viewModelBuilder: () => DashboardScreenViewModel(),
      builder: (context, model, child) {
        bool isDating = model.settingAppData?.isDating == 1;
        bool isSocialMedia = model.settingAppData?.isSocialMedia == 1;
        return Scaffold(
          backgroundColor: ColorRes.bgDark,
          bottomNavigationBar: BottomNavigationView(model: model),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                DashboardTopBar(
                  onNotificationTap: model.onNotificationTap,
                  onSearchTap: model.onSearchTap,
                  onLivesBtnClick: model.onLivesBtnClick,
                  isDating: model.settingAppData?.isDating,
                ),
                Expanded(
                  child: RetainedTabs(
                    key: ValueKey("${SessionManager.instance.getUserID()}_$isDating$isSocialMedia"),
                    index: model.pageIndex,
                    count: isDating ? 5 : (isSocialMedia ? 3 : 2),
                    pageBuilder: (index) => _getCurrentPage(isSocialMedia: isSocialMedia, isDating: isDating, index: index),
                  ),
                ),
                (SessionManager.instance.isDating && model.pageIndex == 1)
                    ? const SizedBox()
                    : const SizedBox(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _getCurrentPage(
      {required bool isSocialMedia,
      required bool isDating,
      required int index}) {
    if (!isDating && !isSocialMedia) {
      switch (index) {
        case 0:
          return const ServerMessagesScreen();
        default:
          return const ProfileScreen();
      }
    } else if (isDating && isSocialMedia) {
      switch (index) {
        case 0:
          return const ExploreScreen();
        case 1:
          return const ExploreHub();
        case 2:
          return const IncomingLikesScreen();
        case 3:
          return const ServerMessagesScreen();
        default:
          return const ProfileScreen();
      }
    } else if (!isDating && isSocialMedia) {
      // Social media only
      switch (index) {
        case 0:
          return const FeedScreen();
        case 1:
          return const ServerMessagesScreen();
        default:
          return const ProfileScreen();
      }
    } else {
      // Dating only
      switch (index) {
        case 0:
          return const ExploreScreen();
        case 1:
          return const ExploreHub();
        case 2:
          return const IncomingLikesScreen();
        case 3:
          return const ServerMessagesScreen();
        default:
          return const ProfileScreen();
      }
    }
  }
}

class BottomNavigationView extends StatelessWidget {
  final DashboardScreenViewModel model;

  const BottomNavigationView({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    bool isDating = model.settingAppData?.isDating == 1;
    bool isSocialMedia = model.settingAppData?.isSocialMedia == 1;
    List<ImageText> navList = [];

    if (!isDating && !isSocialMedia) {
      // Both off
      navList = [
        ImageText(AssetRes.icMessage, S.current.message),
        ImageText(AssetRes.icProfile, S.current.profile),
      ];
    } else if (isDating && isSocialMedia) {
      // Both on
      navList = [
        ImageText(AssetRes.icExplore, KetuaCopy.text(context, 'Swipe')),
        ImageText(AssetRes.icMatch, KetuaCopy.text(context, 'Explore')),
        ImageText(AssetRes.icFeed, KetuaCopy.text(context, 'Likes')),
        ImageText(AssetRes.icMessage, S.current.message),
        ImageText(AssetRes.icProfile, S.current.profile),
      ];
    } else if (!isDating && isSocialMedia) {
      // Social media only
      navList = [
        ImageText(AssetRes.icFeed, S.current.feed),
        ImageText(AssetRes.icMessage, S.current.message),
        ImageText(AssetRes.icProfile, S.current.profile),
      ];
    } else if (isDating && !isSocialMedia) {
      // Dating only
      navList = [
        ImageText(AssetRes.icExplore, KetuaCopy.text(context, 'Swipe')),
        ImageText(AssetRes.icMatch, KetuaCopy.text(context, 'Explore')),
        ImageText(AssetRes.icFeed, KetuaCopy.text(context, 'Likes')),
        ImageText(AssetRes.icMessage, S.current.message),
        ImageText(AssetRes.icProfile, S.current.profile),
      ];
    }
    // Floating navigation bar: rounded, dark surface, elevated, inset from edges.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            color: ColorRes.surfaceDark,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: ColorRes.borderDark),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(navList.length, (index) {
              final item = navList[index];
              final isSelected = index == model.pageIndex;
              final color =
                  isSelected ? ColorRes.ketuaAccent : ColorRes.textSecondaryDark;
              final icon = isDating ? <IconData>[Icons.local_fire_department_outlined, Icons.explore_outlined,
                Icons.favorite_outline_rounded, Icons.chat_bubble_outline_rounded, Icons.person_outline_rounded][index] : null;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => model.onBottomBarTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ColorRes.ketuaAccent.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Badge(isLabelVisible: isDating && index == 2 && model.incomingLikes > 0,
                          label: Text(model.incomingLikes > 99 ? '99+' : '${model.incomingLikes}'),
                          child: icon == null ? Image.asset(item.image, width: 24, height: 24, color: color)
                            : Icon(icon, size: 24, color: color)),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontFamily: FontRes.medium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Keep visited tabs and scroll/deck state alive; do not eagerly start every page.
class RetainedTabs extends StatefulWidget {
 final int index, count; final Widget Function(int) pageBuilder;
 const RetainedTabs({super.key, required this.index, required this.count, required this.pageBuilder});
 @override State<RetainedTabs> createState()=>_RetainedTabsState();
}
class _RetainedTabsState extends State<RetainedTabs> {
 final Map<int,Widget> pages={};
 @override void initState(){super.initState();_announce();}
 @override void didUpdateWidget(covariant RetainedTabs old){super.didUpdateWidget(old);if(old.index!=widget.index)_announce();}
 void _announce(){WidgetsBinding.instance.addPostFrameCallback((_){if(mounted) SessionManager.instance.activeTab.value=widget.index;});}
 @override Widget build(BuildContext context) {
  pages.putIfAbsent(widget.index,()=>widget.pageBuilder(widget.index));
  return IndexedStack(index:widget.index,children:List.generate(widget.count,(i)=>TickerMode(enabled:i==widget.index,child:pages[i]??const SizedBox())));
 }
}
