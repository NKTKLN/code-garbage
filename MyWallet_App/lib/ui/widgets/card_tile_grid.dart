import 'package:flutter/material.dart';
import '../../domain/models/card_item.dart';

class CardTileGrid extends StatelessWidget {
  final CardItem card;
  final VoidCallback onTap;
  final VoidCallback onStar;

  const CardTileGrid({
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
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Positioned(
              right: -4,
              top: -4,
              child: IconButton(
                onPressed: onStar,
                icon: Icon(
                  card.favorite ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 22,
                ),
                color: Colors.white.withOpacity(0.95),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  card.name.isEmpty ? 'Без названия' : card.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                if (card.description.trim().isNotEmpty)
                  Text(
                    card.description.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.25,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
