import 'enums.dart';

class CardItem {
  final String id;
  final String name;
  final String description;

  final CodeType codeType;
  final String codeValue;

  final int colorValue;

  final bool favorite;
  final bool deleted;

  final int createdAtMs;
  final int updatedAtMs;
  final int? expiresAtMs;
  final int? lastUsedAtMs;

  const CardItem({
    required this.id,
    required this.name,
    required this.description,
    required this.codeType,
    required this.codeValue,
    required this.colorValue,
    this.favorite = false,
    this.deleted = false,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.expiresAtMs,
    this.lastUsedAtMs,
  });

  CardItem copyWith({
    String? id,
    String? name,
    String? description,
    CodeType? codeType,
    String? codeValue,
    int? colorValue,
    bool? favorite,
    bool? deleted,
    int? createdAtMs,
    int? updatedAtMs,
    int? expiresAtMs,
    int? lastUsedAtMs,
  }) {
    return CardItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      codeType: codeType ?? this.codeType,
      codeValue: codeValue ?? this.codeValue,
      colorValue: colorValue ?? this.colorValue,
      favorite: favorite ?? this.favorite,
      deleted: deleted ?? this.deleted,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
      lastUsedAtMs: lastUsedAtMs ?? this.lastUsedAtMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'codeType': codeType.name,
        'codeValue': codeValue,
        'colorValue': colorValue,
        'favorite': favorite,
        'deleted': deleted,
        'createdAtMs': createdAtMs,
        'updatedAtMs': updatedAtMs,
        'expiresAtMs': expiresAtMs,
        'lastUsedAtMs': lastUsedAtMs,
      };

  static CardItem fromJson(Map<String, dynamic> json) {
    return CardItem(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      codeType: CodeType.values.byName((json['codeType'] as String?) ?? 'qr'),
      codeValue: (json['codeValue'] as String?) ?? '',
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFFB71C1C,
      favorite: (json['favorite'] as bool?) ?? false,
      deleted: (json['deleted'] as bool?) ?? false,
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      updatedAtMs: (json['updatedAtMs'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      expiresAtMs: (json['expiresAtMs'] as num?)?.toInt(),
      lastUsedAtMs: (json['lastUsedAtMs'] as num?)?.toInt(),
    );
  }
}
