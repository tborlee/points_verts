import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../tile_icon.dart';
import 'geo_button.dart';
import '../../models/walk.dart';
import 'walk_details_view.dart';
import 'walk_icon.dart';
import '../../models/weather.dart';
import '../../services/openweather.dart';

bool smallScreen = window.physicalSize.width <= 640;

class WalkTile extends StatelessWidget {
  WalkTile(this.walk);

  final Walk walk;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: smallScreen,
      leading: _weatherIcon(),
      title: Text(walk.city),
      subtitle: Text("${walk.type} - ${walk.province}"),
      enabled: !walk.isCancelled(),
      onTap: () => Navigator.push(context, _pageRoute()),
      trailing: walk.isCancelled() ? Text("Annulé") : GeoButton(walk: walk),
    );
  }

  Widget _weatherIcon() {
    if (walk.isCancelled()) {
      return TileIcon(WalkIcon(walk));
    }
    return FutureBuilder(
        future: walk.weathers,
        builder: (BuildContext context, AsyncSnapshot<List<Weather>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData && snapshot.data.length > 0) {
              Weather weather = snapshot.data[0];
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  getWeatherIcon(weather, context),
                  Text("${weather.temperature.round()}°"),
                ],
              );
            }
          }
          return TileIcon(WalkIcon(walk));
        });
  }

  PageRoute _pageRoute() {
      return MaterialPageRoute(builder: (context) => WalkDetailsView(walk));
  }
}
