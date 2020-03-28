import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:points_verts/models/walk.dart';
import 'package:points_verts/models/weather.dart';
import 'package:points_verts/services/openweather.dart';
import 'package:url_launcher/url_launcher.dart';

import '../list_header.dart';
import 'walk_utils.dart';

class WalkDetails extends StatelessWidget {
  WalkDetails(this.walk);

  final Walk walk;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        children: <Widget>[
          ListHeader("Prévisions météo"),
          ListTile(title: _weather()),
          ListHeader("Autres informations"),
          ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[Icon(Icons.location_on)],
            ),
            title: Text(walk.meetingPoint),
            subtitle: _getGeoText(),
            onTap: () => launchGeoApp(walk),
          ),
          Divider(height: 0.5),
          ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[Icon(Icons.group)],
            ),
            title: Text("${walk.organizer}"),
            subtitle: Text(
                "${walk.contactFirstName} ${walk.contactLastName} - ${walk.contactPhoneNumber != null ? walk.contactPhoneNumber : ''}"),
            onTap: () {
              if (walk.contactPhoneNumber != null) {
                launch("tel:${walk.contactPhoneNumber}");
              }
            },
          ),
          Divider(height: 0.5),
          walk.transport != null
              ? ListTile(
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[Icon(Icons.train)],
                  ),
                  title: Text(walk.transport))
              : SizedBox.shrink(),
          walk.transport != null ? Divider(height: 0.5) : SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _getGeoText() {
    if (walk.trip != null) {
      return Text(
          "À ${walk.getFormattedDistance()}, ~${Duration(seconds: walk.trip.duration.round()).inMinutes} min. en voiture");
    } else if (walk.distance != null && walk.distance != double.maxFinite) {
      return Text("À ${walk.getFormattedDistance()} (à vol d'oiseau)");
    } else {
      return null;
    }
  }

  Widget _weather() {
    return FutureBuilder(
        future: walk.weathers,
        builder: (BuildContext context, AsyncSnapshot<List<Weather>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              List<Weather> weathers = snapshot.data;
              List<Widget> widgets = List<Widget>();
              for (Weather weather in weathers) {
                widgets.add(Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text("${weather.timestamp.hour}h", textScaleFactor: 0.8),
                    getWeatherIcon(weather, context),
                    Text("${weather.temperature.round()}°",
                        textScaleFactor: 0.8),
                    Text("${weather.windSpeed.round()} km/h",
                        textScaleFactor: 0.8)
                  ],
                ));
              }
              return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: widgets);
            }
          }
          return SizedBox();
        });
  }
}
