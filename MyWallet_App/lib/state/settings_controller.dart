import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/local_settings_datasource.dart';
import '../domain/models/enums.dart';
import 'providers.dart';

class SettingsState {
  final LayoutMode layoutMode;
  final SortOrder sortOrder;

  const SettingsState({
    required this.layoutMode,
    required this.sortOrder,
  });

  SettingsState copyWith({
    LayoutMode? layoutMode,
    SortOrder? sortOrder,
  }) {
    return SettingsState(
      layoutMode: layoutMode ?? this.layoutMode,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final ds = ref.read(localSettingsProvider);
    final s = ds.load();
    return SettingsState(layoutMode: s.layoutMode, sortOrder: s.sortOrder);
  }

  Future<void> setLayout(LayoutMode mode) async {
    state = state.copyWith(layoutMode: mode);
    final ds = ref.read(localSettingsProvider);
    await ds.save(layoutMode: state.layoutMode, sortOrder: state.sortOrder);
  }

  Future<void> setSort(SortOrder order) async {
    state = state.copyWith(sortOrder: order);
    final ds = ref.read(localSettingsProvider);
    await ds.save(layoutMode: state.layoutMode, sortOrder: state.sortOrder);
  }
}
