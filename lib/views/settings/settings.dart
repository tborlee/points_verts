import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:points_verts/company_data.dart';
import 'package:points_verts/services/crashlytics.dart';
import 'package:points_verts/views/list_header.dart';
import 'package:points_verts/services/notification.dart';
import 'package:points_verts/views/walks/walk_utils.dart';

import '../../models/address_suggestion.dart';
import '../../services/notification.dart';
import '../../services/prefs.dart';
import '../tile_icon.dart';
import 'about.dart';
import 'debug.dart';
import 'settings_home_select.dart';

class Settings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String? _home;
  bool _useLocation = false;
  bool _showNotification = false;
  bool _crashlyticsEnabled = false;

  _SettingsState();

  void initState() {
    super.initState();
    _retrievePrefs();
  }

  void dispose() {
    super.dispose();
  }

  Future<void> _retrievePrefs() async {
    String? home = await PrefsProvider.prefs.getString("home_label");
    bool useLocation =
        await PrefsProvider.prefs.getBoolean(key: "use_location");
    bool showNotification = await PrefsProvider.prefs
        .getBoolean(key: "show_notification", defaultValue: false);
    bool crashlyticsEnabled = await PrefsProvider.prefs
        .getBoolean(key: "crashlytics_enabled", defaultValue: false);
    setState(() {
      _home = home;
      _useLocation = useLocation;
      _showNotification = showNotification;
      _crashlyticsEnabled = crashlyticsEnabled;
    });
  }

  Future<void> _setHome(AddressSuggestion suggestion) async {
    await PrefsProvider.prefs.setString(
        "home_coords", "${suggestion.latitude},${suggestion.longitude}");
    String? label =
        await PrefsProvider.prefs.setString("home_label", suggestion.address);
    setState(() {
      _home = label;
    });
    if (_showNotification == true) {
      scheduleNextNearestWalkNotification();
    }
  }

  Future<void> _removeHome() async {
    await PrefsProvider.prefs.remove("home_coords");
    await PrefsProvider.prefs.remove("home_label");
    setState(() {
      _home = null;
    });
    NotificationManager.instance.cancelNextNearestWalkNotification();
  }

  Future<void> _setUseLocation(bool newValue) async {
    bool validated = false;
    if (newValue == true) {
      LocationPermission permission = await checkLocationPermission();
      validated = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } else {
      validated = true;
    }
    if (validated) {
      await PrefsProvider.prefs.setBoolean("use_location", newValue);
      setState(() {
        _useLocation = newValue;
      });
    }
  }

  Future<void> _setShowNotification(bool newValue) async {
    await PrefsProvider.prefs.setBoolean("show_notification", newValue);
    if (newValue == true) {
      bool? notificationsAllowed =
          await NotificationManager.instance.requestNotificationPermissions();
      if (notificationsAllowed == true) {
        scheduleNextNearestWalkNotification();
      } else {
        _setShowNotification(false);
        return;
      }
    } else {
      NotificationManager.instance.cancelNextNearestWalkNotification();
    }
    setState(() {
      _showNotification = newValue;
    });
  }

  Future<void> _setCrashlyticsEnabled(bool newValue) async {
    await Crashlytics.toggle(newValue);
    setState(() {
      _crashlyticsEnabled = newValue;
    });
  }

  Future<LocationPermission> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return permission;
    } else if (permission == LocationPermission.denied) {
      return Geolocator.requestPermission();
    } else {
      return permission;
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
            child: Text("Paramètres"),
            onLongPress: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => Debug()))),
      ),
      body: ListView(
        children: <Widget>[
          ListHeader("Tri des points selon leur emplacement"),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
            child: Text(
                "Autorisez l'accès à votre position et/ou indiquez votre domicile pour que l'application affiche en premier les points les plus proches dans la vue 'Calendrier'.",
                style: Theme.of(context).textTheme.caption),
          ),
          SwitchListTile(
            secondary: TileIcon(Icon(Icons.location_on)),
            title: Text("Ma position actuelle"),
            value: _useLocation,
            onChanged: (bool value) {
              _setUseLocation(value);
            },
          ),
          ListTile(
            leading: TileIcon(Icon(Icons.home)),
            title: Text('Mon domicile'),
            subtitle: getHomeLabel(),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>
                      SettingsHomeSelect(_setHome, _removeHome)));
            },
            trailing: _home != null
                ? IconButton(
                    icon: Icon(Icons.delete), onPressed: () => _removeHome())
                : null,
          ),
          Divider(),
          ListHeader("Notifications"),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
            child: Text(
                "L'application peut afficher une notification indiquant le point le plus proche de votre domicile, si ce dernier est définit.",
                style: Theme.of(context).textTheme.caption),
          ),
          SwitchListTile(
            secondary: TileIcon(Icon(Icons.notifications)),
            title: const Text("Notifier la veille (vers 20h)"),
            value: _showNotification,
            onChanged: (bool value) {
              _setShowNotification(value);
            },
          ),
          Divider(),
          ListHeader("Diagnostic"),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
            child: Text(
                "L'envoi automatique de données de diagnostic nous permet d'améliorer l'application.",
                style: Theme.of(context).textTheme.caption),
          ),
          SwitchListTile(
            secondary: TileIcon(Icon(Icons.bug_report)),
            title: const Text("Envoi de rapports  "),
            value: _crashlyticsEnabled,
            onChanged: (bool value) {
              _setCrashlyticsEnabled(value);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.help),
            title: Text("Assistance"),
            onTap: () => launchURL(assistanceUrl),
          ),
          ListTile(
            leading: Icon(Icons.security),
            title: Text("Charte de la vie privée"),
            onTap: () => launchURL(privacyUrl),
          ),
          About()
        ],
      ),
    );
  }

  Widget getHomeLabel() {
    if (_home == null) {
      return Text("Aucun - appuyez ici pour le définir");
    } else {
      return Text(_home!, style: TextStyle(fontSize: 12.0));
    }
  }
}
