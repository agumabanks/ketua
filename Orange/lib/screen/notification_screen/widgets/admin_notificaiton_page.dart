import 'updates_empty.dart';
import 'package:flutter/material.dart';
import 'package:ketua_ui/common/common_fun.dart';
import 'package:ketua_ui/model/notification/admin_notification.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/font_res.dart';
import 'package:ketua_ui/utils/style_res.dart';

class AdminNotificationPage extends StatelessWidget {
  final List<AdminNotificationData> adminNotification;
  final ScrollController controller;

  const AdminNotificationPage(
      {super.key, required this.adminNotification, required this.controller});

  @override
  Widget build(BuildContext context) {
    return adminNotification.isEmpty
        ? const UpdatesEmpty(platform: true)
        : ListView.builder(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 24 + MediaQuery.paddingOf(context).bottom),
            itemCount: adminNotification.length,
            itemBuilder: (context, index) {
              AdminNotificationData adminData = adminNotification[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: StyleRes.linearGradient),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${adminData.title}',
                                  style: const TextStyle(
                                    fontFamily: FontRes.bold,
                                    fontSize: 15,
                                    color: ColorRes.textPrimaryDark,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                CommonFun.timeAgo(DateTime.tryParse(
                                        '${adminData.createdAt}') ??
                                    DateTime.now()),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: ColorRes.grey2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${adminData.message}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: ColorRes.textSecondaryDark,
                              height: 1.4,
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
  }
}
