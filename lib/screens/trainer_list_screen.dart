import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/trainer.dart';
import '../repositories/persistent_workout_repository.dart';
import '../widgets/entity_table.dart';

class TrainerListScreen extends StatefulWidget {
  const TrainerListScreen({super.key});

  @override
  State<TrainerListScreen> createState() => _TrainerListScreenState();
}

class _TrainerListScreenState extends State<TrainerListScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FitnessClubRepository>();
    final trainers = repo.allTrainers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренеры клуба (CRUD)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/trainers/new'),
        icon: const Icon(Icons.person_add),
        label: const Text('Добавить тренера'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: trainers.isEmpty
              ? const Center(child: Text('Список тренеров пуст'))
              : EntityTable<Trainer>(
                  items: trainers,
                  idOf: (t) => t.id,
                  columns: [
                    TableColumnSpec(
                      label: 'ФИО',
                      build: (t) => Text(
                        t.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TableColumnSpec(
                      label: 'Специализация',
                      build: (t) => Text(t.specialization),
                    ),
                    TableColumnSpec(
                      label: 'Категория',
                      build: (t) => Text(t.category),
                    ),
                    TableColumnSpec(
                      label: 'Опыт',
                      numeric: true,
                      build: (t) => Text('${t.experienceYears} лет'),
                    ),
                  ],
                  actions: (t) => [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Редактировать',
                      onPressed: () => context.go('/trainers/${t.id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Удалить',
                      onPressed: () async {
                        await repo.deleteTrainer(t.id);
                        setState(() {});
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}