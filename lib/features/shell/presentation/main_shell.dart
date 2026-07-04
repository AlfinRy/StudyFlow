import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared_widgets/study_flow_top_bar.dart';
import '../../home/presentation/home_screen.dart';
import '../../schedule/presentation/schedule_form_screen.dart';
import '../../tasks/presentation/task_form_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../progress/presentation/progress_screen.dart';
import '../../schedule/presentation/schedule_screen.dart';
import '../../tasks/presentation/tasks_screen.dart';

/// Root shell with a persistent bottom navigation bar (5 tabs) and an
/// IndexedStack so each tab preserves its state (UI_DESIGN.md 1.3).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    ScheduleScreen(),
    TasksScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  // FAB appears on Beranda, Jadwal, and Tugas (UI_DESIGN.md 1.3).
  bool get _showFab => _index == 0 || _index == 1 || _index == 2;

  /// FAB context-aware per tab aktif (UI_DESIGN.md §1.3: FAB di Beranda,
  /// Jadwal, dan Tugas). Saat ini Jadwal sudah terhubung ke form; Beranda &
  /// Tugas menyusul di fase masing-masing.
  void _onFabPressed() {
    switch (_index) {
      case 1: // Jadwal
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ScheduleFormScreen()),
        );
        break;
      case 2: // Tugas
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TaskFormScreen()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form tambah untuk tab ini menyusul di fase berikutnya.'),
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const StudyFlowTopBar(),
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: _showFab
          ? FloatingActionButton(
              onPressed: _onFabPressed,
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Jadwal',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Progres',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
