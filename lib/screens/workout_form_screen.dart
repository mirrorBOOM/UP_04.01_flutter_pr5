import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/api_exceptions.dart';
import '../models/workout.dart';
import '../repositories/workout_repository.dart';
import '../repositories/persistent_workout_repository.dart';
import '../state/workout_list_notifier.dart';
import '../utils/validators.dart';

class WorkoutFormScreen extends StatefulWidget {
  final int? id;
  const WorkoutFormScreen({super.key, this.id});

  @override
  State<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

class _WorkoutFormScreenState extends State<WorkoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isDirty = false;
  bool _saving = false;
  Map<String, String> _serverErrors = {};

  late final TextEditingController _titleController;
  late final TextEditingController _codeController;
  late final TextEditingController _durationController;
  late final TextEditingController _caloriesController;

  int? _hallId;
  List<int> _selectedCategoryIds = [];

  bool get isEditing => widget.id != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _codeController = TextEditingController();
    _durationController = TextEditingController();
    _caloriesController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = context.read<FitnessClubRepository>();
      if (isEditing) {
        _loadData();
      } else {
        if (repo.allHalls.isNotEmpty) {
          setState(() => _hallId = repo.allHalls.first.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final repo = context.read<WorkoutRepository>();
    final item = await repo.findById(widget.id!);
    if (!mounted) return;
    if (item != null) {
      setState(() {
        _titleController.text = item.title;
        _codeController.text = item.code;
        _durationController.text = item.durationMinutes.toString();
        _caloriesController.text = item.caloriesBurned.toString();
        _hallId = item.hallId;
        _selectedCategoryIds = List.from(item.categoryIds);
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final workout = Workout(
      id: isEditing ? widget.id! : DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: _titleController.text.trim(),
      code: _codeController.text.trim(),
      durationMinutes: int.parse(_durationController.text.trim()),
      caloriesBurned: int.parse(_caloriesController.text.trim()),
      intensity: 3,
      hallId: _hallId ?? 1,
      trainerId: 1,
      categoryIds: _selectedCategoryIds,
      capacityTotal: 15,
      capacityAvailable: 15,
    );

    final repo = context.read<WorkoutRepository>();
    final notifier = context.read<WorkoutListNotifier>();

    try {
      await repo.save(workout);
      await notifier.load();
      if (!mounted) return;
      _isDirty = false;
      context.go('/');
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() => _serverErrors = e.errors);
      _formKey.currentState!.validate();
    } on ConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Конфликт данных (409): ${e.message}'),
          backgroundColor: Colors.orange,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FitnessClubRepository>();
    final halls = repo.allHalls;
    final categories = repo.allCategories;

    final availableCategories = categories.where((cat) {
      if (_hallId == 3) return cat.id == 4;
      if (_hallId == 2) return cat.id == 2 || cat.id == 3;
      return true;
    }).toList();

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _showDiscardDialog();
        if (leave && context.mounted) context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Редактирование тренировки' : 'Новая тренировка'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_isDirty) {
                final leave = await _showDiscardDialog();
                if (leave && context.mounted) context.go('/');
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                onChanged: () {
                  if (!_isDirty) setState(() => _isDirty = true);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Название программы *',
                        border: const OutlineInputBorder(),
                        errorText: _serverErrors['title'],
                      ),
                      validator: (v) =>
                          AppValidators.requiredField(v) ??
                          AppValidators.minLength(v, 3),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Артикул / Код программы *',
                        border: const OutlineInputBorder(),
                        errorText: _serverErrors['code'],
                      ),
                      validator: (val) {
                        if (_serverErrors.containsKey('code')) {
                          return _serverErrors['code'];
                        }
                        return AppValidators.requiredField(val);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      key: ValueKey('hall_$_hallId'),
                      initialValue: _hallId,
                      decoration: const InputDecoration(
                        labelText: 'Зал проведения',
                        border: OutlineInputBorder(),
                      ),
                      items: halls
                          .map((h) => DropdownMenuItem(
                                value: h.id,
                                child: Text(h.name),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _hallId = val;
                          _selectedCategoryIds.removeWhere(
                            (id) => !availableCategories.any((c) => c.id == id),
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    FormField<List<int>>(
                      initialValue: _selectedCategoryIds,
                      validator: (val) =>
                          (val == null || val.isEmpty)
                              ? 'Выберите хотя бы одну категорию'
                              : null,
                      builder: (field) {
                        return InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Категории фитнеса',
                            border: const OutlineInputBorder(),
                            errorText: field.errorText,
                          ),
                          child: Wrap(
                            spacing: 8,
                            children: availableCategories.map((cat) {
                              final isSelected =
                                  _selectedCategoryIds.contains(cat.id);
                              return FilterChip(
                                label: Text(cat.name),
                                selected: isSelected,
                                onSelected: (sel) {
                                  final next =
                                      List<int>.from(_selectedCategoryIds);
                                  sel ? next.add(cat.id) : next.remove(cat.id);
                                  field.didChange(next);
                                  setState(() => _selectedCategoryIds = next);
                                },
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            decoration: const InputDecoration(
                              labelText: 'Длительность (мин) *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: AppValidators.positiveInt,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _caloriesController,
                            decoration: const InputDecoration(
                              labelText: 'Калории (ккал) *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: AppValidators.positiveInt,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEditing
                                  ? 'Сохранить изменения'
                                  : 'Создать тренировку',
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showDiscardDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Несохранённые изменения'),
            content: const Text(
              'На форме есть несохранённые данные. Вы уверены, что хотите уйти?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Остаться'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Уйти'),
              ),
            ],
          ),
        ) ??
        false;
  }
}