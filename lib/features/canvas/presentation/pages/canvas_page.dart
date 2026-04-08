import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/canvas_bloc.dart';
import '../widgets/canvas_item_card.dart';
import '../widgets/fps_overlay.dart';

class CanvasPage extends StatefulWidget {
  const CanvasPage({super.key});

  @override
  State<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage> {
  late final ScrollController _scrollController;
  bool _showFps = false;

  double _lastScrollOffset = 0;
  DateTime _lastScrollTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    // Initial load
    context.read<CanvasBloc>().add(FetchNextPage());
  }

  void _onScroll() {
    final now = DateTime.now();
    final dt = now.difference(_lastScrollTime).inMilliseconds;
    double velocity = 0;
    if (dt > 0) {
      final dx = (_scrollController.offset - _lastScrollOffset).abs();
      velocity = dx / dt * 1000; // pixels per second
    }
    _lastScrollOffset = _scrollController.offset;
    _lastScrollTime = now;

    context.read<CanvasBloc>().add(ScrollSpeedChanged(velocity));

    // Trigger next page fetch near the bottom
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (current >= maxScroll * 0.85) {
      context.read<CanvasBloc>().add(FetchNextPage());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<CanvasBloc, CanvasState>(
        builder: (context, state) {
          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── App Bar ──────────────────────────────────────
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    title: const Text('Infinite Canvas'),
                    actions: [
                      // FPS Toggle
                      IconButton(
                        onPressed: () =>
                            setState(() => _showFps = !_showFps),
                        icon: Icon(
                          _showFps ? Icons.speed : Icons.speed_outlined,
                          color: _showFps
                              ? const Color(0xFF6C63FF)
                              : Colors.white54,
                        ),
                        tooltip: 'Toggle FPS meter',
                      ),
                      // Refresh
                      IconButton(
                        onPressed: () =>
                            context.read<CanvasBloc>().add(RefreshCanvas()),
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),

                  // ── Fast-scroll banner ────────────────────────────
                  if (state.isFastScrolling)
                    const SliverToBoxAdapter(
                      child: _FastScrollBanner(),
                    ),

                  // ── Error state ───────────────────────────────────
                  if (state.error != null && state.items.isEmpty)
                    SliverFillRemaining(
                      child: _ErrorView(
                        onRetry: () =>
                            context.read<CanvasBloc>().add(FetchNextPage()),
                      ),
                    ),

                  // ── Empty / initial state ─────────────────────────
                  if (!state.isLoading &&
                      state.items.isEmpty &&
                      state.error == null)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text('No items yet.'),
                      ),
                    ),

                  // ── Items list ────────────────────────────────────
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = state.items[index];
                        return CanvasItemCard(
                          key: ValueKey(item.id),
                          item: item,
                          isFastScrolling: state.isFastScrolling,
                        );
                      },
                      childCount: state.items.length,
                    ),
                  ),

                  // ── Loading footer ────────────────────────────────
                  if (state.isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                      ),
                    ),

                  // ── End of list ───────────────────────────────────
                  if (state.hasReachedMax)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            '— End of list —',
                            style: TextStyle(color: Colors.white24),
                          ),
                        ),
                      ),
                    ),

                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),

              // ── FPS Overlay ───────────────────────────────────────
              if (_showFps) const FpsOverlay(),
            ],
          );
        },
      ),
    );
  }
}

class _FastScrollBanner extends StatelessWidget {
  const _FastScrollBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: const Color(0xFFFF9800).withAlpha(40),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: Color(0xFFFF9800), size: 16),
          SizedBox(width: 6),
          Text(
            'Fast scroll — pausing image loads to maintain 120 FPS',
            style: TextStyle(color: Color(0xFFFF9800), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('Failed to load items'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
