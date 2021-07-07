import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'prefs.dart';

const String TAG = "dev.alpagaga.points_verts.Crashlytics";

class Crashlytics {
  static Future<void> initialize() async {
      toggle(await PrefsProvider.prefs
          .getBoolean(key: "crashlytics_enabled", defaultValue: false));
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  }

  static Future<bool?> crashlyticsPrompt(BuildContext context) async {
    bool? result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text('Diagnostic'),
              content: const Text(
                  "L'envoi automatique de données de diagnostic nous permet d'améliorer l'application."),
              actions: <Widget>[
                TextButton(
                  child: const Text('Autoriser'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
                TextButton(
                  child: const Text('Refuser'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
              ]);
        });
    if (result != null) {
      toggle(result);
    }
  }

  static Future<void> toggle(bool value) async {
    await PrefsProvider.prefs.setBoolean("crashlytics_enabled", value);
    if (kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    } else {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(value);
    }
    log("Crashlytics is now " + (value ? "enabled" : "disabled"), name: TAG);
  }
}
