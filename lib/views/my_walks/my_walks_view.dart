import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:points_verts/models/my_walk.dart';
import 'package:points_verts/services/database.dart';
import 'package:points_verts/views/loading.dart';
import 'package:points_verts/views/walks/walk_tile.dart';

class MyWalksView extends StatefulWidget {
  @override
  _MyWalksViewState createState() => _MyWalksViewState();
}

class _MyWalksViewState extends State<MyWalksView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Marches"),
        actions: [IconButton(icon: Icon(Icons.add), onPressed: () => {})],
      ),
      body: _MyWalksList(),
    );
  }
}

class _MyWalksList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: DBProvider.db.getMyWalks(),
      builder: (BuildContext context, AsyncSnapshot<List<MyWalk>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, i) {
                return WalkTile(snapshot.data[i].walk, TileType.calendar);
              });
        } else if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        } else {
          return Loading();
        }
      },
    );
  }
}
