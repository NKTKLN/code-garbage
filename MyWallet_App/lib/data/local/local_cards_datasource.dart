import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/models/card_item.dart';
import 'local_db.dart';

class LocalCardsDataSource {
  Box<String> get _box => LocalDb.cardsBox;

  Stream<BoxEvent> watch() => _box.watch();

  Future<void> upsert(CardItem card) async {
    await _box.put(card.id, jsonEncode(card.toJson()));
  }

  Future<void> deleteHard(String id) async {
    await _box.delete(id);
  }

  Future<void> markDeleted(CardItem card) async {
    await upsert(card);
  }

  List<CardItem> getAll() {
    return _box.values
        .map((s) => CardItem.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map)))
        .toList();
  }

  CardItem? getById(String id) {
    final s = _box.get(id);
    if (s == null) return null;
    return CardItem.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map));
  }
}
