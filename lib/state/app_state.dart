import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/challenge.dart';
import '../models/habit.dart';
import '../services/app_repository.dart';
import '../services/auth_service.dart';
import '../services/habit_engine.dart';
import '../services/invite_service.dart';
import '../services/local_database.dart';
import '../services/totp_service.dart';

class AppState extends ChangeNotifier {
  static const adminEmail = LocalDebugAuthService.adminEmail;
  static const adminPassword = LocalDebugAuthService.adminPassword;
  final AppRepository database;
  final AuthService authService = LocalDebugAuthService();
  final InviteService inviteService = LocalDebugInviteService();
  final habits = <Habit>[const Habit(id: 'study', name: 'Study DSA', type: HabitType.duration, target: 120, unit: 'min')];
  final logs = <HabitLog>[];
  bool signedIn = false;
  bool isSuperAdmin = false;
  bool onboardingComplete = false;
  String buddyStatus = 'ended';
  String? inviteCode;
  String? inviteSecret;
  bool darkMode = false;
  final notificationPreferences = <String, bool>{'dailyReminders': true, 'buddyActivity': true, 'accountabilityNudges': true, 'syncUpdates': true, 'streakRisk': true};
  final notifications = <String>[];
  final challenges = <DuetChallenge>[];
  final buddyActivity = <String>['Alex completed Running', 'You completed Study DSA'];
  String? lastBuddyReaction;
  bool isLoaded = false;
  late final Future<void> _databaseReady;
  Future<void> _saveQueue = Future<void>.value();

  AppState({AppRepository? repository}) : database = repository ?? LocalDatabase() {
    final today = DateTime.now();
    logs.add(HabitLog(habitId: 'study', date: today, value: 90));
    for (var daysAgo = 1; daysAgo < 7; daysAgo++) {
      logs.add(HabitLog(habitId: 'study', date: today.subtract(Duration(days: daysAgo)), value: [105, 120, 75, 90, 110, 60][daysAgo - 1].toDouble()));
    }
    _databaseReady = _load();
  }

  Future<void> _load() async {
    await database.init();
    final savedHabits = database.loadHabits();
    final savedLogs = database.loadLogs();
    final savedChallenges = database.getSetting<String>('challenges');
    if (savedChallenges != null) {
      try {
        challenges.addAll((jsonDecode(savedChallenges) as List).map((item) => DuetChallenge.fromJson(item as Map<String, dynamic>)));
      } on FormatException {
        // Ignore malformed prototype data and keep the app usable.
      }
    }
    if (savedHabits.isNotEmpty) habits..clear()..addAll(savedHabits);
    if (savedLogs.isNotEmpty) logs..clear()..addAll(savedLogs);
    signedIn = database.getSetting<bool>('signedIn') ?? false;
    isSuperAdmin = database.getSetting<bool>('isSuperAdmin') ?? false;
    if (!kDebugMode) {
      signedIn = false;
      isSuperAdmin = false;
    }
    buddyStatus = database.getSetting<String>('buddyStatus') ?? 'ended';
    inviteCode = database.getSetting<String>('inviteCode');
    inviteSecret = database.getSetting<String>('inviteSecret');
    if (inviteCode != null && !RegExp(r'^[A-Z0-9]{6}$').hasMatch(inviteCode!)) {
      inviteCode = TotpService.createInviteCode();
      await database.setSetting('inviteCode', inviteCode);
    }
    darkMode = database.getSetting<bool>('darkMode') ?? false;
    for (final key in notificationPreferences.keys) {
      notificationPreferences[key] = database.getSetting<bool>('notify_$key') ?? notificationPreferences[key]!;
    }
    isLoaded = true;
    notifyListeners();
  }

  Future<void> _save() {
    _saveQueue = _saveQueue.then((_) async {
      await _databaseReady;
      await Future.wait([
        database.saveHabits(habits), database.saveLogs(logs),
        database.setSetting('signedIn', signedIn), database.setSetting('isSuperAdmin', isSuperAdmin), database.setSetting('buddyStatus', buddyStatus),
        database.setSetting('inviteCode', inviteCode), database.setSetting('inviteSecret', inviteSecret), database.setSetting('darkMode', darkMode),
        database.setSetting('challenges', jsonEncode(challenges.map((challenge) => challenge.toJson()).toList())),
        ...notificationPreferences.entries.map((entry) => database.setSetting('notify_${entry.key}', entry.value)),
      ]);
    });
    return _saveQueue;
  }

  void setSignedIn(bool value) { signedIn = value; _save(); notifyListeners(); }

  bool authenticate(String email, String password) {
    final result = authService.authenticate(email, password);
    if (!result.authenticated) return false;
    signedIn = true; isSuperAdmin = result.isSuperAdmin; _save(); notifyListeners(); return true;
  }

  bool get buddyPaired => buddyStatus == 'active';
  Iterable<Habit> get activeHabits => habits.where((habit) => !habit.archived);
  void toggleDarkMode(bool enabled) { darkMode = enabled; _save(); notifyListeners(); }

  String createInvite() {
    if (!kDebugMode) return '';
    final invite = inviteService.create();
    inviteCode = invite.code; inviteSecret = invite.secret; buddyStatus = 'pending'; _save(); notifyListeners(); return inviteCode!;
  }

  void acceptInvite() { buddyStatus = 'active'; _save(); notifyListeners(); }
  String get currentInviteOtp => inviteSecret == null ? '' : TotpService.generate(inviteSecret!);

  bool acceptInviteCode(String code, String otp) {
    if (!kDebugMode || inviteCode == null || inviteSecret == null) return false;
    if (!inviteService.validate(code, otp, InviteData(code: inviteCode!, secret: inviteSecret!))) return false;
    createInvite(); buddyStatus = 'active'; _save(); notifyListeners(); return true;
  }

  void endBuddy() { buddyStatus = 'ended'; _save(); notifyListeners(); }
  void reactToBuddy(String reaction) { lastBuddyReaction = reaction; buddyActivity.insert(0, 'You sent $reaction to Alex'); if (buddyActivity.length > 6) buddyActivity.removeLast(); _save(); notifyListeners(); }
  void nudgeBuddy() { notifications.insert(0, 'You sent Alex an encouragement nudge.'); buddyActivity.insert(0, 'You nudged Alex to keep going'); if (buddyActivity.length > 6) buddyActivity.removeLast(); _save(); notifyListeners(); }

  Future<void> resetLocalData() async {
    habits..clear()..add(const Habit(id: 'study', name: 'Study DSA', type: HabitType.duration, target: 120, unit: 'min'));
    logs.clear(); notifications.clear(); challenges.clear(); inviteCode = null; inviteSecret = null; lastBuddyReaction = null;
    buddyActivity..clear()..addAll(['Alex completed Running', 'You completed Study DSA']);
    buddyStatus = 'ended'; await _save(); notifyListeners();
  }

  double todayPercent(String id) { final habit = habits.firstWhere((h) => h.id == id); final log = logs.where((l) => l.habitId == id && HabitEngine.isSameDay(l.date, DateTime.now())).firstOrNull; return habit.percentage(log?.value ?? 0); }
  double averageForToday() => habits.isEmpty ? 0 : HabitEngine.averageForDate(habits, logs, DateTime.now());
  double percentForDate(Habit habit, DateTime date) => HabitEngine.completionForDate(habit, logs, date);
  double averageForDate(DateTime date, Iterable<Habit> selectedHabits) => HabitEngine.averageForDate(selectedHabits, logs, date);
  double buddyPercentForDate(DateTime date) { final daysAgo = DateTime.now().difference(DateTime(date.year, date.month, date.day)).inDays; return [78, 88, 64, 92, 72, 84, 78][daysAgo.clamp(0, 6)].toDouble(); }
  int streak(String id) => HabitEngine.streak(habits.firstWhere((h) => h.id == id), logs, DateTime.now());

  void checkIn(Habit habit, double value) {
    logs.removeWhere((l) => l.habitId == habit.id && HabitEngine.isSameDay(l.date, DateTime.now()));
    logs.add(HabitLog(habitId: habit.id, date: DateTime.now(), value: value));
    if (notificationPreferences['syncUpdates'] == true && value >= habit.target) notifications.insert(0, 'You completed ${habit.name}. Keep the duet going!');
    _save(); notifyListeners();
  }

  void setNotificationPreference(String key, bool enabled) { notificationPreferences[key] = enabled; _save(); notifyListeners(); }
  void addHabit(String name, HabitType type, double target, String? unit) { final normalizedName = name.trim(); if (normalizedName.isEmpty || !target.isFinite || target <= 0) return; habits.add(Habit(id: DateTime.now().microsecondsSinceEpoch.toString(), name: normalizedName, type: type, target: target, unit: unit)); _save(); notifyListeners(); }
  void addChallenge(String title, int duration, String? habitId) { if (title.trim().isEmpty || duration < 1 || duration > 365) return; challenges.insert(0, DuetChallenge(id: DateTime.now().microsecondsSinceEpoch.toString(), title: title, duration: duration, startDate: DateTime.now(), habitId: habitId)); _save(); notifyListeners(); }
  void updateChallenge(DuetChallenge challenge) { final index = challenges.indexWhere((item) => item.id == challenge.id); if (index == -1) return; challenges[index] = challenge; _save(); notifyListeners(); }
  void checkInChallenge(DuetChallenge challenge) {
    if (challenge.status != 'Active') return;
    final today = DateTime.now();
    final key = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    if (challenge.completedDateKeys.contains(key)) return;
    final completedDateKeys = [...challenge.completedDateKeys, key];
    final days = completedDateKeys.length < challenge.completedDays ? challenge.completedDays + 1 : completedDateKeys.length;
    updateChallenge(challenge.copyWith(completedDays: days, completedDateKeys: completedDateKeys, status: days >= challenge.duration ? 'Completed' : 'Active'));
  }
  void updateHabit(Habit updated) { if (updated.name.trim().isEmpty || !updated.target.isFinite || updated.target <= 0) return; final index = habits.indexWhere((habit) => habit.id == updated.id); if (index == -1) return; habits[index] = updated; _save(); notifyListeners(); }
  void archiveHabit(Habit habit) => updateHabit(habit.copyWith(archived: true));
}
