// import 'package:acela/firebase_options.dart';
import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/global_provider/image_resolution_provider.dart';
import 'package:acela/src/global_provider/video_setting_provider.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/podcast/controller/podcast_controller.dart';
import 'package:acela/src/screens/podcast/controller/podcast_player_controller.dart';
import 'package:acela/src/screens/upload/video/controller/video_upload_controller.dart';
import 'package:acela/src/utils/graphql/gql_communicator.dart';
import 'package:acela/src/utils/routes/app_router.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:audio_service/audio_service.dart';
import 'package:upgrader/upgrader.dart';
import 'src/screens/podcast/widgets/audio_player/audio_player_core_controls.dart';

Future<void> main() async {
  await dotenv.load(fileName: "dotenv");
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  await GetStorage.init();
  await FlutterDownloader.initialize(
    debug: true,
    ignoreSsl: true,
  );
  GetAudioPlayer getAudioPlayer = GetAudioPlayer();
  getAudioPlayer.audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandlerImpl(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ryanheise.myapp.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );
  // await Upgrader.clearSavedSettings(); // for debugging
  await Upgrader.sharedInstance.initialize();
  if (kDebugMode) {
    runApp(const MyApp());
  } else {
    // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // PlatformDispatcher.instance.onError = (error, stack) {
    //   FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    //   return true;
    // };
    runApp(MyApp());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<void> _futureToLoadData;

  // late final FirebaseMessaging _messaging;
  // Create storage

  Widget futureBuilder(Widget withWidget) {
    return FutureBuilder(
      future: _futureToLoadData,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Firebase not initialized');
        } else if (snapshot.connectionState == ConnectionState.done) {
          return withWidget;
        } else {
          return MaterialApp(
            title: '3Speak',
            home: Scaffold(
              appBar: AppBar(title: const Text('3Speak')),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
      },
    );
  }

  void logEvent() async {
    // await FirebaseAnalytics.instance.logEvent(
    //   name: 'app_entry',
    // );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => PodcastController(),
        ),
        ChangeNotifierProvider(
            lazy: false, create: (context) => VideoSettingProvider()),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => SettingsProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => PodcastPlayerController(),
        ),
        ChangeNotifierProvider(create: (context) => VideoUploadController())
      ],
      child: OverlaySupport.global(
        child: futureBuilder(
          StreamProvider<HiveUserData>.value(
            value: server.hiveUserData,
            initialData: HiveUserData(
              resolution: '480p',
              keychainData: null,
              accessToken: null,
              postingKey: null,
              username: null,
              cookie: null,
              postingAuthority: null,
              rpc: 'api.hive.blog',
              union: GQLCommunicator.defaultGQLServer,
              loaded: false,
              language: null,
            ),
            child: StreamProvider<bool>.value(
              value: server.theme,
              initialData: true,
              child: const AcelaApp(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    logEvent();
    _futureToLoadData = loadData();
  }

  Future<void> loadData() async {
    const storage = FlutterSecureStorage();
    String? username = await storage.read(key: 'username');
    String? postingKey = await storage.read(key: 'postingKey');
    String? cookie = await storage.read(key: 'cookie');
    String? accessToken = await storage.read(key: 'accessToken');
    String? hasId = await storage.read(key: 'hasId');
    String? hasExpiry = await storage.read(key: 'hasExpiry');
    String? hasAuthKey = await storage.read(key: 'hasAuthKey');
    String resolution = await storage.read(key: 'resolution') ?? '480p';
    String rpc = await storage.read(key: 'rpc') ?? 'api.hive.blog';
    String? postingAuth = await storage.read(key: 'postingAuth');
    String union =
        await storage.read(key: 'union') ?? GQLCommunicator.defaultGQLServer;
    if (union == 'threespeak-union-graph-ql.sagarkothari88.one') {
      await storage.write(
          key: 'union', value: GQLCommunicator.defaultGQLServer);
      union = GQLCommunicator.defaultGQLServer;
    }
    String? lang = await storage.read(key: 'lang');
    server.updateHiveUserData(
      HiveUserData(
        username: username,
        postingKey: postingKey,
        keychainData: hasId != null &&
                hasId.isNotEmpty &&
                hasExpiry != null &&
                hasExpiry.isNotEmpty &&
                hasAuthKey != null &&
                hasAuthKey.isNotEmpty
            ? HiveKeychainData(
                hasAuthKey: hasAuthKey,
                hasExpiry: hasExpiry,
                hasId: hasId,
              )
            : null,
        cookie: cookie,
        accessToken: accessToken,
        postingAuthority: postingAuth,
        resolution: resolution,
        rpc: rpc,
        union: union,
        loaded: true,
        language: lang,
      ),
    );
  }
}

class AcelaApp extends StatelessWidget {
  const AcelaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var isDarkMode = Provider.of<bool>(context);
    return MaterialApp.router(
      title: 'Acela - 3Speak App',
      routerConfig: AppRouter.router,
      theme: isDarkMode
          ? ThemeData.dark().copyWith(
              primaryColor: Colors.deepPurple,
              primaryColorLight: Colors.white,
              primaryColorDark: Colors.black,
              scaffoldBackgroundColor: Colors.black,
              cardTheme: CardTheme(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4))),
                  color: Colors.grey.shade900),
            )
          : ThemeData.light().copyWith(
              primaryColor: Colors.deepPurple,
              primaryColorLight: Colors.black,
              primaryColorDark: Colors.white,
              cardTheme: CardTheme(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4))),
                  color: Colors.grey.shade200),
            ),
      debugShowCheckedModeBanner: false,
    );
  }
}
