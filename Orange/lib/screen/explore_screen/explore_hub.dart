import 'package:ketua_ui/utils/font_res.dart';
import 'package:ketua_ui/screen/commerce/paid_content_screen.dart';
import 'package:ketua_ui/screen/feed_screen/feed_screen.dart';
import 'package:ketua_ui/screen/explore_screen/experiences_screen.dart';
import 'package:ketua_ui/common/ketua_copy.dart';
import 'package:flutter/material.dart';
import 'places_screen.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/screen/find_match_profile/find_match_profile.dart';
import 'package:ketua_ui/screen/short_video_screen/short_video_screen.dart';
import 'package:ketua_ui/service/session_manager.dart';
import 'package:ketua_ui/utils/color_res.dart';

class ExploreHub extends StatelessWidget {
  const ExploreHub({super.key});
  Widget _experience(BuildContext context, String title, String subtitle,
          IconData icon, VoidCallback onTap) =>
      Material(
          color: ColorRes.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: ColorRes.ketuaAccent, size: 26),
                        const SizedBox(height: 10),
                        Text(KetuaCopy.text(context, title),
                            style: const TextStyle(
                                fontSize: 17,
                                fontFamily: FontRes.bold,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Flexible(
                            child: Text(KetuaCopy.text(context, subtitle),
                                style: const TextStyle(
                                    color: ColorRes.textSecondaryDark,
                                    fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis))
                      ]))));
  @override
  Widget build(BuildContext context) {
    final goals = SessionManager.instance
            .getSettings()
            ?.relationshipGoals
            ?.where((g) => g.isDeleted != 1)
            .toList() ??
        [];
    const icons = [
      Icons.local_florist_rounded,
      Icons.diamond_rounded,
      Icons.favorite_rounded,
      Icons.auto_awesome_rounded
    ];
    const colors = [
      Color(0xFFFF678E),
      Color(0xFFC684FF),
      Color(0xFF7BAEFF),
      Color(0xFFE7BC43)
    ];
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(KetuaCopy.text(context, 'Explore'),
              style: const TextStyle(
                  fontSize: 34,
                  fontFamily: FontRes.bold,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(KetuaCopy.text(context, 'Find people who want what you want.'),
              style: const TextStyle(
                  color: ColorRes.textSecondaryDark, fontSize: 16)),
          const SizedBox(height: 24),
          Text(KetuaCopy.text(context, 'Experiences'),
              style: const TextStyle(
                  fontSize: 22,
                  fontFamily: FontRes.bold,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.sizeOf(context).width < 320 ||
                          MediaQuery.textScalerOf(context).scale(1) > 1.3
                      ? 1
                      : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent:
                      MediaQuery.textScalerOf(context).scale(1) > 1.3
                          ? 220
                          : 166),
              children: [
                _experience(
                    context,
                    'Party tonight',
                    'Music, friends, a good night',
                    Icons.celebration_rounded,
                    () => Get.to(() => const ExperiencesScreen(
                        category: 'party', tonight: true))),
                _experience(
                    context,
                    'Dating',
                    'Find a place within your budget',
                    Icons.restaurant_rounded,
                    () => Get.to(() => const PlacesScreen(category: 'date'))),
                _experience(
                    context,
                    'AirStay',
                    'Stay a night. Stay a week.',
                    Icons.bed_rounded,
                    () => Get.to(() => const PlacesScreen(category: 'stay'))),
                _experience(
                    context,
                    'Massage & spa',
                    'Relax and recharge',
                    Icons.spa_rounded,
                    () => Get.to(() => const PlacesScreen(category: 'spa'))),
                _experience(
                    context,
                    'Reservations',
                    'Your plans in one place',
                    Icons.calendar_month_rounded,
                    () => Get.to(() => const ReservationsScreen())),
                _experience(
                    context,
                    'Events & tickets',
                    'What’s happening nearby',
                    Icons.confirmation_number_rounded,
                    () => Get.to(
                        () => const ExperiencesScreen(category: 'event'))),
              ]),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [
            ActionChip(
                avatar: const Icon(Icons.sensors),
                label: const Text('Live events'),
                onPressed: () =>
                    Get.to(() => const ExperiencesScreen(category: 'live'))),
            ActionChip(
                avatar: const Icon(Icons.confirmation_number_outlined),
                label: const Text('My tickets'),
                onPressed: () =>
                    Get.to(() => const ExperiencesScreen(ticketsOnly: true))),
            ActionChip(
                avatar: const Icon(Icons.lock_open),
                label: const Text('Creator exclusives'),
                onPressed: () => Get.to(() => const PaidContentScreen())),
          ]),
          const SizedBox(height: 24),
          if (goals.isNotEmpty)
            GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.sizeOf(context).width < 320 ||
                            MediaQuery.textScalerOf(context).scale(1) > 1.3
                        ? 1
                        : 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: 235),
                itemCount: goals.length,
                itemBuilder: (_, i) => Material(
                    color: ColorRes.surfaceDark,
                    borderRadius: BorderRadius.circular(28),
                    child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () => Get.to(() => Scaffold(
                            backgroundColor: ColorRes.bgDark,
                            body: SafeArea(
                                child:
                                    FindMatchProfile(initialGoal: goals[i])))),
                        child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      child: Center(
                                          child: Container(
                                              width: 100,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient:
                                                      RadialGradient(colors: [
                                                    colors[i % 4]
                                                        .withValues(alpha: .22),
                                                    Colors.transparent
                                                  ])),
                                              child: Icon(icons[i % 4],
                                                  size: 62,
                                                  color: colors[i % 4])))),
                                  Text(goals[i].title ?? 'Connections',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontFamily: FontRes.bold,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 6),
                                  Text(
                                      KetuaCopy.text(
                                          context, 'Explore connections'),
                                      style: const TextStyle(
                                          color: ColorRes.textSecondaryDark,
                                          fontSize: 12)),
                                ]))))),
          if (goals.isEmpty)
            Padding(
                padding: const EdgeInsets.all(20),
                child: Text(KetuaCopy.text(context,
                    'Your discovery categories will appear here when available.'))),
          const SizedBox(height: 20),
          if (SessionManager.instance.getSettings()?.appdata?.isSocialMedia ==
              1)
            ListTile(
                leading: const Icon(Icons.dynamic_feed_rounded),
                title: Text(KetuaCopy.text(context, 'Community feed')),
                trailing: const Icon(Icons.arrow_forward_rounded),
                onTap: () => Get.to(
                    () => const Scaffold(body: SafeArea(child: FeedScreen())))),
          ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              tileColor: ColorRes.surfaceDark,
              leading: const Icon(Icons.play_circle_outline_rounded,
                  color: Color(0xFFC684FF), size: 34),
              title: Text(KetuaCopy.text(context, 'A glimpse into their world'),
                  style: const TextStyle(
                      fontFamily: FontRes.bold, fontWeight: FontWeight.w700)),
              subtitle: Text(
                  KetuaCopy.text(context, 'Discover moments in short video')),
              trailing: const Icon(Icons.arrow_forward_rounded),
              onTap: () => Get.to(() => const ShortVideoScreen())),
        ]);
  }
}
