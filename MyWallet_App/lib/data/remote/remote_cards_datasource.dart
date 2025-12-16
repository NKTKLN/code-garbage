import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/card_item.dart';

class RemoteCardsDataSource {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _ref(String uid) =>
      _db.collection('users').doc(uid).collection('cards');

  Future<List<CardItem>> fetchAll(String uid) async {
    final snap = await _ref(uid).get();
    return snap.docs.map((d) => CardItem.fromJson(d.data())).toList();
  }

  Stream<List<CardItem>> watchAll(String uid) {
    return _ref(uid).snapshots().map(
          (snap) => snap.docs.map((d) => CardItem.fromJson(d.data())).toList(),
        );
  }

  Future<void> upsert(String uid, CardItem card) async {
    await _ref(uid).doc(card.id).set(card.toJson(), SetOptions(merge: true));
  }
}
