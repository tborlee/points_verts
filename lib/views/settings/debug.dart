import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:points_verts/services/firebase.dart';
import 'package:points_verts/services/notification.dart';
import 'package:points_verts/services/prefs.dart';

class Debug extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Debug"),
        ),
        body: ListView(
          children: <Widget>[
            _LastWalkUpdateTile(),
            Divider(height: 0.5),
            _GeoPosTile(),
            Divider(height: 0.5),
            _PendingNotificationsTile(),
            Divider(height: 0.5),
            _LastBackgroundFetch(),
            Divider(height: 0.5),
            _FirebaseToken()
          ],
        ));
  }
}

class _LastWalkUpdateTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PrefsProvider.prefs.getString("last_walk_update"),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return ListTile(
            title: Text("Dernière mise à jour de la liste des marches"),
            subtitle: Text("${formatDate(snapshot.data)} (heure locale)"),
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }
}

class _GeoPosTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PrefsProvider.prefs.getString("home_coords"),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          return ListTile(
            title: Text("Coordonnées GPS de l'emplacement de référence"),
            subtitle: Text(snapshot.data),
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }
}

class _PendingNotificationsTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: NotificationManager.instance.pendingNotifications(),
        builder: (BuildContext context,
            AsyncSnapshot<List<PendingNotificationRequest>> snapshot) {
          if (snapshot.hasData) {
            List<PendingNotificationRequest> requests = snapshot.data;
            if (requests.length > 0) {
              return ListTile(
                isThreeLine: true,
                title: Text("Prochaine notification planifiée"),
                subtitle: Text(
                  requests[0].title + '\n' + requests[0].body,
                  style: TextStyle(fontSize: 12.0),
                ),
              );
            }
          }
          return SizedBox.shrink();
        });
  }
}

class _LastBackgroundFetch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: PrefsProvider.prefs.getString("last_background_fetch"),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return ListTile(
              title: Text("Dernière actualisation en arrière-plan"),
              subtitle: Text("${formatDate(snapshot.data)} (heure locale)"),
            );
          }
          return SizedBox.shrink();
        });
  }
}

class _FirebaseToken extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: GetIt.I.getAsync<FirebaseManager>(),
        builder:
            (BuildContext context, AsyncSnapshot<FirebaseManager> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return ListTile(
              title: Text("Jeton Firebase"),
              subtitle: FutureBuilder(
                  future: snapshot.data.getToken(),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Text(snapshot.data);
                    }
                    return SizedBox.shrink();
                  }),
            );
          }
          return SizedBox.shrink();
        });
  }
}

String formatDate(String date) {
  DateFormat dateFormat = new DateFormat.MMMMEEEEd("fr").add_Hms();
  DateTime dateTime = DateTime.parse(date).toLocal();
  return dateFormat.format(dateTime);
}
