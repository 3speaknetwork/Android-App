import 'package:get_storage/get_storage.dart';

class PolicyRepo {
  final GetStorage _storage = GetStorage();
  final String _policyKey = "policy";

  bool isPolicyTermsAccepted() {
    String? result = _storage.read(_policyKey);
    return result != null && result == "true";
  }

  Future<void> writePolicyStatus(bool status) async {
    await _storage.write(_policyKey, status.toString());
  }
}
