import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// ─── State ───────────────────────────────────────────────────────────────────
class ConnectivityState extends Equatable {
  final bool isOnline;
  const ConnectivityState({required this.isOnline});
  @override
  List<Object?> get props => [isOnline];
}

// ─── Cubit ───────────────────────────────────────────────────────────────────
class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit()
      : super(const ConnectivityState(isOnline: true)) {
    _init();
  }

  void _init() {
    Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) =>
          r != ConnectivityResult.none);
      emit(ConnectivityState(isOnline: isOnline));
    });
  }
}
