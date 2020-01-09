import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';

import 'geo_button.dart';
import 'loading.dart';
import 'mapbox.dart';
import 'walk.dart';
import 'walk_list_error.dart';
import 'walk_utils.dart';

class WalkResultsMapView extends StatelessWidget {
  WalkResultsMapView(this.walks, this.currentPosition, this.selectedWalk,
      this.onWalkSelect, this.refreshWalks);

  final Future<List<Walk>> walks;
  final Position currentPosition;
  final Walk selectedWalk;
  final Function(Walk) onWalkSelect;
  final Function refreshWalks;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: walks,
      builder: (BuildContext context, AsyncSnapshot<List<Walk>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            List<Marker> markers = new List<Marker>();
            for (Walk walk in snapshot.data) {
              if (walk.lat != null && walk.long != null) {
                markers.add(_buildMarker(walk, context));
              }
            }
            if (currentPosition != null) {
              markers.add(Marker(
                point: new LatLng(
                    currentPosition.latitude, currentPosition.longitude),
                builder: (ctx) => new Container(child: Icon(Icons.location_on)),
              ));
            }

            return Stack(
              children: <Widget>[
                retrieveMap(
                    markers, MediaQuery.of(context).platformBrightness),
                _buildWalkInfo(selectedWalk),
              ],
            );
          } else if (snapshot.hasError) {
            return WalkListError(refreshWalks);
          } else {
            return Loading();
          }
        } else {
          return Loading();
        }
      },
    );
  }

  static Widget _buildWalkInfo(Walk walk) {
    if (walk == null) {
      return SizedBox.shrink();
    } else {
      return SafeArea(
          child: Align(
              alignment: Alignment.bottomCenter,
              child: Card(
                child: Container(
                  height: 50.0,
                  padding: EdgeInsets.only(left: 10.0, right: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      displayIcon(walk),
                      _buildWalkInfoLabel(walk),
                      walk.isCancelled()
                          ? SizedBox.shrink()
                          : GeoButton(walk: walk)
                    ],
                  ),
                ),
              )));
    }
  }

  static Widget _buildWalkInfoLabel(Walk walk) {
    if (walk.isCancelled()) {
      return Text('${walk.city} (annulé)');
    } else if (walk.distance != null) {
      return Column(
        children: <Widget>[
          Spacer(),
          Text(walk.city),
          Text(walk.getFormattedDistance()),
          Spacer()
        ],
      );
    } else {
      return Text(walk.city);
    }
  }

  Marker _buildMarker(Walk walk, BuildContext context) {
    return Marker(
      width: 25,
      height: 25,
      point: new LatLng(walk.lat, walk.long),
      builder: (ctx) => RawMaterialButton(
        child: displayIcon(walk, color: Colors.white, size: 20),
        shape: new CircleBorder(),
        elevation: selectedWalk == walk ? 5.0 : 2.0,
        // TODO: find a way to not hardcode the colors here
        fillColor: selectedWalk == walk ? Colors.greenAccent : Colors.green,
        onPressed: () {
          onWalkSelect(walk);
        },
      ),
    );
  }
}
