import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:points_verts/services/mapbox.dart';

import '../loading.dart';
import '../../models/walk.dart';
import 'walks_view.dart';
import 'walk_list_error.dart';
import 'walk_tile.dart';

class WalkResultsMapView extends StatefulWidget {
  WalkResultsMapView(this.walks, this.position, this.currentPlace,
      this.selectedWalk, this.onWalkSelect, this.refreshWalks);

  final Future<List<Walk>> walks;
  final Position position;
  final Places currentPlace;
  final Walk selectedWalk;
  final Function(Walk) onWalkSelect;
  final Function refreshWalks;
  @override
  _WalkResultsMapViewState createState() => _WalkResultsMapViewState();

  static Widget _buildWalkInfo(Walk walk) {
    if (walk == null) {
      return SizedBox.shrink();
    } else {
      return SafeArea(
          child: Align(
              alignment: Alignment.bottomCenter,
              child: Card(
                child: Container(
                  child: WalkTile(walk, TileType.calendar),
                ),
              )));
    }
  }
}

class _WalkResultsMapViewState extends State<WalkResultsMapView> {
  MapboxMapController mapController;

  @override
  void dispose() {
    if (mapController != null) {
      mapController.dispose();
    }
    super.dispose();
  }

  void _onMapCreated(MapboxMapController controller) async {
    if (controller != null) {
      mapController = controller;
    }
  }

  void _onStyleLoadedCallback() async {
    if (mapController != null) {
      await mapController.clearCircles();
      if (widget.position != null) {
        mapController.addCircle(CircleOptions(
            geometry:
            LatLng(widget.position.latitude, widget.position.longitude)));
      }
      List<Walk> walks = await widget.walks;
      for (Walk walk in walks) {
        if (walk.lat != null && walk.long != null) {
          print("adding walk on map");
          mapController.addCircle(
              CircleOptions(geometry: LatLng(walk.lat, walk.long)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget map = MapboxMap(
        styleString: MapboxStyles.MAPBOX_STREETS,
        initialCameraPosition: CameraPosition(
            target: LatLng(
              50.3155646,
              5.009682,
            ),
            zoom: 7),
        onStyleLoadedCallback: _onStyleLoadedCallback,
        onMapCreated: _onMapCreated);
    return FutureBuilder(
      future: widget.walks,
      builder: (BuildContext context, AsyncSnapshot<List<Walk>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _onStyleLoadedCallback();
          if (snapshot.hasData) {
            return Stack(
              children: <Widget>[
                map,
                WalkResultsMapView._buildWalkInfo(widget.selectedWalk),
              ],
            );
          } else if (snapshot.hasError) {
            return WalkListError(widget.refreshWalks);
          }
        }
        return Stack(
          children: <Widget>[
            map,
            Loading(),
            WalkResultsMapView._buildWalkInfo(widget.selectedWalk),
          ],
        );
      },
    );
  }
}
