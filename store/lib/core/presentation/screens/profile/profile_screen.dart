import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${authProvider.user?.name ?? 'Guest'}'),
            const SizedBox(height: 8),
            Text('Email: ${authProvider.user?.email ?? 'Not signed in'}'),
            const SizedBox(height: 24),
            if (authProvider.isAdmin) ...[
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/admin/dashboard'),
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('Admin Dashboard'),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: authProvider.isAuthenticated ? authProvider.logout : null,
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
