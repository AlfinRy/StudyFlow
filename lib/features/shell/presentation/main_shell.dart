import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../shared_widgets/app_dialogs.dart';
import '../../../shared_widgets/app_logo.dart';
import '../../../shared_widgets/study_flow_top_bar.dart';
import '../../home/presentation/home_screen.dart';
import '../../materials/presentation/materials_screen.dart';
import '../../tasks/task_providers.dart';
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

  /// Drawer menu (UI_DESIGN.md §1.3 "hamburger menu"). Berisi tujuan
  /// sekunder: Materi, Forum (segera), dan Tentang. Bottom nav tetap untuk
  /// 5 tab utama.
  Drawer _buildDrawer(BuildContext context, WidgetRef ref) {
    void closeAnd(VoidCallback action) {
      Navigator.of(context).pop(); // tutup drawer dulu
      action();
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(gradient: AppColors.navyGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                AppLogo(size: 40),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'StudyFlow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.folder_open_outlined),
            title: const Text('Materi Pembelajaran'),
            onTap: () => closeAnd(
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MaterialsScreen()),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.forum_outlined),
            title: const Text('Forum Diskusi'),
            subtitle: const Text('Segera hadir'),
            onTap: () =>
                closeAnd(() => showComingSoon(context, 'Forum Diskusi')),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Tentang Aplikasi'),
            onTap: () => closeAnd(() => showStudyFlowAbout(context)),
          ),
        ],
      ),
    );
  }

  /// Panel pengingat tugas (lonceng). Menampilkan tugas yang aktif
  /// pengingatnya & belum selesai, terurut mendekati deadline (data real dari
  /// Hive, terhubung ke fitur notifikasi Fase 6).
  void _showNotifications(BuildContext context, WidgetRef ref) {
    final upcoming = ref
        .read(taskListProvider)
        .where((t) => t.reminderEnabled && !t.isDone)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final items = upcoming.take(6).toList();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: const [
                  Icon(Icons.notifications_active_rounded,
                      color: AppColors.accent),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Pengingat Tugas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Belum ada pengingat aktif. Aktifkan "Pengingat" pada tugas '
                  'untuk mendapat reminder menjelang deadline.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4),
                ),
              )
            else
              for (final t in items)
                ListTile(
                  leading: const Icon(Icons.alarm_rounded,
                      color: AppColors.warning),
                  title: Text(t.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(idnFormatDateCompact(t.dueDate)),
                ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(activeTabProvider);
    // FAB appears on Beranda, Jadwal, and Tugas (UI_DESIGN.md 1.3).
    final showFab = index == 0 || index == 1 || index == 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StudyFlowTopBar(
        onNotificationsPressed: () => _showNotifications(context, ref),
      ),
      drawer: _buildDrawer(context, ref),
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
