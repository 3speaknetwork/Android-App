import 'dart:convert';

class ReportUserModel {
  final String username;
  final String? reason;

  const ReportUserModel({
    this.reason,
    required this.username,
  });

  factory ReportUserModel.fromJson(Map<String, dynamic> json) =>
      ReportUserModel(
        username: json["name"],
      );
  factory ReportUserModel.fromRawJson(String str) =>
      ReportUserModel.fromJson(json.decode(str));

  static List<ReportUserModel> fromRawListJson(String str) =>
      List<ReportUserModel>.from(
          json.decode(str).map((x) => ReportUserModel.fromJson(x)));

  Map<String, dynamic> toJson() => {'username': username, "reason": reason};

  String toRawJson() => json.encode(toJson());
}
