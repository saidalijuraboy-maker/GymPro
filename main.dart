import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const WorkoutApp());
}

class WorkoutApp extends StatelessWidget {
  const WorkoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymPro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFE8FF47),
          onPrimary: const Color(0xFF0A0A0A),
          surface: const Color(0xFF111111),
          onSurface: const Color(0xFFF0F0F0),
          surfaceContainerHighest: const Color(0xFF1E1E1E),
          outline: const Color(0xFF2A2A2A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        fontFamily: 'SF Pro Display',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          foregroundColor: Color(0xFFF0F0F0),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF0F0F0),
            letterSpacing: -0.5,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

class Exercise {
  final String id;
  final String name;
  final String muscle;
  final String icon;

  const Exercise({required this.id, required this.name, required this.muscle, required this.icon});
}

class WorkoutSet {
  int reps;
  double weight;
  bool done;

  WorkoutSet({this.reps = 10, this.weight = 0, this.done = false});

  Map<String, dynamic> toJson() => {'reps': reps, 'weight': weight, 'done': done};
  factory WorkoutSet.fromJson(Map<String, dynamic> j) =>
      WorkoutSet(reps: j['reps'], weight: j['weight'].toDouble(), done: j['done']);
}

class WorkoutEntry {
  final String exerciseId;
  final String exerciseName;
  final List<WorkoutSet> sets;
  final DateTime date;

  WorkoutEntry({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'sets': sets.map((s) => s.toJson()).toList(),
        'date': date.toIso8601String(),
      };

  factory WorkoutEntry.fromJson(Map<String, dynamic> j) => WorkoutEntry(
        exerciseId: j['exerciseId'],
        exerciseName: j['exerciseName'],
        sets: (j['sets'] as List).map((s) => WorkoutSet.fromJson(s)).toList(),
        date: DateTime.parse(j['date']),
      );

  double get totalVolume => sets.fold(0, (sum, s) => sum + s.reps * s.weight);
  int get completedSets => sets.where((s) => s.done).length;
}

// ─────────────────────────────────────────────
// EXERCISES DATABASE
// ─────────────────────────────────────────────

const List<Exercise> kExercises = [
  Exercise(id: 'bench', name: 'Жим лёжа', muscle: 'Грудь', icon: '🏋️'),
  Exercise(id: 'squat', name: 'Приседания', muscle: 'Ноги', icon: '🦵'),
  Exercise(id: 'deadlift', name: 'Становая тяга', muscle: 'Спина', icon: '💪'),
  Exercise(id: 'pullup', name: 'Подтягивания', muscle: 'Спина', icon: '🔝'),
  Exercise(id: 'ohp', name: 'Жим стоя', muscle: 'Плечи', icon: '🙌'),
  Exercise(id: 'row', name: 'Тяга штанги', muscle: 'Спина', icon: '🤸'),
  Exercise(id: 'curl', name: 'Сгибание рук', muscle: 'Бицепс', icon: '💪'),
  Exercise(id: 'tricep', name: 'Разгибание рук', muscle: 'Трицепс', icon: '✊'),
  Exercise(id: 'lunge', name: 'Выпады', muscle: 'Ноги', icon: '🚶'),
  Exercise(id: 'plank', name: 'Планка', muscle: 'Пресс', icon: '🧘'),
  Exercise(id: 'dips', name: 'Отжимания на брусьях', muscle: 'Грудь', icon: '⬇️'),
  Exercise(id: 'calf', name: 'Подъём на носки', muscle: 'Ноги', icon: '👟'),
];

// ─────────────────────────────────────────────
// STORAGE SERVICE
// ─────────────────────────────────────────────

class StorageService {
  static const _key = 'workout_history';

  static Future<List<WorkoutEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded.map((e) => WorkoutEntry.fromJson(e)).toList();
  }

  static Future<void> saveHistory(List<WorkoutEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(history.map((e) => e.toJson()).toList()));
  }
}

// ─────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  final List<Widget> _pages = const [
    ExercisesPage(),
    ActiveWorkoutPage(),
    HistoryPage(),
    StatsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: const Color(0xFF111111),
        indicatorColor: const Color(0xFFE8FF47),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Упражнения'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline), label: 'Тренировка'),
          NavigationDestination(icon: Icon(Icons.history), label: 'История'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Прогресс'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EXERCISES PAGE
// ─────────────────────────────────────────────

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  String _filter = 'Все';

  List<String> get muscles {
    final m = kExercises.map((e) => e.muscle).toSet().toList()..sort();
    return ['Все', ...m];
  }

  List<Exercise> get filtered =>
      _filter == 'Все' ? kExercises : kExercises.where((e) => e.muscle == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('GymPro'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              '${kExercises.length} упражнений',
              style: TextStyle(color: color.primary, fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: muscles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final sel = muscles[i] == _filter;
                return GestureDetector(
                  onTap: () => setState(() => _filter = muscles[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? color.primary : color.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      muscles[i],
                      style: TextStyle(
                        color: sel ? color.onPrimary : color.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final ex = filtered[i];
                return _ExerciseTile(exercise: ex);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  const _ExerciseTile({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: exercise)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(exercise.icon, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(exercise.muscle,
                      style: TextStyle(color: color.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.outline),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EXERCISE DETAIL
// ─────────────────────────────────────────────

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: color.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(exercise.icon, style: const TextStyle(fontSize: 48))),
              ),
            ),
            const SizedBox(height: 24),
            _InfoRow(label: 'Группа мышц', value: exercise.muscle),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to active workout with this exercise pre-selected
                },
                icon: const Icon(Icons.add),
                label: const Text('Добавить в тренировку'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.primary,
                  foregroundColor: color.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color.onSurface.withOpacity(0.6))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ACTIVE WORKOUT PAGE
// ─────────────────────────────────────────────

class ActiveWorkoutPage extends StatefulWidget {
  const ActiveWorkoutPage({super.key});

  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  final List<WorkoutEntry> _entries = [];
  bool _started = false;
  late DateTime _startTime;
  Timer? _timer;
  int _elapsed = 0;

  // Rest timer
  Timer? _restTimer;
  int _restSeconds = 0;
  bool _restActive = false;

  void _startWorkout() {
    setState(() {
      _started = true;
      _startTime = DateTime.now();
      _elapsed = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed++);
    });
  }

  void _addExercise(Exercise ex) {
    setState(() {
      _entries.add(WorkoutEntry(
        exerciseId: ex.id,
        exerciseName: ex.name,
        sets: [WorkoutSet()],
        date: DateTime.now(),
      ));
    });
  }

  void _finishWorkout() async {
    _timer?.cancel();
    _restTimer?.cancel();
    final history = await StorageService.loadHistory();
    for (final entry in _entries) {
      history.add(WorkoutEntry(
        exerciseId: entry.exerciseId,
        exerciseName: entry.exerciseName,
        sets: entry.sets,
        date: DateTime.now(),
      ));
    }
    await StorageService.saveHistory(history);
    setState(() {
      _entries.clear();
      _started = false;
      _elapsed = 0;
      _restActive = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Тренировка сохранена!'), backgroundColor: Color(0xFF2A2A2A)),
      );
    }
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _restSeconds = seconds;
      _restActive = true;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restSeconds <= 1) {
        _restTimer?.cancel();
        setState(() => _restActive = false);
        HapticFeedback.heavyImpact();
      } else {
        setState(() => _restSeconds--);
      }
    });
  }

  String _formatTime(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    if (!_started) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: color.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.fitness_center, size: 56, color: color.primary),
              ),
              const SizedBox(height: 28),
              const Text('Готов к тренировке?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Начни отслеживать подходы и прогресс',
                  style: TextStyle(color: color.onSurface.withOpacity(0.5))),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _startWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.primary,
                  foregroundColor: color.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                child: const Text('Начать тренировку'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('⏱ ${_formatTime(_elapsed)}',
            style: TextStyle(color: color.primary, fontWeight: FontWeight.w800, fontSize: 22)),
        actions: [
          TextButton(
            onPressed: _entries.isEmpty ? null : _finishWorkout,
            child: Text('Завершить',
                style: TextStyle(
                    color: _entries.isEmpty ? color.outline : color.primary,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Rest timer banner
          if (_restActive)
            Container(
              width: double.infinity,
              color: color.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  '⏸ Отдых: ${_formatTime(_restSeconds)}',
                  style: TextStyle(
                      color: color.onPrimary, fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
            ),
          Expanded(
            child: _entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 64, color: color.outline),
                        const SizedBox(height: 16),
                        Text('Добавь упражнение',
                            style: TextStyle(
                                color: color.onSurface.withOpacity(0.5), fontSize: 17)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    itemBuilder: (ctx, i) => _ExerciseBlock(
                      entry: _entries[i],
                      onSetDone: () => _startRest(90),
                      onDelete: () => setState(() => _entries.removeAt(i)),
                      onChanged: () => setState(() {}),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF111111),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => _ExercisePicker(onPick: _addExercise),
        ),
        backgroundColor: color.primary,
        foregroundColor: color.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Упражнение', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  final WorkoutEntry entry;
  final VoidCallback onSetDone;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _ExerciseBlock({
    required this.entry,
    required this.onSetDone,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.outline),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Text(
                  kExercises.firstWhere((e) => e.id == entry.exerciseId,
                      orElse: () => kExercises.first).icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(entry.exerciseName,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onDelete),
              ],
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _colLabel('Подход', flex: 1),
                _colLabel('Повт.', flex: 2),
                _colLabel('Вес (кг)', flex: 2),
                _colLabel('✓', flex: 1),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...entry.sets.asMap().entries.map((e) => _SetRow(
                index: e.key,
                set: e.value,
                onDone: () {
                  e.value.done = !e.value.done;
                  if (e.value.done) onSetDone();
                  onChanged();
                },
                onChanged: onChanged,
              )),
          TextButton.icon(
            onPressed: () {
              entry.sets.add(WorkoutSet(
                  reps: entry.sets.isNotEmpty ? entry.sets.last.reps : 10,
                  weight: entry.sets.isNotEmpty ? entry.sets.last.weight : 0));
              onChanged();
            },
            icon: Icon(Icons.add, color: color.primary, size: 18),
            label: Text('Добавить подход',
                style: TextStyle(color: color.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _colLabel(String t, {required int flex}) => Expanded(
        flex: flex,
        child: Text(t,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
      );
}

class _SetRow extends StatelessWidget {
  final int index;
  final WorkoutSet set;
  final VoidCallback onDone;
  final VoidCallback onChanged;

  const _SetRow(
      {required this.index, required this.set, required this.onDone, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: set.done ? color.primary.withOpacity(0.08) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: Text('${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          Expanded(
            flex: 2,
            child: _NumField(
              value: set.reps.toString(),
              onChanged: (v) {
                set.reps = int.tryParse(v) ?? set.reps;
                onChanged();
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: _NumField(
              value: set.weight == 0 ? '' : set.weight.toString(),
              hint: '0',
              onChanged: (v) {
                set.weight = double.tryParse(v) ?? set.weight;
                onChanged();
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: GestureDetector(
                onTap: onDone,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: set.done ? color.primary : color.outline.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check,
                      size: 18, color: set.done ? color.onPrimary : Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  const _NumField({required this.value, required this.onChanged, this.hint = ''});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: TextFormField(
        initialValue: value,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        onChanged: onChanged,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)),
        ),
      ),
    );
  }
}

class _ExercisePicker extends StatelessWidget {
  final ValueChanged<Exercise> onPick;
  const _ExercisePicker({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              const Text('Выбери упражнение',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: kExercises.map((ex) {
              return ListTile(
                leading: Text(ex.icon, style: const TextStyle(fontSize: 22)),
                title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(ex.muscle, style: TextStyle(color: color.primary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  onPick(ex);
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// HISTORY PAGE
// ─────────────────────────────────────────────

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<WorkoutEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await StorageService.loadHistory();
    setState(() => _history = h.reversed.toList());
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('История'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: color.outline),
                  const SizedBox(height: 16),
                  Text('Нет записей', style: TextStyle(color: color.onSurface.withOpacity(0.5))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (ctx, i) {
                final entry = _history[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.outline),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.exerciseName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(entry.date),
                              style: TextStyle(
                                  color: color.onSurface.withOpacity(0.5), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${entry.completedSets}/${entry.sets.length} подходов',
                              style: TextStyle(
                                  color: color.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                          if (entry.totalVolume > 0)
                            Text('${entry.totalVolume.toStringAsFixed(0)} кг объём',
                                style: TextStyle(
                                    color: color.onSurface.withOpacity(0.5), fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────
// STATS PAGE
// ─────────────────────────────────────────────

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<WorkoutEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await StorageService.loadHistory();
    setState(() => _history = h);
  }

  int get totalWorkouts {
    final days = _history.map((e) =>
        '${e.date.year}-${e.date.month}-${e.date.day}').toSet();
    return days.length;
  }

  int get totalSets => _history.fold(0, (s, e) => s + e.completedSets);
  double get totalVolume => _history.fold(0.0, (s, e) => s + e.totalVolume);

  Map<String, int> get topExercises {
    final map = <String, int>{};
    for (final e in _history) {
      map[e.exerciseName] = (map[e.exerciseName] ?? 0) + e.completedSets;
    }
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(5));
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Прогресс')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary cards
            Row(children: [
              _StatCard(label: 'Тренировок', value: '$totalWorkouts'),
              const SizedBox(width: 10),
              _StatCard(label: 'Подходов', value: '$totalSets'),
              const SizedBox(width: 10),
              _StatCard(label: 'Объём (т)', value: (totalVolume / 1000).toStringAsFixed(1)),
            ]),
            const SizedBox(height: 24),
            if (topExercises.isNotEmpty) ...[
              const Text('Топ упражнений',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 14),
              ...topExercises.entries.map((e) {
                final maxVal = topExercises.values.first;
                final ratio = e.value / maxVal;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('${e.value} подх.',
                              style:
                                  TextStyle(color: color.primary, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: color.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(color.primary),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Icon(Icons.bar_chart, size: 64, color: color.outline),
                    const SizedBox(height: 16),
                    Text('Начни тренироваться\nчтобы увидеть статистику',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: color.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900, color: color.primary)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 12, color: color.onSurface.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }
}
