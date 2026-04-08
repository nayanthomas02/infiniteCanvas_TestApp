import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/canvas_item.dart';
import '../../domain/repositories/canvas_repository.dart';
import '../../../../core/constants/app_constants.dart';

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class CanvasEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchNextPage extends CanvasEvent {}

class RefreshCanvas extends CanvasEvent {}

class ScrollSpeedChanged extends CanvasEvent {
  final double velocity;
  ScrollSpeedChanged(this.velocity);
  @override
  List<Object?> get props => [velocity];
}

// ─── State ───────────────────────────────────────────────────────────────────
class CanvasState extends Equatable {
  final List<CanvasItem> items;
  final bool isLoading;
  final bool isFastScrolling;
  final bool hasReachedMax;
  final String? error;
  final int currentPage;

  const CanvasState({
    this.items = const [],
    this.isLoading = false,
    this.isFastScrolling = false,
    this.hasReachedMax = false,
    this.error,
    this.currentPage = 0,
  });

  CanvasState copyWith({
    List<CanvasItem>? items,
    bool? isLoading,
    bool? isFastScrolling,
    bool? hasReachedMax,
    String? error,
    int? currentPage,
  }) {
    return CanvasState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isFastScrolling: isFastScrolling ?? this.isFastScrolling,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      error: error,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props =>
      [items, isLoading, isFastScrolling, hasReachedMax, error, currentPage];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────
class CanvasBloc extends Bloc<CanvasEvent, CanvasState> {
  final CanvasRepository repository;
  CancelToken? _cancelToken;

  CanvasBloc({required this.repository}) : super(const CanvasState()) {
    on<FetchNextPage>(_onFetchNextPage);
    on<RefreshCanvas>(_onRefreshCanvas);
    on<ScrollSpeedChanged>(_onScrollSpeedChanged);
  }

  Future<void> _onFetchNextPage(
    FetchNextPage event,
    Emitter<CanvasState> emit,
  ) async {
    if (state.isLoading || state.hasReachedMax) return;

    emit(state.copyWith(isLoading: true, error: null));

    try {
      final newItems = await repository.fetchPage(state.currentPage);

      if (newItems.isEmpty) {
        emit(state.copyWith(isLoading: false, hasReachedMax: true));
      } else {
        emit(state.copyWith(
          isLoading: false,
          items: [...state.items, ...newItems],
          currentPage: state.currentPage + 1,
          hasReachedMax: newItems.length < AppConstants.pageSize,
        ));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onRefreshCanvas(
    RefreshCanvas event,
    Emitter<CanvasState> emit,
  ) async {
    emit(const CanvasState());
    add(FetchNextPage());
  }

  void _onScrollSpeedChanged(
    ScrollSpeedChanged event,
    Emitter<CanvasState> emit,
  ) {
    final isFast =
        event.velocity.abs() > AppConstants.fastScrollVelocityThreshold;
    if (isFast != state.isFastScrolling) {
      emit(state.copyWith(isFastScrolling: isFast));
    }
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel();
    return super.close();
  }
}

/// Simple cancel token for in-flight requests
class CancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}
