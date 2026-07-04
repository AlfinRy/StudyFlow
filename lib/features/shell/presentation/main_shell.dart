import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared_widgets/study_flow_top_bar.dart';
import '../../home/presentation/home_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../progress/presentation/progress_screen.dart';
import '../../schedule/presentation/schedule_form_screen.dart';
import '../../schedule/presentation/schedule_screen.dart';
import '../../tasks/presentation/task_form_screen.dart';
import '../../tasks/presentation/tasks_screen.dart';
import '../shell_providers.dart';

/// Root shell with a persistent bottom navigation bar (5 tabs) and an
/// IndexedStack so each tab preserves its state (UI_DESIGN.md 1.3).
///
/// Tab aktif disimpan di [activeTabProvider] agar layar anak (mis. Beranda)
/// bisa memindahkan tab, mis. lewat tombol "Lihat semua".
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _screens = <Widget>[
    HomeScreen(),
    ScheduleScreen(),
    TasksScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  void _onFabPressed(BuildContext context, WidgetRef ref) {
    final index = ref.read(activeTabProvider);
    switch (index) {
      case 0: // Beranda → quick-add tugas (aksi paling umum)
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TaskFormScreen()),
        );
        break;
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
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(activeTabProvider);
    // FAB appears on Beranda, Jadwal, and Tugas (UI_DESIGN.md 1.3).
    final showFab = index == 0 || index == 1 || index == 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const StudyFlowTopBar(),
      body: IndexedStack(index: index, children: _screens),
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () => _onFabPressed(context, ref),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(activeTabProvider.notifier).state = i,
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
