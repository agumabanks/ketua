// To parse this JSON data, do
//
//     final filterProfileModel = filterProfileModelFromJson(jsonString);

import 'dart:convert';

import 'package:ketua_ui/model/user/registration_user.dart';

FilterProfileModel filterProfileModelFromJson(String str) =>
    FilterProfileModel.fromJson(json.decode(str));

String filterProfileModelToJson(FilterProfileModel data) =>
    json.encode(data.toJson());

class FilterProfileModel {
  bool status;
  String message;
  int? total;
  List<UserData> data;

  FilterProfileModel({
    required this.status,
    required this.message,
    required this.total,
    required this.data,
  });

  factory FilterProfileModel.fromJson(dynamic json) {
    return FilterProfileModel(
      status: json["status"] == true,
      message: json["message"]?.toString() ?? '',
      total: int.tryParse('${json["total"]}'),
      data: (json["data"] is List ? json["data"] as List : const []).map((x) => UserData.fromJson(x)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "total": total,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}
