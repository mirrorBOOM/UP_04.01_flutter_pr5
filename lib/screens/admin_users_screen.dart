import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель администратора (Только Admin)'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 72, color: Colors.deepPurple),
            SizedBox(height: 16),
            Text('Управление доступом и персоналом', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Раздел доступен исключительно роли «Администратор» (п. 8 ТЗ).'),
          ],
        ),
      ),
    );
  }
}