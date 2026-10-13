import 'package:flutter/material.dart';
import 'package:ketua_ui/common/fullname_with_age.dart';
import 'package:ketua_ui/common/gradient_widget.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/utils/asset_res.dart';
import 'package:ketua_ui/utils/color_res.dart';

class ProfileDetailCard extends StatelessWidget {
  final VoidCallback onImageTap;
  final UserData? userData;
  const ProfileDetailCard(
      {super.key, required this.userData, required this.onImageTap});
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onImageTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 7, 10, 10),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xAA101016), Color(0xED101016)])),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if(userData?.superLikeReceived==true)const Chip(avatar:Icon(Icons.star_rounded,color:Color(0xFFAAC8FF)),label:Text('Super Liked you')),
          FullnameWithAge(userData: userData, fontSize: 26),
          Row(children: [
            GradientWidget(
                child: Image.asset(AssetRes.locationPin,
                    height: 13.5, width: 10.5)),
            const SizedBox(width: 6),
            Expanded(
                child: Text(
                    userData?.publicDistanceKm != null
                        ? '${userData!.distanceLabel} · ${userData!.city ?? ''}'
                        : userData?.address ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: ColorRes.white, fontSize: 13)))
          ]),
          const SizedBox(height: 6),
          Text(userData?.bio ?? '',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: ColorRes.white, fontSize: 13)),
        ]),
      ));
}
