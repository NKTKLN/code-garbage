import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/enums.dart';
import '../../state/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final settings = ref.watch(settingsControllerProvider);
    final settingsCtrl = ref.read(settingsControllerProvider.notifier);
    final cardsCtrl = ref.read(cardsControllerProvider.notifier);
    final authService = ref.read(authServiceProvider);

    final user = auth.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w500)),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 6),
          ListTile(
            title: const Text('Account', style: TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(user == null ? 'Not logged in (local only)' : 'Logged in: ${user.email ?? user.uid}'),
            trailing: TextButton(
              onPressed: () async {
                if (user == null) {
                  Navigator.pushNamed(context, '/login');
                } else {
                  await authService.signOut();
                }
              },
              child: Text(user == null ? 'Login' : 'Logout'),
            ),
          ),
          const Divider(),

          ListTile(
            title: const Text('Sync now'),
            subtitle: const Text('Merge local and cloud (last write wins)'),
            trailing: const Icon(Icons.sync),
            onTap: user == null ? null : () async => cardsCtrl.syncNow(),
          ),
          const Divider(),

          ListTile(
            title: const Text('Import JSON'),
            subtitle: const Text('Add cards from file'),
            trailing: const Icon(Icons.file_open),
            onTap: () async {
              final mode = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1C1C1C),
                  title: const Text('Import mode'),
                  content: const Text('Generate new IDs?\n(Use this if importing same file multiple times)'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep IDs')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('New IDs')),
                  ],
                ),
              );
              if (mode == null) return;
              await cardsCtrl.importJson(generateNewIds: mode);
            },
          ),
          ListTile(
            title: const Text('Export JSON'),
            subtitle: const Text('Share cards_export.json'),
            trailing: const Icon(Icons.ios_share),
            onTap: () async => cardsCtrl.exportJson(),
          ),
          const Divider(),

          ListTile(
            title: const Text('Layout'),
            subtitle: Text('Current: ${settings.layoutMode.name}'),
            trailing: DropdownButton<LayoutMode>(
              value: settings.layoutMode,
              items: [
                DropdownMenuItem(value: LayoutMode.list, child: const Text('List')),
                DropdownMenuItem(value: LayoutMode.grid, child: const Text('Grid')),
              ],
              onChanged: (v) => v == null ? null : settingsCtrl.setLayout(v),
            ),
          ),
          ListTile(
            title: const Text('Sort'),
            subtitle: Text('Current: ${settings.sortOrder.name}'),
            trailing: DropdownButton<SortOrder>(
              value: settings.sortOrder,
              items: [
                DropdownMenuItem(value: SortOrder.createdAt, child: const Text('Created')),
                DropdownMenuItem(value: SortOrder.name, child: const Text('Name')),
                DropdownMenuItem(value: SortOrder.lastUsed, child: const Text('Last used')),
                DropdownMenuItem(value: SortOrder.expiration, child: const Text('Expiration')),
              ],
              onChanged: (v) => v == null ? null : settingsCtrl.setSort(v),
            ),
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
