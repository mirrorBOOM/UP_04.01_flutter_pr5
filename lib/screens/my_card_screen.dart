import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';

class MyCardScreen extends StatelessWidget {
  const MyCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой абонемент (Кабинет клиента)'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.credit_card, size: 64, color: Colors.deepOrange),
                const SizedBox(height: 12),
                Text('Клиент: ${user?.fullName ?? ""}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Клубная карта: CARD-7749 (Активна до 31.12.2026)'),
                const Text('Тариф: Безлимит на все групповые тренировки'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}