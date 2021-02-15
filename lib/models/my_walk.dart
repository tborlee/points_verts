import 'walk.dart';

class MyWalk {
  MyWalk({this.id, this.walk, this.score, this.createdAt, this.updatedAt});

  final int id;
  final Walk walk;
  int score;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory MyWalk.fromWalk(Walk walk) {
    DateTime timestamp = DateTime.now();
    return MyWalk(walk: walk, createdAt: timestamp, updatedAt: timestamp);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'walk_id': walk.id,
      'score': score,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String()
    };
  }
}
