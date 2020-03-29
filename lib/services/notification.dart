import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:points_verts/models/walk.dart';
import 'package:points_verts/services/database.dart';
import 'package:points_verts/views/walks/walk_utils.dart';

import 'adeps.dart';
import 'mapbox.dart';
import 'prefs.dart';

const int NEXT_NEAREST_WALK = 0;

class NotificationManager {
  NotificationManager._();

  static final NotificationManager instance = NotificationManager._();
  FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  Future<FlutterLocalNotificationsPlugin> get plugin async {
    if (_flutterLocalNotificationsPlugin != null)
      return _flutterLocalNotificationsPlugin;
    print("creating a new plugin instance");
    var initializationSettingsAndroid =
        AndroidInitializationSettings('ic_stat_name');
    var initializationSettingsIOS = IOSInitializationSettings();
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    _flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    return _flutterLocalNotificationsPlugin;
  }

  scheduleNextNearestWalk(Walk walk, DateTime walkDate) async {
    try {
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'NEXT_NEAREST_WALK',
          'Prochain point à proximité',
          'Indique la veille le prochain point vert Adeps le plus proche de votre domicile',
          importance: Importance.Max,
          priority: Priority.High,
          ticker: 'ticker');
      var iOSPlatformChannelSpecifics = IOSNotificationDetails();
      var platformChannelSpecifics = NotificationDetails(
          androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
      FlutterLocalNotificationsPlugin instance = await plugin;
      await _flutterLocalNotificationsPlugin.cancel(NEXT_NEAREST_WALK);
      DateTime scheduledAt = walkDate.subtract(Duration(hours: 4));
      DateFormat fullDate = DateFormat.yMMMEd("fr_BE");
      if (walk.trip != null) {
        await instance.schedule(
            NEXT_NEAREST_WALK,
            'Point le plus proche le ${fullDate.format(walkDate)}',
            "${walk.city} - ${walk.province} - ${Duration(seconds: walk.trip.duration.round()).inMinutes} min. en voiture",
            scheduledAt,
            platformChannelSpecifics,
            payload: walk.id.toString());
      } else {
        await instance.schedule(
            NEXT_NEAREST_WALK,
            'Point le plus proche le ${fullDate.format(walkDate)}',
            "${walk.city} - ${walk.province}",
            scheduledAt,
            platformChannelSpecifics,
            payload: walk.id.toString());
      }
      print('Notification scheduled for ${scheduledAt.toString()}');
    } catch (err) {
      print("cannot display notification: $err");
    }
  }
}

Future<void> scheduleNextNearestWalkNotification() async {
  String homePos = await PrefsProvider.prefs.getString("home_coords");
  String lastUpdate = await PrefsProvider.prefs.getString("last_walk_update");
  if (homePos == null) return;
  List<String> split = homePos.split(",");
  Position home = Position(
      latitude: double.parse(split[0]), longitude: double.parse(split[1]));
  DBProvider.db.deleteOldWalks();
  List<DateTime> dates = await DBProvider.db.getWalkDates();
  if (dates.length >= 1) {
    if (dates[0].isBefore(DateTime.now())) {
      // don't say that the next walk is tomorrow if it's today, user normally
      // already got the notification yesterday
      return;
    }
    try {
      List<Walk> updatedWalks = await refreshAllWalks(lastUpdate);
      if (updatedWalks.isNotEmpty) {
        await DBProvider.db.insertWalks(updatedWalks);
        PrefsProvider.prefs
            .setString("last_walk_update", DateTime.now().toIso8601String());
      }
    } catch (err) {
      print("Cannot refresh walks list: $err");
    }
    List<Walk> walks = await DBProvider.db.getWalks(dates[0]);
    final Geolocator geolocator = Geolocator();
    for (Walk walk in walks) {
      if (walk.isPositionable()) {
        walk.distance = await geolocator.distanceBetween(
            home.latitude, home.longitude, walk.lat, walk.long);
      }
    }
    walks.sort((a, b) => sortWalks(a, b));
    try {
      await retrieveTrips(home.longitude, home.latitude, walks);
    } catch (err) {
      print("Cannot retrieve trips: $err");
    }
    walks.sort((a, b) => sortWalks(a, b));
    if (walks.length >= 1) {
      await NotificationManager.instance
          .scheduleNextNearestWalk(walks[0], dates[0]);
    }
  }
}