import 'package:acela/src/models/user_account/action_response.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/report/model/report/report_post.dart';
import 'package:acela/src/screens/report/model/report_user_model.dart';
import 'package:acela/src/utils/communicator.dart';
import 'package:flutter/material.dart';

class ReportController extends ChangeNotifier {
  ReportController();

  HiveUserData? userData;

  List<ReportPostModel> reportedPosts = [];
  List<ReportUserModel> reportedUsers = [];

  bool shouldRefresh = false;

  void init() async {
    if (this.userData != null && this.userData?.accessToken != null) {
      List data = await Future.wait([
        Communicator().readReportedPosts(userData!),
        Communicator().readReportedUsers(userData!)
      ]);
      ActionListDataResponse<ReportPostModel> reportPostResponse =
          data.first as ActionListDataResponse<ReportPostModel>;
      ActionListDataResponse<ReportUserModel> reportUserResponse =
          data.elementAt(1) as ActionListDataResponse<ReportUserModel>;
      if (reportPostResponse.isSuccess) {
        reportedPosts = reportPostResponse.data!;
        shouldRefresh = true;
      }
      if (reportUserResponse.isSuccess) {
        reportedUsers = reportUserResponse.data!;
        shouldRefresh = true;
      }
      notifyListeners();
    }
  }

  Future<void> reportUser(ReportUserModel report,
      {required VoidCallback onSuccess,
      required VoidCallback onFailure,
      required VoidCallback onLogout,
      required Function(String) showToast}) async {
    if (userData?.accessToken == null) {
      showToast("Session expired! Please log in again");
      onLogout();
      onFailure();
    } else {
      ActionSingleDataResponse<bool> response =
          await Communicator().reportUser(report, userData!);
      if (response.isSuccess) {
        reportedUsers = [...reportedUsers, report];
        showToast("Report has been submitted successfully");
        onSuccess();
        shouldRefresh = true;
        notifyListeners();
      } else {
        showToast(response.errorMessage);
        onFailure();
      }
    }
  }

  void updateHiveUserData(HiveUserData newData) {
    userData = newData;
    reportedPosts.clear();
    reportedUsers.clear();
    init();
  }

  Future<void> reportReply(ReportPostModel report,
      {required VoidCallback onSuccess,
      required VoidCallback onFailure,
      required VoidCallback onLogout,
      required Function(String) showToast}) async {
    if (userData?.accessToken == null) {
      showToast("Session expired! Please log in again");
      onLogout();
      onFailure();
    } else {
      ActionSingleDataResponse<bool> response =
          await Communicator().reportPost(report, userData!);
      if (response.isSuccess) {
        reportedPosts = [...reportedPosts, report];
        showToast("Report has been submitted successfully");
        onSuccess();
        shouldRefresh = true;
        notifyListeners();
      } else {
        showToast(response.errorMessage);
        onFailure();
      }
    }
  }

  void turnRefreshOff() {
    shouldRefresh = false;
    notifyListeners();
  }
}
