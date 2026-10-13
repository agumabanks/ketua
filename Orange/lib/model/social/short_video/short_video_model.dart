import 'package:ketua_ui/model/user/registration_user.dart';

class ShortVideoModel {
  ShortVideoModel({
    this.id,
    this.video,
    this.thumbnail,
    this.caption,
    this.sound,
    this.durationSec,
    this.likesCount,
    this.commentsCount,
    this.sharesCount,
    this.viewsCount,
    this.hashtags,
    this.isLiked,
    this.user,
  });

  int? id;
  String? video;
  String? thumbnail;
  String? caption;
  String? sound;
  int? durationSec;
  int? likesCount;
  int? commentsCount;
  int? sharesCount;
  int? viewsCount;
  String? hashtags;
  bool? isLiked;
  UserData? user;

  ShortVideoModel.fromJson(dynamic json) {
    id = int.tryParse('${json['id']}');
    video = json['video'];
    thumbnail = json['thumbnail'];
    caption = json['caption'];
    sound = json['sound'];
    durationSec = int.tryParse('${json['duration_sec']}');
    likesCount = int.tryParse('${json['likes_count']}');
    commentsCount = int.tryParse('${json['comments_count']}');
    sharesCount = int.tryParse('${json['shares_count']}');
    viewsCount = int.tryParse('${json['views_count']}');
    hashtags = json['hashtags'];
    isLiked = json['is_liked'] == true || json['is_liked'] == 1 || json['is_liked'] == '1';
    user = json['user'] != null ? UserData.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['video'] = video;
    map['thumbnail'] = thumbnail;
    map['caption'] = caption;
    map['sound'] = sound;
    map['duration_sec'] = durationSec;
    map['likes_count'] = likesCount;
    map['comments_count'] = commentsCount;
    map['shares_count'] = sharesCount;
    map['views_count'] = viewsCount;
    map['hashtags'] = hashtags;
    map['is_liked'] = isLiked;
    if (user != null) map['user'] = user?.toJson();
    return map;
  }
}
