import 'package:flutter/cupertino.dart';
import 'package:points_verts/models/coordinates.dart';
import 'package:points_verts/models/walk.dart';

import '../list_header.dart';
import 'walk_tile.dart';
import 'walks_view.dart';

class WalkResultsList extends StatelessWidget {
  WalkResultsList(this.walks, this.position, this.currentPlace);

  final List<Walk> walks;
  final Coordinates? position;
  final Places? currentPlace;

  @override
  Widget build(BuildContext context) {
    if (walks.length == 0) {
      return Center(
          child: Text("Aucune marche ne correspond aux critères ce jour-là."));
    }
    return ListView.builder(
        itemBuilder: (context, i) {
          if (position != null) {
            if (i == 0) {
              return ListHeader(_defineTopHeader());
            }
            if (i == 6) {
              return ListHeader("Autres Points");
            }
            if (i < 6) {
              i = i - 1;
            } else {
              i = i - 2;
            }
          }
          if (walks.length > i) {
            return WalkTile(walks[i], TileType.calendar);
          } else {
            return SizedBox.shrink();
          }
        },
        itemCount: _defineItemCount(walks));
  }

  String _defineTopHeader() {
    if (currentPlace == Places.home) {
      return "Points les plus proches du domicile";
    } else if (currentPlace == Places.current) {
      return "Points les plus proches de votre position";
    } else {
      return "Points les plus proches";
    }
  }

  int _defineItemCount(List<Walk>? walks) {
    if (position != null) {
      if (walks!.length == 0) {
        return walks.length;
      } else if (walks.length > 5) {
        return walks.length + 2;
      } else {
        return walks.length + 1;
      }
    } else {
      return walks!.length;
    }
  }
}
