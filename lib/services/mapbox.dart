import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../models/address_suggestion.dart';
import '../models/trip.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/walk.dart';
import 'trip_cache_manager.dart';

String _token = DotEnv().env['MAPBOX_TOKEN'];

class Mapbox extends StatefulWidget {
  Mapbox(
      {this.centerLat = 50.3155646,
        this.centerLong = 5.009682,
        this.zoom = 7.5,
        this.interactive = true,
        this.symbols});

  final double centerLat;
  final double centerLong;
  final double zoom;
  final bool interactive;
  final List<CircleOptions> symbols;

  @override
  _MapboxState createState() => _MapboxState();
}

class _MapboxState extends State<Mapbox> {
  MapboxMapController _mapController;

  @override
  void dispose() {
    if(_mapController != null) {
      _mapController.dispose();
    }
    super.dispose();
  }

  void _onMapCreated(MapboxMapController controller) async {
    print("onMapCreated");
    this._mapController = controller;
    await _mapController.clearSymbols();
    await _mapController.clearCircles();
    _mapController..onCircleTapped.add(_onCircleTapped);
  }

  void _onCircleTapped(Circle circle) {
    print(circle);
  }

  void _onMapIdle() {
    print("_onMapIdle");
    _mapController.clearCircles();
  }

  void _onStyleLoadedCallback() async {
    print("_onStyleLoadedCallback");
    if (mounted && widget.symbols != null && _mapController != null) {
      for (CircleOptions symbol in widget.symbols) {
        await _mapController.addCircle(symbol);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapboxMap(
      accessToken: _token,
      onMapCreated: _onMapCreated,
      onMapIdle: _onMapIdle,
      onStyleLoadedCallback: _onStyleLoadedCallback,
      tiltGesturesEnabled: widget.interactive,
      rotateGesturesEnabled: widget.interactive,
      scrollGesturesEnabled: widget.interactive,
      zoomGesturesEnabled: widget.interactive,
      initialCameraPosition: CameraPosition(
          target: LatLng(widget.centerLat, widget.centerLong),
          zoom: widget.zoom),
    );
  }
}


Future<void> retrieveTrips(
    double fromLong, double fromLat, List<Walk> walks) async {
  String origin = "$fromLong,$fromLat";
  String destinations = "";
  for (int i = 0; i < min(walks.length, 5); i++) {
    Walk walk = walks[i];
    if (walk.isPositionable()) {
      destinations = destinations + ";${walk.long},${walk.lat}";
    }
  }
  if (destinations.isEmpty) {
    return;
  }
  final String url =
      "https://api.mapbox.com/directions-matrix/v1/mapbox/driving/$origin$destinations?sources=0&annotations=distance,duration&access_token=$_token";
  final http.Response response = await TripCacheManager().getData(url);
  final decoded = json.decode(response.body);
  final distances =
      decoded['distances']?.length == 1 ? decoded['distances'][0] : null;
  final durations =
      decoded['durations']?.length == 1 ? decoded['durations'][0] : null;
  if (distances != null && durations != null) {
    for (int i = 0; i < min(walks.length, 5); i++) {
      Walk walk = walks[i];
      if (walk.isPositionable() && distances.length >= i) {
        walk.trip =
            Trip(distance: distances[i + 1], duration: durations[i + 1]);
      }
    }
  }
}

Future<List<AddressSuggestion>> retrieveSuggestions(
    String country, String search) async {
  if (search.isNotEmpty) {
    final String url =
        "https://api.mapbox.com/geocoding/v5/mapbox.places/$search.json?access_token=$_token&country=$country&language=fr_BE&limit=10&types=address,poi";
    final http.Response response = await http.get(url);
    var decoded = json.decode(response.body);
    List<AddressSuggestion> results = List<AddressSuggestion>();
    if (decoded['features'] != null) {
      for (var result in decoded['features']) {
        results.add(AddressSuggestion(
            text: result['text'],
            address: result['place_name'],
            longitude: result['center'][0],
            latitude: result['center'][1]));
      }
    }
    return results;
  } else {
    return List<AddressSuggestion>();
  }
}

Future<String> retrieveAddress(double long, double lat) async {
  final String url =
      "https://api.mapbox.com/geocoding/v5/mapbox.places/$long,$lat.json?access_token=$_token";
  final http.Response response = await http.get(url);
  var decoded = json.decode(response.body);
  if (decoded['features'].length > 0) {
    return decoded['features'][0]['place_name'];
  } else {
    return null;
  }
}

Widget retrieveStaticImage(
    double long, double lat, int width, int height, Brightness brightness,
    {double zoom = 16.0}) {
  final String style = brightness == Brightness.dark ? 'dark-v10' : 'light-v10';
  final String url =
      "https://api.mapbox.com/styles/v1/mapbox/$style/static/pin-l($long,$lat)/$long,$lat,$zoom,0,0/${width}x$height@2x?access_token=$_token";
  return CachedNetworkImage(
    imageUrl: url,
    progressIndicatorBuilder: (context, url, downloadProgress) => Center(
        child: CircularProgressIndicator(value: downloadProgress.progress)),
    errorWidget: (context, url, error) => Icon(Icons.error),
  );
}
