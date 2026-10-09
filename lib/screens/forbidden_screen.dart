import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Доступ запрещён (403)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gpp_bad, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text('403 Forbidden', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('У вашей роли недостаточно прав для просмотра этого раздела.'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Вернуться в каталог'),
            ),
          ],
        ),
      ),
    );
  }
}