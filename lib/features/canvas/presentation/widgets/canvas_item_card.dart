import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../domain/entities/canvas_item.dart';
import 'chart_painter.dart';
import '../../../../core/theme/app_theme.dart';

class CanvasItemCard extends StatelessWidget {
  final CanvasItem item;
  final bool isFastScrolling;

  const CanvasItemCard({
    super.key,
    required this.item,
    required this.isFastScrolling,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header with image (wrapped in RepaintBoundary) ───────────
            RepaintBoundary(
              child: _ImageHeader(
                item: item,
                isFastScrolling: isFastScrolling,
              ),
            ),
            // ── Body ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Category chip — wrapped in RepaintBoundary (static)
                      RepaintBoundary(
                        child: _CategoryChip(category: item.category),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  RepaintBoundary(
                    child: _StatsRow(statsA: item.statsA, statsB: item.statsB),
                  ),
                  const SizedBox(height: 16),

                  // Chart — drawn with CustomPainter (zero widget nesting)
                  Text(
                    'Performance Trend',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white38,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: CustomPaint(
                      painter: ChartPainter(data: item.chartData),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets for isolated repaint boundaries ───────────────────────────────

class _ImageHeader extends StatelessWidget {
  final CanvasItem item;
  final bool isFastScrolling;

  const _ImageHeader({required this.item, required this.isFastScrolling});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: isFastScrolling
            // Skip image loading when scrolling fast — show placeholder
            ? Container(
                color: const Color(0xFF1A1A40),
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: Colors.white12,
                    size: 40,
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 600,
                placeholder: (_, __) => Container(
                  color: const Color(0xFF1A1A40),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFF1A1A40),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.white24),
                  ),
                ),
              ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final String statsA;
  final String statsB;
  const _StatsRow({required this.statsA, required this.statsB});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Score', value: statsA, icon: Icons.star_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Rate', value: '$statsB%', icon: Icons.trending_up_rounded)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
