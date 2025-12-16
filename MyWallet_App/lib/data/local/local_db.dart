import 'package:hive_flutter/hive_flutter.dart';

class LocalDb {
  static late Box<String> cardsBox;
  static late Box<String> settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    cardsBox = await Hive.openBox<String>('cards');       // id -> json string
    settingsBox = await Hive.openBox<String>('settings'); // key -> json string
  }
}
