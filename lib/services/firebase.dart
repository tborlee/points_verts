import 'package:firebase_messaging/firebase_messaging.dart';

import 'dart:developer';

const String TAG = "dev.alpagaga.points_verts.FirebaseManager";

class FirebaseManager {
  FirebaseMessaging _messaging;

  FirebaseManager() {
    _messaging = FirebaseMessaging.instance;
    _messaging.getToken().then((token) {
      log("Firebase Messaging token: $token", name: TAG);
    });
  }

  Future<void> subscribeToTopic(String topicName) async {
    try {
      await _messaging.subscribeToTopic(topicName);
      log("Subscribed to topic '$topicName'", name: TAG);
    } catch (err) {
      print("cannot subscribe to topic '$topicName': $err");
    }
  }

  Future<void> unsubscribeFromTopic(String topicName) async {
    try {
      await _messaging.unsubscribeFromTopic(topicName);
      log("Unsubscribed from topic '$topicName'", name: TAG);
    } catch (err) {
      print("cannot unsubscribe from topic '$topicName': $err");
    }
  }

  Future<String> getToken() async {
    try {
      String token = await _messaging.getToken();
      log("retrieved token '$token'", name: TAG);
      return token;
    } catch (err) {
      print("Cannot get token: $err");
    }
    return null;
  }
}
