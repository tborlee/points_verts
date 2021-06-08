import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:points_verts/services/database.dart';
import 'package:points_verts/services/notification.dart';
import 'package:points_verts/services/prefs.dart';
import 'package:points_verts/views/walks/walk_details_view.dart';
import 'package:points_verts/views/walks/walk_utils.dart';

import 'package:points_verts/walks_home_screen.dart';

import 'models/walk.dart';

void backgroundFetchHeadlessTask(String taskId) async {
  print('[BackgroundFetch] Headless event received.');
  try {
    await dotenv.load(fileName: '.env');
    await updateWalks();
    await scheduleNextNearestWalkNotification();
    await PrefsProvider.prefs.setString(
        "last_background_fetch", DateTime.now().toUtc().toIso8601String());
  } catch (err) {
    print("Cannot schedule next nearest walk notification: $err");
  }
  BackgroundFetch.finish(taskId);
}

void main() async {
  await dotenv.load(fileName: '.env');
  WidgetsFlutterBinding.ensureInitialized();
  //TODO: improve how we initialize these singletons (get_it package?)
  await NotificationManager.instance.plugin;
  await DBProvider.db.database;
  runApp(new MyApp());
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

class MyApp extends StatelessWidget {
  static final navigatorKey = new GlobalKey<NavigatorState>();

  static redirectToWalkDetails(int walkId) async {
    Walk? walk = await DBProvider.db.getWalk(walkId);
    if (walk != null) {
      MyApp.navigatorKey.currentState!
          .push(MaterialPageRoute(builder: (context) => WalkDetailsView(walk)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('fr', 'BE'),
        const Locale('fr', 'FR'),
        const Locale('fr', 'LU'),
      ],
      navigatorKey: navigatorKey,
      title: 'Points Verts',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      darkTheme:
          ThemeData(brightness: Brightness.dark, primarySwatch: Colors.green),
      home: WalksHomeScreen(),
    );
  }
}
