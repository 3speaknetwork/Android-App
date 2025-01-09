import 'dart:convert';

class ErrorModel {
  final String error;

  ErrorModel({
    required this.error,
  });

  factory ErrorModel.fromJson(Map<String, dynamic> json) => ErrorModel(
        error: json["error"],
      );

  Map<String, dynamic> toJson() => {
        "error": error,
      };

  factory ErrorModel.fromJsonString(String str) =>
      ErrorModel.fromJson(json.decode(str));

  String errorModelToJson(ErrorModel data) => json.encode(data.toJson());
}
