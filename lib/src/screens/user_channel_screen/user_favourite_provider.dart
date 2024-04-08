import 'package:get_storage/get_storage.dart';

class UserFavoriteProvider {
  final box = GetStorage();
  final String _usersLocalKey = '_userLocalKey';

  List getBookmarkedUsers() {
    final String key = _usersLocalKey;
    if (box.read(key) != null) {
      List items = box.read(key);
      return items;
    } else {
      return [];
    }
  }

  //check if the liked podcast single episode is present locally
  bool isUserPresentLocally(String userName) {
    final String key = _usersLocalKey;
    if (box.read(key) != null) {
      List json = box.read(key);
      int index = json.indexWhere((element) => element == userName);
      return index != -1;
    } else {
      return false;
    }
  }

  //sotre the single podcast episode locally if user likes it
  void storeLikedUserLocally(String userName, {bool forceRemove = false}) {
    final String key = _usersLocalKey;
    if (box.read(key) != null) {
      List json = box.read(key);
      int index = json.indexWhere((element) => element == userName);
      if (index == -1 && !forceRemove) {
        json.add(userName);
        box.write(key, json);
      } else {
        json.removeWhere((element) => element == userName);
        box.write(key, json);
      }
    } else {
      box.write(key, [userName]);
    }
    print(box.read(key));
  }
}
