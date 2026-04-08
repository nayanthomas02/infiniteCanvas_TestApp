import '../../domain/entities/canvas_item.dart';
import '../../domain/repositories/canvas_repository.dart';
import '../isolate/json_parser.dart';
import '../services/mock_api_service.dart';
import '../../../../core/constants/app_constants.dart';

class CanvasRepositoryImpl implements CanvasRepository {
  final MockApiService _apiService;

  CanvasRepositoryImpl(this._apiService);

  @override
  Future<List<CanvasItem>> fetchPage(int page) async {
    // 1. Fetch raw JSON from mock API
    final rawList = await _apiService.fetchPage(page, AppConstants.pageSize);

    // 2. Parse heavy JSON off the main thread via compute() (Isolate)
    final items = await parseCanvasItemsInIsolate(rawList);

    return items;
  }
}
