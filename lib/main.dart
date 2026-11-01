import 'dart:async';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'models/challenge.dart';
import 'models/habit.dart';
import 'services/habit_engine.dart';
import 'state/app_state.dart';

export 'state/app_state.dart' show AppState;

final appProvider = ChangeNotifierProvider((ref) => AppState());

final routerProvider = Provider((ref) {
  final app = ref.watch(appProvider);
  return buildRouter(app: app, login: const LoginScreen(), home: const AppShell());
});

void main() => runApp(const ProviderScope(child: DuetApp()));

class DuetApp extends ConsumerWidget {
  const DuetApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Duet', debugShowCheckedModeBanner: false,
    themeMode: ref.watch(appProvider).darkMode ? ThemeMode.dark : ThemeMode.light,
    theme: buildLightTheme(),
    darkTheme: buildDarkTheme(),
    routerConfig: ref.watch(routerProvider),
  );
}

class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? const [Color(0xFF080B18), Color(0xFF111A34), Color(0xFF0B0D1B)]
                  : const [Color(0xFFF7F5FF), Color(0xFFECE9FF), Color(0xFFF9F8FF)],
            ),
          ),
        ),
        Positioned(top: -100, right: -70, child: _GlowOrb(color: dark ? const Color(0x665E4BFF) : const Color(0x445E4BFF), size: 260)),
        Positioned(bottom: -120, left: -80, child: _GlowOrb(color: dark ? const Color(0x4439A8FF) : const Color(0x3339A8FF), size: 300)),
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(color: (dark ? const Color(0x22080B18) : const Color(0x22FFFFFF)), child: Material(type: MaterialType.transparency, child: child)),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(child: Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 70, spreadRadius: 30)])));
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: GlassBackdrop(child: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 24), const BrandMark(), const SizedBox(height: 28),
    Text('Different goals.\nOne journey.', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, height: 1.05)),
    const SizedBox(height: 12), Text('Stay accountable with someone who is moving forward too.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)), const SizedBox(height: 32),
    TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')), const SizedBox(height: 12), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
    if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: Colors.red))),
    const SizedBox(height: 20), FilledButton(onPressed: _signIn, child: const Text('Continue')),
    if (kDebugMode) ...[
      const SizedBox(height: 10), OutlinedButton.icon(onPressed: _useAdminAccount, icon: const Icon(Icons.admin_panel_settings_outlined), label: const Text('Use super-admin demo account')),
      const SizedBox(height: 8), Text('Local testing only · admin@duet.local', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
    ] else ...[
      const SizedBox(height: 10), const Text('Production authentication is not configured for this build.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
    ],
    const SizedBox(height: 12), Center(child: TextButton(onPressed: () {}, child: const Text('Forgot password?'))), const SizedBox(height: 24),
    Center(child: TextButton(onPressed: () {}, child: const Text('New here? Create an account'))),
  ])))));

  void _useAdminAccount() {
    email.text = AppState.adminEmail;
    password.text = AppState.adminPassword;
    _signIn();
  }

  void _signIn() {
    final authenticated = ref.read(appProvider).authenticate(email.text, password.text);
    if (!authenticated) {
      setState(() => error = 'Enter an email and password to continue.');
      return;
    }
    context.go('/home');
  }
}

class AppShell extends ConsumerStatefulWidget { const AppShell({super.key}); @override ConsumerState<AppShell> createState() => _AppShellState(); }
class _AppShellState extends ConsumerState<AppShell> {
  int index = 0;
  final pages = const [HomeScreen(), ProgressScreen(), BuddyScreen(), ChallengesScreen(), SettingsScreen()];
  static const destinations = [
    NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.insights_rounded), label: 'Progress'),
    NavigationDestination(icon: Icon(Icons.people_alt_outlined), label: 'Buddy'),
    NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Challenges'),
    NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: GlassBackdrop(
          child: LayoutBuilder(builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 900;
            final content = Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: desktop ? 980 : 720), child: IndexedStack(index: index, children: pages)));
            if (!desktop) return content;
            return Row(children: [
              _DesktopSidebar(index: index, onSelected: (value) => setState(() => index = value)),
              Expanded(child: content),
            ]);
          }),
        ),
        bottomNavigationBar: LayoutBuilder(builder: (context, constraints) => constraints.maxWidth >= 900 ? const SizedBox.shrink() : NavigationBar(selectedIndex: index, onDestinationSelected: (value) => setState(() => index = value), destinations: destinations)),
      );
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.index, required this.onSelected});
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
        width: 230,
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        decoration: BoxDecoration(color: Theme.of(context).cardColor.withValues(alpha: .72), borderRadius: BorderRadius.circular(28), border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .28))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: BrandMark()),
          const SizedBox(height: 32),
          _sideItem(context, 0, Icons.grid_view_rounded, 'Home'),
          _sideItem(context, 1, Icons.insights_rounded, 'Progress'),
          _sideItem(context, 2, Icons.people_alt_outlined, 'Buddy'),
          _sideItem(context, 3, Icons.emoji_events_outlined, 'Challenges'),
          _sideItem(context, 4, Icons.tune_rounded, 'Settings'),
          const Spacer(),
          Padding(padding: const EdgeInsets.all(12), child: Text('Stay consistent.\nGrow together.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12, height: 1.4))),
        ]),
      );

  Widget _sideItem(BuildContext context, int value, IconData icon, String label) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Semantics(button: true, selected: index == value, label: '$label tab', child: ListTile(selected: index == value, selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: .12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), leading: Icon(icon), title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)), onTap: () => onSelected(value))));
}

class HomeScreen extends ConsumerWidget { const HomeScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) { final state = ref.watch(appProvider); final visibleHabits = state.activeHabits.toList(); final percent = visibleHabits.isEmpty ? 0.0 : visibleHabits.map((habit) => state.todayPercent(habit.id)).reduce((a, b) => a + b) / visibleHabits.length; return SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 28), children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_greeting(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)), const SizedBox(height: 4), const Text('Your duet today', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 28))]), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE9E6F2))), child: Row(children: [const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF6257D9)), const SizedBox(width: 7), Text(_dateLabel(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black))]))]), const SizedBox(height: 20),
    const _TodayStrip(), const SizedBox(height: 16), _TogetherCard(percent: percent, onCheckIn: state.habits.isEmpty ? null : () => _showCheckIn(context, ref, state.habits.first)), const SizedBox(height: 18),
    Row(children: [Expanded(child: SummaryCard(title: 'You', percent: percent, streak: visibleHabits.isEmpty ? 0 : state.streak(visibleHabits.first.id), color: const Color(0xFFECEAFF))), const SizedBox(width: 12), Expanded(child: state.buddyPaired ? const SummaryCard(title: 'Alex', percent: 78, streak: 6, color: Color(0xFFFFE9DF)) : const _EmptyBuddyCard())]), const SizedBox(height: 22),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Your habits', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)), TextButton.icon(onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const AddHabitSheet()), icon: const Icon(Icons.add, size: 18), label: const Text('Add'))]),
    if (visibleHabits.isEmpty) const _FirstHabitPrompt(),
    ...visibleHabits.map((h) => HabitTile(habit: h, percent: state.todayPercent(h.id))),
  ])); }
}

class _TodayStrip extends StatelessWidget {
  const _TodayStrip();

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final date = today.subtract(Duration(days: 6 - index));
        final selected = index == 6;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 39,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: selected ? const LinearGradient(colors: [Color(0xFF6257D9), Color(0xFF8B78E9)]) : null,
            color: selected ? null : Theme.of(context).cardColor.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? Colors.transparent : Theme.of(context).dividerColor.withValues(alpha: .35)),
          ),
          child: Semantics(label: '${selected ? 'Today, ' : ''}${weekdays[date.weekday - 1]} ${date.day}', button: true, child: Column(children: [
            Text(weekdays[date.weekday - 1], style: TextStyle(fontSize: 11, color: selected ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${date.day}', style: TextStyle(color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800)),
          ])),
        );
      }),
    );
  }
}

class _TogetherCard extends StatelessWidget {
  const _TogetherCard({required this.percent, this.onCheckIn});
  final double percent;
  final VoidCallback? onCheckIn;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6559D9), Color(0xFF8B78E9)]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Color(0x336557D9), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TOGETHER %', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${percent.round()}%', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800)),
              Text(percent >= 80 ? 'You\'re both doing great!' : 'A little progress is still progress.', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: onCheckIn, style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF6257D9), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)), icon: const Icon(Icons.add_task_rounded, size: 17), label: const Text('Quick check-in')),
            ])),
            SizedBox(width: 78, height: 78, child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: percent / 100, strokeWidth: 8, backgroundColor: Colors.white24, color: Colors.white),
              const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 30),
            ])),
          ]),
          const SizedBox(height: 16),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: percent / 100, minHeight: 7, backgroundColor: Colors.white24, color: Colors.white)),
        ]),
      );
}

String _greeting() { final hour = DateTime.now().hour; return hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening'; }
String _dateLabel() { final now = DateTime.now(); const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']; return '${months[now.month - 1]} ${now.day}'; }

class SummaryCard extends StatelessWidget { const SummaryCard({required this.title, required this.percent, required this.streak, required this.color, super.key}); final String title; final double percent; final int streak; final Color color;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)), const SizedBox(height: 12), Text('${percent.round()}%', style: const TextStyle(color: Colors.black, fontSize: 30, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Row(children: [const Icon(Icons.local_fire_department, size: 16, color: Color(0xFFF06F42)), Text(' $streak day streak', style: const TextStyle(fontSize: 12, color: Colors.black54))])])); }
 class _EmptyBuddyCard extends StatelessWidget { const _EmptyBuddyCard(); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF0EFF6), borderRadius: BorderRadius.circular(22)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Buddy', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)), SizedBox(height: 12), Text('Not paired', style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w800)), SizedBox(height: 8), Text('Invite someone to join', style: TextStyle(fontSize: 12, color: Colors.black54))])); }
class _FirstHabitPrompt extends StatelessWidget { const _FirstHabitPrompt(); @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [const Icon(Icons.flag_outlined, color: Color(0xFF6257D9), size: 30), const SizedBox(width: 14), const Expanded(child: Text('Create your first habit to start your journey.', style: TextStyle(fontWeight: FontWeight.w700))), FilledButton(onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const AddHabitSheet()), child: const Text('Start'))]))); }
class HabitTile extends ConsumerWidget { const HabitTile({required this.habit, required this.percent, super.key}); final Habit habit; final double percent;
  @override Widget build(BuildContext context, WidgetRef ref) { final done = percent >= 100; final progress = (percent / 100).clamp(0.0, 1.0); return Semantics(container: true, label: '${habit.name}, ${percent.round()} percent complete, target ${habit.targetLabel}', child: Card(elevation: 0, margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: done ? const Color(0xFFDDF5E9) : const Color(0xFFF0EEFF), shape: BoxShape.circle), child: Icon(done ? Icons.check : _habitIcon(habit.type), color: done ? Colors.green : const Color(0xFF6257D9))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(habit.name, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text('${percent.round()}% · ${habit.targetLabel}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)), const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: progress, minHeight: 5, color: done ? Colors.green : const Color(0xFF6257D9), backgroundColor: Theme.of(context).dividerColor.withValues(alpha: .25))) ])), IconButton(onPressed: () => _showCheckIn(context, ref, habit), tooltip: done ? 'Update check-in' : 'Check in', icon: Icon(done ? Icons.check_circle : Icons.add_circle_outline, color: done ? Colors.green : const Color(0xFF6257D9), size: 28)), PopupMenuButton<String>(tooltip: 'Habit actions', onSelected: (action) { if (action == 'edit') { showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => EditHabitSheet(habit: habit)); } else if (action == 'archive') { ref.read(appProvider).archiveHabit(habit); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit habit')), PopupMenuItem(value: 'archive', child: Text('Archive habit'))])])))); }
}

IconData _habitIcon(HabitType type) => switch (type) {
  HabitType.boolean => Icons.task_alt_rounded,
  HabitType.quantity => Icons.straighten_rounded,
  HabitType.duration => Icons.timer_outlined,
  HabitType.distance => Icons.directions_run_rounded,
  HabitType.count => Icons.format_list_numbered_rounded,
};

void _showCheckIn(BuildContext context, WidgetRef ref, Habit habit) {
  final pageContext = context;
  final existing = ref.read(appProvider).logs.where((log) => log.habitId == habit.id && HabitEngine.isSameDay(log.date, DateTime.now())).firstOrNull;
  var value = existing?.value ?? 0;
  final valueController = TextEditingController(text: value.toStringAsFixed(value % 1 == 0 ? 0 : 1));
  showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => StatefulBuilder(builder: (context, setModalState) => Padding(
    padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Log ${habit.name}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8), Text('Daily target: ${habit.targetLabel}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 20),
      if (habit.type == HabitType.boolean) ...[
        Center(child: FilledButton.icon(onPressed: () => setModalState(() => value = value >= 1 ? 0 : 1), icon: Icon(value >= 1 ? Icons.check : Icons.circle_outlined), label: Text(value >= 1 ? 'Completed' : 'Mark as done'))),
      ] else if (habit.type == HabitType.quantity || habit.type == HabitType.count) ...[
        Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(tooltip: 'Decrease value', onPressed: () => setModalState(() => value = (value - 1).clamp(0, double.infinity)), icon: const Icon(Icons.remove_circle_outline), iconSize: 34), Text('${value % 1 == 0 ? value.toInt() : value}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800)), IconButton(tooltip: 'Increase value', onPressed: () => setModalState(() => value++), icon: const Icon(Icons.add_circle_outline), iconSize: 34)])),
        Center(child: Text(habit.unit ?? 'units', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
      ] else ...[
        Text('${habit.percentage(value).round()}% complete', style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8),
        LinearProgressIndicator(value: habit.percentage(value) / 100, minHeight: 10, borderRadius: BorderRadius.circular(10)), const SizedBox(height: 16),
        TextField(keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Completed ${habit.unit ?? 'units'}'), controller: valueController, onChanged: (text) => value = double.tryParse(text) ?? value),
      ],
      const SizedBox(height: 20), FilledButton(onPressed: () {
        final app = ref.read(appProvider);
        final completed = value >= habit.target;
        app.checkIn(habit, value);
        Navigator.pop(context);
        if (completed) {
          ScaffoldMessenger.of(pageContext).showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF6257D9),
            content: Text(app.buddyPaired ? '🎉 You and Alex both showed up!' : '🎉 ${habit.name} complete!'),
          ));
        }
      }, child: const Text('Save check-in')),
    ]),
  ))).whenComplete(valueController.dispose);
}

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}


class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    return SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Challenges', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          Text('Build momentum together', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          _ChallengeHero(onPressed: () => _showChallengeDialog(context, ref)),
          const SizedBox(height: 18),
          Text('Your challenges', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (state.challenges.isEmpty) const _ChallengeEmptyState(),
          ...state.challenges.map((challenge) => _ChallengeTile(challenge: challenge, onCheckIn: () => ref.read(appProvider).checkInChallenge(challenge))),
        ],),
      );
  }

  void _showChallengeDialog(BuildContext context, WidgetRef ref) {
    final title = TextEditingController(text: '30 Day Show Up');
    final duration = TextEditingController(text: '30');
    showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Create challenge'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: title, decoration: const InputDecoration(labelText: 'Challenge name')), const SizedBox(height: 12), TextField(controller: duration, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration in days'))]),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () { ref.read(appProvider).addChallenge(title.text.trim().isEmpty ? 'New challenge' : title.text.trim(), int.tryParse(duration.text) ?? 30, null); Navigator.pop(dialogContext); }, child: const Text('Create'))],
    ));
  }
}

class _ChallengeHero extends StatelessWidget {
  const _ChallengeHero({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6257D9), Color(0xFF9A7BEE)]), borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x335F4FD1), blurRadius: 18, offset: Offset(0, 8))]),
        child: Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Make it a duet', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)), SizedBox(height: 6), Text('Small promises become shared wins.', style: TextStyle(color: Colors.white70)), SizedBox(height: 16)])),
          FilledButton(onPressed: onPressed, style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF6257D9)), child: const Text('Create')),
        ]),
      );
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({required this.challenge, required this.onCheckIn});
  final DuetChallenge challenge;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) { const color = Color(0xFF6257D9); return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
    Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: .14), shape: BoxShape.circle), child: const Icon(Icons.flag_rounded, color: color)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(challenge.title, style: const TextStyle(fontWeight: FontWeight.w800)), Text('${challenge.duration} day shared goal', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))])), Text(challenge.status, style: const TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700))]),
    const SizedBox(height: 14), Row(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: challenge.progress, minHeight: 7, color: color, backgroundColor: color.withValues(alpha: .12)))), const SizedBox(width: 10), Text('${challenge.completedDays}/${challenge.duration}', style: const TextStyle(fontWeight: FontWeight.w800))]),
    const SizedBox(height: 12), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: challenge.status == 'Active' ? onCheckIn : null, icon: const Icon(Icons.check_rounded, size: 18), label: Text(challenge.status == 'Completed' ? 'Completed' : 'Mark today complete'))),
  ]))); }
}

class _ChallengeEmptyState extends StatelessWidget {
  const _ChallengeEmptyState();
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [Icon(Icons.emoji_events_outlined, size: 46, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 10), const Text('No challenges yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), const SizedBox(height: 6), Text('Create a shared challenge to turn consistency into a team win.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))])));
}
class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  bool compareWithBuddy = true;
  String selectedHabitId = 'all';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final selectedHabits = selectedHabitId == 'all'
        ? state.habits
        : state.habits.where((habit) => habit.id == selectedHabitId);
    final days = List.generate(7, (index) => DateTime.now().subtract(Duration(days: 6 - index)));
    final yourSpots = days.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), state.averageForDate(entry.value, selectedHabits))).toList();
    final buddySpots = days.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), state.buddyPercentForDate(entry.value))).toList();
    final average = yourSpots.isEmpty ? 0 : yourSpots.map((spot) => spot.y).reduce((a, b) => a + b) / yourSpots.length;

    return SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Progress', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      Text('See how your momentum is changing', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 18),
      Card(elevation: 0, child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 8, 8), child: Row(children: [
        const Icon(Icons.compare_arrows_rounded, color: Color(0xFF6257D9)),
        const SizedBox(width: 10),
        const Expanded(child: Text('Compare with Alex', style: TextStyle(fontWeight: FontWeight.w700))),
        Switch(value: compareWithBuddy, onChanged: (value) => setState(() => compareWithBuddy = value)),
      ]))),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: selectedHabitId,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.filter_list_rounded), labelText: 'Tasks in graph'),
        items: [
          const DropdownMenuItem(value: 'all', child: Text('All tasks (average)')),
          ...state.habits.map((habit) => DropdownMenuItem(value: habit.id, child: Text(habit.name))),
        ],
        onChanged: (value) => setState(() => selectedHabitId = value ?? 'all'),
      ),
      const SizedBox(height: 16),
      Card(elevation: 0, child: Padding(padding: const EdgeInsets.fromLTRB(12, 20, 18, 16), child: Column(children: [
        SizedBox(height: 240, child: LineChart(LineChartData(
          minY: 0, maxY: 100,
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25, getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFEDEBF4), strokeWidth: 1)),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 34, interval: 25)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (value, meta) => Padding(padding: const EdgeInsets.only(top: 8), child: Text('${days[value.toInt().clamp(0, 6)].day}/${days[value.toInt().clamp(0, 6)].month}', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant))))),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(isCurved: true, color: const Color(0xFF6257D9), barWidth: 4, dotData: const FlDotData(show: true), spots: yourSpots),
            if (compareWithBuddy) LineChartBarData(isCurved: true, color: const Color(0xFFF0784B), barWidth: 4, dotData: const FlDotData(show: true), spots: buddySpots),
          ],
        ))),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const _LegendDot(color: Color(0xFF6257D9), label: 'You'),
          if (compareWithBuddy) const _LegendDot(color: Color(0xFFF0784B), label: 'Alex'),
        ]),
      ]))),
      const SizedBox(height: 18),
      Row(children: [Expanded(child: StatCard(label: '7-day average', value: '${average.round()}%')), const SizedBox(width: 12), Expanded(child: StatCard(label: 'Tasks tracked', value: '${selectedHabits.length}'))]),
    ]));
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 5), Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))]));
}
 class StatCard extends StatelessWidget { const StatCard({required this.label, required this.value, super.key}); final String label; final String value; @override Widget build(BuildContext context) => Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))]))); }

class BuddyScreen extends ConsumerStatefulWidget {
  const BuddyScreen({super.key});

  @override
  ConsumerState<BuddyScreen> createState() => _BuddyScreenState();
}

class _BuddyScreenState extends ConsumerState<BuddyScreen> {
  Timer? _refreshTimer;
  int _secondsRemaining = 30 - (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 30;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsRemaining = 30 - (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 30;
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final state = ref.watch(appProvider);
    final status = state.buddyStatus;
    return SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Buddy', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      Text('Cheer each other on', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 24),
      if (status == 'active') ...[
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [Row(children: [
          const CircleAvatar(radius: 30, backgroundColor: Color(0xFFFFE9DF), child: Icon(Icons.person, color: Color(0xFFF06F42), size: 30)),
          const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Alex Morgan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), Text('78% today · 6 day streak', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))])),
          PopupMenuButton<String>(tooltip: 'Buddy actions', onSelected: (value) { if (value == 'end') _confirmEndBuddy(context, ref); }, itemBuilder: (_) => const [PopupMenuItem(value: 'end', child: Text('End relationship'))]),
        ]), const SizedBox(height: 16), Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => ref.read(appProvider).nudgeBuddy(), icon: const Icon(Icons.notifications_active_outlined, size: 18), label: const Text('Send nudge'))), const SizedBox(width: 10), Expanded(child: FilledButton.icon(onPressed: () => _showReactionPicker(context, ref), icon: const Icon(Icons.favorite_border, size: 18), label: const Text('React')))]),
        ]))),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFFFF1E9), borderRadius: BorderRadius.circular(22)), child: const Row(children: [Text('🔥', style: TextStyle(fontSize: 30)), SizedBox(width: 14), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('6 day sync streak', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 17)), Text('Keep the rhythm going today', style: TextStyle(color: Colors.black54))])])),
        const SizedBox(height: 18),
        _BuddyActivityCard(activity: state.buddyActivity),
      ] else if (status == 'pending') ...[
        Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Icon(Icons.shield_outlined, size: 54, color: Color(0xFFF0784B)), const SizedBox(height: 14), const Text('Secure invite pending', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(state.inviteCode ?? '', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 4)), IconButton(tooltip: 'Copy invite token', icon: const Icon(Icons.copy_outlined), onPressed: state.inviteCode == null ? null : () { Clipboard.setData(ClipboardData(text: state.inviteCode!)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite token copied'))); })]), const SizedBox(height: 12), Text('Current OTP: ${state.currentInviteOtp}', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)), const SizedBox(height: 6), Text('Refreshes in ${_secondsRemaining}s', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)), const SizedBox(height: 8), Text('The OTP changes every 30 seconds. Share the token and OTP privately.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12))]))),
      ] else ...[
        Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Icon(Icons.people_alt_outlined, size: 54, color: Color(0xFF6257D9)), const SizedBox(height: 14), const Text('Your journey is better together', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text('Invite a buddy to share progress, celebrate wins, and build a sync streak.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 18), FilledButton.icon(onPressed: () { final code = ref.read(appProvider).createInvite(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invite created: $code'))); }, icon: const Icon(Icons.link), label: const Text('Generate invite'))]))),
        if (status == 'ended') Padding(padding: const EdgeInsets.only(top: 12), child: Text('Your previous buddy relationship has ended. You can start a new invite anytime.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
        const SizedBox(height: 18),
      ],
      if (status != 'active') ...[const SizedBox(height: 18), const InviteCodeEntry()],
      const SizedBox(height: 24),
      if (status == 'active') ...[const Text('Recent activity', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)), const ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(child: Icon(Icons.check)), title: Text('Alex completed Running'), subtitle: Text('18 minutes ago'), trailing: Text('👏'))],
    ]));
  }

  Future<void> _confirmEndBuddy(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('End buddy relationship?'),
      content: const Text('You can invite a buddy again later, but this shared connection will be ended.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep buddy')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('End relationship'))],
    ));
    if (confirmed == true) ref.read(appProvider).endBuddy();
  }

  void _showReactionPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(context: context, builder: (sheetContext) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Send encouragement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),
      Wrap(spacing: 12, children: ['👏', '🔥', '💪', '❤️', '🎉'].map((reaction) => Semantics(button: true, label: 'Send $reaction reaction', child: InkWell(onTap: () { ref.read(appProvider).reactToBuddy(reaction); Navigator.pop(sheetContext); }, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(18)), child: Text(reaction, style: const TextStyle(fontSize: 28)))))).toList()),
    ]))));
  }
}

class _BuddyActivityCard extends StatelessWidget {
  const _BuddyActivityCard({required this.activity});
  final List<String> activity;

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Recent activity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    ...activity.take(4).map((item) => ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: CircleAvatar(radius: 16, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Icon(item.contains('Alex') ? Icons.person_outline : Icons.check_rounded, size: 17, color: Theme.of(context).colorScheme.primary)), title: Text(item, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text('Today', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)))),
  ])));
}

class InviteCodeEntry extends ConsumerStatefulWidget {
  const InviteCodeEntry({super.key});

  @override
  ConsumerState<InviteCodeEntry> createState() => _InviteCodeEntryState();
}

class _InviteCodeEntryState extends ConsumerState<InviteCodeEntry> {
  final controller = TextEditingController();
  String otp = '';
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Have an invite code?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Enter the six-character invite token and its current OTP.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: 'Invite token', hintText: 'A7K2Q9', errorText: error),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'One-time password', hintText: '123456'),
              onChanged: (value) => otp = value,
            ),
            const SizedBox(height: 4),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _accept, icon: const Icon(Icons.person_add_alt_1), label: const Text('Accept invite'))),
          ]),
        ),
      );

  void _accept() {
    final accepted = ref.read(appProvider).acceptInviteCode(controller.text, otp);
    if (!accepted) {
      setState(() => error = 'Enter a valid token and the current six-digit OTP.');
      return;
    }
    setState(() => error = null);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buddy invite accepted!')));
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    return SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      const SizedBox(height: 20),
      const ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(child: Icon(Icons.person)), title: Text('Jordan Lee', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('Manage your profile'), trailing: Icon(Icons.chevron_right)),
      if (state.isSuperAdmin) ...[
        _AdminPanel(onReset: () => _confirmReset(context, ref)),
      ],
      const Divider(),
      const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      const SizedBox(height: 8),
      Text('Choose which nudges you want to receive.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      _NotificationSwitch(state: state, setting: 'dailyReminders', title: 'Daily reminders', subtitle: 'A gentle nudge to check in', icon: Icons.notifications_none),
      _NotificationSwitch(state: state, setting: 'buddyActivity', title: 'Buddy activity', subtitle: 'Know when Alex shows up', icon: Icons.favorite_border),
      _NotificationSwitch(state: state, setting: 'accountabilityNudges', title: 'Accountability nudges', subtitle: 'A reminder when your buddy is ahead', icon: Icons.bolt_outlined),
      _NotificationSwitch(state: state, setting: 'syncUpdates', title: 'Sync updates', subtitle: 'Celebrate when you complete a goal', icon: Icons.local_fire_department_outlined),
      _NotificationSwitch(state: state, setting: 'streakRisk', title: 'Streak at risk', subtitle: 'Warn me before today slips away', icon: Icons.warning_amber_outlined),
      const Divider(),
      const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      SwitchListTile(contentPadding: EdgeInsets.zero, value: state.darkMode, onChanged: state.toggleDarkMode, title: const Text('Dark mode'), subtitle: const Text('A calmer theme for evening check-ins'), secondary: const Icon(Icons.dark_mode_outlined)),
      if (state.notifications.isNotEmpty) ...[
        const Divider(),
        const Text('Recent notifications', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ...state.notifications.take(3).map((message) => ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(backgroundColor: Color(0xFFECEAFF), child: Icon(Icons.check, color: Color(0xFF6257D9))), title: Text(message))),
      ],
      const Divider(),
      ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.logout), title: const Text('Log out'), onTap: () { ref.read(appProvider).setSignedIn(false); context.go('/login'); }),
    ]));
  }
}

Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Reset local test data?'), content: const Text('This clears habits, logs, invites, and notifications on this browser.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Reset'))]));
  if (confirmed == true && context.mounted) {
    await ref.read(appProvider).resetLocalData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local test data reset.')));
  }
}

class _AdminPanel extends StatelessWidget {
  const _AdminPanel({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFFECEAFF),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Icon(Icons.admin_panel_settings, color: Color(0xFF6257D9)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Super admin mode', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF40378F))),
              Text('Local testing controls are enabled.', style: TextStyle(fontSize: 12, color: Color(0xFF40378F))),
            ])),
            TextButton(onPressed: onReset, child: const Text('Reset data')),
          ]),
        ),
      );
}

class _NotificationSwitch extends StatelessWidget {
  const _NotificationSwitch({required this.state, required this.setting, required this.title, required this.subtitle, required this.icon});
  final AppState state;
  final String setting;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SwitchListTile(contentPadding: EdgeInsets.zero, value: state.notificationPreferences[setting] ?? false, onChanged: (enabled) => state.setNotificationPreference(setting, enabled), title: Text(title), subtitle: Text(subtitle), secondary: Icon(icon));
}

class EditHabitSheet extends ConsumerStatefulWidget {
  const EditHabitSheet({required this.habit, super.key});
  final Habit habit;

  @override
  ConsumerState<EditHabitSheet> createState() => _EditHabitSheetState();
}

class _EditHabitSheetState extends ConsumerState<EditHabitSheet> {
  late final TextEditingController name = TextEditingController(text: widget.habit.name);
  late final TextEditingController target = TextEditingController(text: widget.habit.target.toString());
  late HabitType type = widget.habit.type;

  @override
  void dispose() { name.dispose(); target.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Edit habit', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), const SizedBox(height: 18),
    TextField(controller: name, decoration: const InputDecoration(labelText: 'Habit name')), const SizedBox(height: 12),
    DropdownButtonFormField<HabitType>(initialValue: type, decoration: const InputDecoration(labelText: 'Goal type'), items: HabitType.values.map((value) => DropdownMenuItem(value: value, child: Text(value.name[0].toUpperCase() + value.name.substring(1)))).toList(), onChanged: (value) { if (value != null) setState(() => type = value); }), const SizedBox(height: 12),
    TextField(controller: target, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Daily target')), const SizedBox(height: 16),
    FilledButton(onPressed: () { ref.read(appProvider).updateHabit(Habit(id: widget.habit.id, name: name.text.trim().isEmpty ? widget.habit.name : name.text.trim(), type: type, target: double.tryParse(target.text) ?? widget.habit.target, unit: type == HabitType.boolean ? null : 'units', frequency: widget.habit.frequency)); Navigator.pop(context); }, child: const Text('Save changes')),
  ])));
}

class AddHabitSheet extends ConsumerStatefulWidget { const AddHabitSheet({super.key}); @override ConsumerState<AddHabitSheet> createState() => _AddHabitSheetState(); }
class _AddHabitSheetState extends ConsumerState<AddHabitSheet> { final name = TextEditingController(); final target = TextEditingController(text: '1'); HabitType type = HabitType.boolean;
  @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('New habit', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), const SizedBox(height: 18), TextField(controller: name, decoration: const InputDecoration(labelText: 'Habit name', hintText: 'e.g. Read a book')), const SizedBox(height: 12), DropdownButtonFormField<HabitType>(initialValue: type, decoration: const InputDecoration(labelText: 'Goal type'), items: HabitType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name[0].toUpperCase() + t.name.substring(1)))).toList(), onChanged: (v) => setState(() => type = v!)), const SizedBox(height: 12), TextField(controller: target, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Daily target')), const SizedBox(height: 16), FilledButton(onPressed: () { ref.read(appProvider).addHabit(name.text.isEmpty ? 'New habit' : name.text, type, double.tryParse(target.text) ?? 1, type == HabitType.boolean ? null : 'units'); Navigator.pop(context); }, child: const Text('Add habit'))]))); }

class BrandMark extends StatelessWidget { const BrandMark({super.key}); @override Widget build(BuildContext context) => Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF6257D9), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.link, color: Colors.white)), const SizedBox(width: 10), const Text('duet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))]); }
