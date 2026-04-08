import 'package:flutter/foundation.dart';
import '../../domain/entities/canvas_item.dart';

/// Runs on an Isolate via compute() — must be a top-level function
List<CanvasItem> parseCanvasItems(List<Map<String, dynamic>> rawList) {
  return rawList.map((json) {
    return CanvasItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      chartData: (json['chartData'] as List).cast<double>(),
      statsA: json['statsA'] as String,
      statsB: json['statsB'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }).toList();
}

/// Wrapper to call compute() from the repository
Future<List<CanvasItem>> parseCanvasItemsInIsolate(
  List<Map<String, dynamic>> rawList,
) async {
  return compute(parseCanvasItems, rawList);
}
