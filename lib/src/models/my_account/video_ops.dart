import 'dart:convert';

import 'package:acela/src/utils/safe_convert.dart';

class VideoOpsResponse {
  final bool success;
  VideoOpsResponse({
    required this.success,
  });

  factory VideoOpsResponse.fromJson(Map<String, dynamic>? json) =>
      VideoOpsResponse(
        success: asBool(json, 'success'),
      );

  factory VideoOpsResponse.fromJsonString(String jsonString) =>
      VideoOpsResponse.fromJson(json.decode(jsonString));
}

class ErrorResponse {
  final String? error;
  ErrorResponse({
    required this.error,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic>? json) => ErrorResponse(
        error: asString(json, 'error'),
      );

  factory ErrorResponse.fromJsonString(String jsonString) =>
      ErrorResponse.fromJson(json.decode(jsonString));
}

class BeneficiariesJson {
  final String account;
  int weight;
  final String src;
  final bool isDefault;

  BeneficiariesJson({
    required this.account,
    required this.weight,
    required this.src,
    this.isDefault = false
  });

  factory BeneficiariesJson.fromJson(Map<String, dynamic>? json) =>
      BeneficiariesJson(
        account: asString(json, 'account'),
        weight: asInt(json, 'weight'),
        src: asString(json, 'src'),
      );

  static List<BeneficiariesJson> fromJsonString(String jsonString) {
    var list = json.decode(jsonString) as List;
    var listNew = list.map((e) => BeneficiariesJson.fromJson(e)).toList();
    return listNew;
  }

  static String toJsonString(List<BeneficiariesJson> data) {
    return json.encode(data);
  }

  Map<String, dynamic> toJson() {
    return {
      'account': account,
      'weight': weight,
      'src': src,
    };
  }
}
