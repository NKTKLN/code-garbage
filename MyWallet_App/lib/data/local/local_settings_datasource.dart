import 'dart:convert';

import '../../domain/models/enums.dart';
import 'local_db.dart';

class LocalSettingsDataSource {
  static const _key = 'ui_settings';

  Future<void> save({
    required LayoutMode layoutMode,
    required SortOrder sortOrder,
  }) async {
    final json = jsonEncode({
      'layoutMode': layoutMode.name,
      'sortOrder': sortOrder.name,
    });
    await LocalDb.settingsBox.put(_key, json);
  }

  ({LayoutMode layoutMode, SortOrder sortOrder}) load() {
    final s = LocalDb.settingsBox.get(_key);
    if (s == null) {
      return (layoutMode: LayoutMode.grid, sortOrder: SortOrder.createdAt);
    }
    final m = jsonDecode(s) as Map<String, dynamic>;
    return (
      layoutMode: LayoutMode.values.byName((m['layoutMode'] as String?) ?? 'grid'),
      sortOrder: SortOrder.values.byName((m['sortOrder'] as String?) ?? 'createdAt'),
    );
  }
}
