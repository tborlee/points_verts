import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:points_verts/services/notification.dart';
import 'package:points_verts/services/prefs.dart';
import 'package:points_verts/views/loading.dart';
import 'package:points_verts/views/walks/walk_list_error.dart';
import 'package:points_verts/views/walks/walk_utils.dart';

import 'services/crashlytics.dart';
import 'views/directory/walk_directory_view.dart';
import 'views/settings/settings.dart';
import 'views/walks/walks_view.dart';

class WalksHomeScreen extends StatefulWidget {
  @override
  _WalksHomeScreenState createState() => _WalksHomeScreenState();
}

class _WalksHomeScreenState extends State<WalksHomeScreen>
    with WidgetsBindingObserver {
  List<Widget> _pages = [WalksView(), WalkDirectoryView(), Settings()];
  int _selectedIndex = 0;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    _crashlyticsCheck();
    fetchData().then((_) {
      _initPlatformState();
    }).catchError((err) {
      print("error init state");
    });
    PrefsProvider.prefs.remove("last_selected_date");
    WidgetsBinding.instance!.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  Future<void> fetchData() async {
    setState(() {
      _error = false;
      _loading = true;
    });
    updateWalks().then((_) {
      setState(() {
        _loading = false;
      });
    }).catchError((err) {
      print("error fetch data");
      setState(() {
        _loading = false;
        _error = true;
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchData();
    }
  }

  Future<void> _crashlyticsCheck() async {
    PrefsProvider.prefs
        .getBooleanNullable("crashlytics_enabled")
        .then((prompt) async {
      if (prompt == null) {
        Crashlytics.crashlyticsPrompt(context);
      }
    });
  }

  Future<void> _initPlatformState() async {
    BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 60 * 6,
            // four times per day
            stopOnTerminate: false,
            enableHeadless: true,
            requiredNetworkType: NetworkType.ANY,
            startOnBoot: true), (String taskId) async {
      print("[BackgroundFetch] taskId: $taskId");
      try {
        await scheduleNextNearestWalkNotification();
        await PrefsProvider.prefs.setString(
            "last_background_fetch", DateTime.now().toUtc().toIso8601String());
      } catch (err) {
        print("Cannot schedule next nearest walk notification: $err");
      }
      BackgroundFetch.finish(taskId);
    }, (String taskId) async {
      print("[BackgroundFetch] TIMEOUT taskId: $taskId");
      BackgroundFetch.finish(taskId);
    }).then((int status) {
      print('[BackgroundFetch] configure success: $status');
    }).catchError((e) {
      print('[BackgroundFetch] configure ERROR: $e');
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: "Calendrier"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.import_contacts), label: "Annuaire"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Paramètres"),
        ],
      ),
      body: _error
          ? WalkListError(fetchData)
          : _loading
              ? Loading()
              : _pages[_selectedIndex],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
