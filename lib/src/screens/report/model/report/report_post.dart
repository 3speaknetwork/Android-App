import 'dart:convert';

class ReportPostModel {
  final String username;
  final String permlink;
  final String? reason;

  const ReportPostModel({
    required this.permlink,
    this.reason,
    required this.username,
  });

  factory ReportPostModel.fromJson(Map<String, dynamic> json) =>
      ReportPostModel(
        username: json["name"],
        permlink: json["permlink"],
      );

  factory ReportPostModel.fromRawJson(String str) =>
      ReportPostModel.fromJson(json.decode(str));

  static List<ReportPostModel> fromRawListJson(String str) =>
      List<ReportPostModel>.from(
          json.decode(str).map((x) => ReportPostModel.fromJson(x)));

  Map<String, dynamic> toJson() =>
      {'username': username, 'permlink': permlink, "reason": reason};

  String toRawJson() => json.encode(toJson());
}
