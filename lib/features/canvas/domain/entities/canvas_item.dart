import 'package:equatable/equatable.dart';

class CanvasItem extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String category;
  final List<double> chartData;
  final String statsA;
  final String statsB;
  final DateTime timestamp;

  const CanvasItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.category,
    required this.chartData,
    required this.statsA,
    required this.statsB,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id];
}
