import 'dart:convert';

enum ResponseStatus { success, failed, unknown }

class ActionSingleDataResponse<T> {
  final String? id;
  final String? type;
  final T? data;
  final bool valid;
  final String errorMessage;
  final ResponseStatus status;
  final bool isSuccess;

  ActionSingleDataResponse(
      {this.id,
      this.type,
      this.data,
      this.isSuccess = false,
      this.valid = false,
      required this.errorMessage,
      required this.status});

  factory ActionSingleDataResponse.fromJsonString(
          String string, T Function(Map<String, dynamic>) fromJson) =>
      ActionSingleDataResponse.fromJson(json.decode(string), fromJson);

  factory ActionSingleDataResponse.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    return ActionSingleDataResponse(
      id: json['id'] as String,
      type: json['type'] as String, 
      data: fromJson(json['data']),
      valid: json['valid'] as bool,
      status: json['valid'] && json['error'].isEmpty
          ? ResponseStatus.success
          : ResponseStatus.failed,
      isSuccess: json['valid'] && json['error'].isEmpty,
      errorMessage: json['error'] as String,
    );
  }
}

class ActionListDataResponse<T> {
  final List<T>? data;
  final bool valid;
  final String errorMessage;
  final ResponseStatus status;
  final bool isSuccess;

  ActionListDataResponse({
    this.data,
    this.isSuccess = false,
    this.valid = false,
    required this.status,
    required this.errorMessage,
  });

  factory ActionListDataResponse.fromJsonString(
          String string, T Function(dynamic) fromJson) =>
      ActionListDataResponse.fromJson(json.decode(string), fromJson);

  factory ActionListDataResponse.fromJson(
      Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return ActionListDataResponse(
      data: (json['data'] as List<dynamic>?)
              ?.map((dynamic item) => fromJson(item))
              .toList() ??
          [],
      status: json['valid'] && json['error'].isEmpty
          ? ResponseStatus.success
          : ResponseStatus.failed,
      isSuccess: json['valid'] && json['error'].isEmpty && json['data'] != null,
      valid: json['valid'] as bool,
      errorMessage: json['error'] as String,
    );
  }
}
