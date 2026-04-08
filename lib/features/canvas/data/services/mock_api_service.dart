import 'dart:math';

/// Simulates a paginated list API response
class MockApiService {
  static const List<String> _categories = [
    'Technology', 'Science', 'Design', 'Business', 'Health',
    'Finance', 'Education', 'Arts', 'Sports', 'Travel',
  ];

  static const List<String> _adjectives = [
    'Advanced', 'Modern', 'Efficient', 'Dynamic', 'Intelligent',
    'Creative', 'Scalable', 'Robust', 'Innovative', 'Seamless',
  ];

  final _random = Random();

  Future<List<Map<String, dynamic>>> fetchPage(int page, int pageSize) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final List<Map<String, dynamic>> items = [];
    final startId = page * pageSize;

    for (int i = 0; i < pageSize; i++) {
      final id = startId + i;
      final seed = id % 1000;
      items.add({
        'id': 'item_$id',
        'title': '${_adjectives[id % _adjectives.length]} ${_categories[id % _categories.length]}',
        'subtitle': 'Item #$id — tap to explore detailed analysis and metrics',
        'imageUrl': 'https://picsum.photos/seed/$seed/600/300',
        'category': _categories[id % _categories.length],
        'chartData': _generateChartData(),
        'statsA': (_random.nextDouble() * 100).toStringAsFixed(1),
        'statsB': (_random.nextDouble() * 50).toStringAsFixed(1),
        'timestamp': DateTime.now()
            .subtract(Duration(hours: id))
            .toIso8601String(),
      });
    }
    return items;
  }

  List<double> _generateChartData() {
    return List.generate(
      12,
      (_) => _random.nextDouble() * 100,
    );
  }
}
