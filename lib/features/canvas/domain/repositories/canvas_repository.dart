import '../entities/canvas_item.dart';

abstract class CanvasRepository {
  Future<List<CanvasItem>> fetchPage(int page);
}
