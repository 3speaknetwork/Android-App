import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/utils/graphql/gql_communicator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LogoutProvider {
  Future<void> call() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'username');
    await storage.delete(key: 'postingKey');
    await storage.delete(key: 'accessToken');
    await storage.delete(key: 'postingAuth');
    await storage.delete(key: 'cookie');
    await storage.delete(key: 'hasId');
    await storage.delete(key: 'hasExpiry');
    await storage.delete(key: 'hasAuthKey');
    String resolution = await storage.read(key: 'resolution') ?? '480p';
    String rpc = await storage.read(key: 'rpc') ?? 'api.hive.blog';
    String union =
        await storage.read(key: 'union') ?? GQLCommunicator.defaultGQLServer;
    String? lang = await storage.read(key: 'lang');
    var newUserData = HiveUserData(
      username: null,
      postingKey: null,
      keychainData: null,
      cookie: null,
      accessToken: null,
      postingAuthority: null,
      resolution: resolution,
      rpc: rpc,
      union: union,
      loaded: true,
      language: lang,
    );
    server.updateHiveUserData(newUserData);
  }
}
