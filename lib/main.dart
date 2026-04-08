import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/canvas/presentation/bloc/canvas_bloc.dart';
import 'features/canvas/presentation/pages/canvas_page.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'features/tasks/presentation/cubit/connectivity_cubit.dart';
import 'features/tasks/presentation/pages/task_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const PerfTaskApp());
}

class PerfTaskApp extends StatelessWidget {
  const PerfTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CanvasBloc>(create: (_) => sl<CanvasBloc>()),
        BlocProvider<TaskBloc>(create: (_) => sl<TaskBloc>()),
        BlocProvider<ConnectivityCubit>(create: (_) => sl<ConnectivityCubit>()),
      ],
      child: MaterialApp(
        title: 'infiniteCanvas',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  static const _pages = [
    CanvasPage(),
    TaskPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withAlpha(15), width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          backgroundColor: const Color(0xFF1A1A2E),
          indicatorColor: const Color(0xFF6C63FF).withAlpha(40),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_mosaic_outlined),
              selectedIcon: Icon(Icons.auto_awesome_mosaic_rounded,
                  color: Color(0xFF6C63FF)),
              label: 'Infinite Canvas',
            ),
            NavigationDestination(
              icon: Icon(Icons.task_outlined),
              selectedIcon:
                  Icon(Icons.task_rounded, color: Color(0xFF6C63FF)),
              label: 'Task Manager',
            ),
          ],
        ),
      ),
    );
  }
}
