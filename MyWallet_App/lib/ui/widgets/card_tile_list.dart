import 'package:flutter/material.dart';
import '../../domain/models/card_item.dart';

class CardTileList extends StatelessWidget {
  final CardItem card;
  final VoidCallback onTap;
  final VoidCallback onStar;

  const CardTileList({
    super.key,
    required this.card,
    required this.onTap,
    required this.onStar,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Color(card.colorValue);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name.isEmpty ? 'Без названия' : card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (card.description.trim().isNotEmpty)
                    Text(
                      card.description.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.75),
                        height: 1.25,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onStar,
              icon: Icon(
                card.favorite ? Icons.star_rounded : Icons.star_border_rounded,
                size: 22,
              ),
              color: Colors.white.withOpacity(0.9),
            ),
          ],
        ),
      ),
    );
  }
}
