import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../data/repositories/cards_repository.dart';
import '../domain/models/card_item.dart';
import '../domain/models/enums.dart';
import 'providers.dart';
import 'settings_controller.dart';

class CardsState {
  final List<CardItem> all;
  final bool favoritesOnly;
  final String search;

  const CardsState({
    required this.all,
    required this.favoritesOnly,
    required this.search,
  });

  CardsState copyWith({
    List<CardItem>? all,
    bool? favoritesOnly,
    String? search,
  }) {
    return CardsState(
      all: all ?? this.all,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      search: search ?? this.search,
    );
  }
}

class CardsController extends Notifier<CardsState> {
  StreamSubscription? _localSub;
  StreamSubscription? _cloudSub;

  @override
  CardsState build() {
    final repo = ref.read(cardsRepositoryProvider);

    final initial = CardsState(
      all: repo.getAllLocal(),
      favoritesOnly: false,
      search: '',
    );

    _localSub?.cancel();
    _localSub = ref.read(localCardsDataSourceProvider).watch().listen((_) {
      final repo = ref.read(cardsRepositoryProvider);
      state = state.copyWith(all: repo.getAllLocal());
    });

    ref.listen(authStateProvider, (prev, next) async {
      final user = next.asData?.value;
      final repo = ref.read(cardsRepositoryProvider);

      if (user != null) {
        await repo.syncFromCloudMerge();
        _startCloudWatch();
      } else {
        await _stopCloudWatch();
      }
    });

    ref.onDispose(() async {
      await _localSub?.cancel();
      await _cloudSub?.cancel();
    });

    return initial;
  }

  Future<void> _startCloudWatch() async {
    await _stopCloudWatch();
    final repo = ref.read(cardsRepositoryProvider);

    final stream = repo.watchCloud();
    if (stream == null) return;

    _cloudSub = stream.listen((cloudCards) async {
      final localDs = ref.read(localCardsDataSourceProvider);
      final local = ref.read(cardsRepositoryProvider).getAllLocal();
      final localMap = {for (final c in local) c.id: c};

      for (final cloud in cloudCards) {
        final loc = localMap[cloud.id];
        if (loc == null || cloud.updatedAtMs > loc.updatedAtMs) {
          await localDs.upsert(cloud);
        }
      }
    });
  }

  Future<void> _stopCloudWatch() async {
    await _cloudSub?.cancel();
    _cloudSub = null;
  }

  List<CardItem> visible(SettingsState settings) {
    final q = state.search.trim().toLowerCase();

    Iterable<CardItem> items = state.all.where((c) => !c.deleted);

    if (state.favoritesOnly) {
      items = items.where((c) => c.favorite);
    }

    if (q.isNotEmpty) {
      items = items.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          c.codeValue.toLowerCase().contains(q));
    }

    final list = items.toList();

    switch (settings.sortOrder) {
      case SortOrder.createdAt:
        list.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
        break;
      case SortOrder.name:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOrder.lastUsed:
        int lm(CardItem x) => x.lastUsedAtMs ?? 0;
        list.sort((a, b) => lm(b).compareTo(lm(a)));
        break;
      case SortOrder.expiration:
        int em(CardItem x) => x.expiresAtMs ?? (1 << 60);
        list.sort((a, b) => em(a).compareTo(em(b)));
        break;
    }

    return list;
  }

  void setSearch(String s) => state = state.copyWith(search: s);

  void toggleFavoritesOnly() =>
      state = state.copyWith(favoritesOnly: !state.favoritesOnly);

  Future<CardItem> createEmpty() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = const Uuid().v4();
    return CardItem(
      id: id,
      name: '',
      description: '',
      codeType: CodeType.qr,
      codeValue: '',
      colorValue: 0xFFB71C1C,
      favorite: false,
      deleted: false,
      createdAtMs: now,
      updatedAtMs: now,
      expiresAtMs: null,
      lastUsedAtMs: null,
    );
  }

  Future<void> save(CardItem card) async {
    final repo = ref.read(cardsRepositoryProvider);
    await repo.save(card.copyWith(updatedAtMs: DateTime.now().millisecondsSinceEpoch));
  }

  Future<void> toggleFavorite(CardItem card) async {
    await save(card.copyWith(favorite: !card.favorite));
  }

  Future<void> markUsed(CardItem card) async {
    await save(card.copyWith(lastUsedAtMs: DateTime.now().millisecondsSinceEpoch));
  }

  Future<void> delete(CardItem card) async {
    final repo = ref.read(cardsRepositoryProvider);
    await repo.softDelete(card);
  }

  Future<void> syncNow() async {
    final repo = ref.read(cardsRepositoryProvider);
    await repo.syncFromCloudMerge();
  }

  Future<void> exportJson() async {
    final cards = state.all.where((c) => !c.deleted).map((c) => c.toJson()).toList();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(cards);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/cards_export.json');
    await file.writeAsString(jsonStr);

    await Share.shareXFiles([XFile(file.path)], text: 'Мои карты');
  }

  Future<void> importJson({bool generateNewIds = false}) async {
    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (pick == null || pick.files.single.path == null) return;

    final file = File(pick.files.single.path!);
    final content = await file.readAsString();

    final list = jsonDecode(content) as List;
    final repo = ref.read(cardsRepositoryProvider);

    for (final item in list) {
      final card = CardItem.fromJson(Map<String, dynamic>.from(item as Map));
      final now = DateTime.now().millisecondsSinceEpoch;

      final normalized = generateNewIds
          ? card.copyWith(id: const Uuid().v4(), createdAtMs: now, updatedAtMs: now, deleted: false)
          : card.copyWith(updatedAtMs: now, deleted: false);

      await repo.save(normalized);
    }
  }
}
