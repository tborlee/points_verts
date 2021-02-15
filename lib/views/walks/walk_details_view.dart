import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:points_verts/models/my_walk.dart';
import 'package:points_verts/services/database.dart';
import 'package:points_verts/services/mapbox.dart';
import 'package:points_verts/views/walks/walk_details.dart';

import '../../models/walk.dart';

class WalkDetailsView extends StatelessWidget {
  WalkDetailsView(this.walk);

  final Walk walk;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
            fit: BoxFit.fitWidth, child: Text("${walk.type} à ${walk.city}")),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_outline),
            onPressed: () {
              DBProvider.db.insertMyWalk(MyWalk.fromWalk(walk));
            },
          )
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            return Column(mainAxisSize: MainAxisSize.max, children: <Widget>[
              _buildMap(context, false),
              WalkDetails(walk)
            ]);
          } else {
            return Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
              _buildMap(context, true),
              WalkDetails(walk)
            ]);
          }
        },
      ),
    );
  }

  Widget _buildMap(BuildContext context, bool landscape) {
    Size size = MediaQuery.of(context).size;
    double height = landscape ? size.height : 200.0;
    double width = landscape ? size.width / 2 : size.width;
    return Container(
      height: height,
      width: width,
      child: retrieveStaticImage(walk.long, walk.lat, width.round(),
          height.round(), Theme.of(context).brightness),
    );
  }
}
