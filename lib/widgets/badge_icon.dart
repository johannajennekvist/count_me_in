import 'package:flutter/material.dart';

/// (background, foreground) pairs cycled through by badge color index.
const badgeColors = [
  (Colors.amber, Color(0xFF8A6D00)),
  (Colors.lightBlue, Color(0xFF00587A)),
  (Colors.purple, Color(0xFF6A1B9A)),
  (Colors.pink, Color(0xFFAD1457)),
  (Colors.teal, Color(0xFF00695C)),
];

String formatCompactCount(int value) {
  if (value < 1000) return '$value';
  final divisor = value < 1000000 ? 1000 : 1000000;
  final suffix = value < 1000000 ? 'k' : 'M';
  final scaled = (value / divisor * 10).round() / 10;
  final isWhole = scaled == scaled.roundToDouble();
  return '${isWhole ? scaled.toInt() : scaled}$suffix';
}

const _monthAbbrev = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// The short "Jul 22" style date shown under a badge icon.
String formatBadgeDate(DateTime date) =>
    '${_monthAbbrev[date.month - 1]} ${date.day}';

/// Up to two uppercase initials for a display name, e.g. "Johanna
/// Jennekvist" -> "JJ", "Anonymous" -> "AN".
String initialsFor(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    final word = words.first;
    return word.length >= 2
        ? word.substring(0, 2).toUpperCase()
        : word.toUpperCase();
  }
  return (words[0][0] + words[1][0]).toUpperCase();
}

/// A trophy badge circle with a small compact-count chip in the corner,
/// e.g. the icon shown per-badge on the counter detail page and in the
/// goal-reached celebration popup.
class BadgeIcon extends StatelessWidget {
  final int value;
  final int colorIndex;
  final double size;

  const BadgeIcon({
    super.key,
    required this.value,
    required this.colorIndex,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = badgeColors[colorIndex % badgeColors.length];
    final scale = size / 56;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: background.shade100, shape: BoxShape.circle),
            child: Icon(Icons.emoji_events, color: foreground, size: size * 0.5),
          ),
          Positioned(
            right: -4 * scale,
            bottom: -4 * scale,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 5 * scale,
                vertical: 2 * scale,
              ),
              decoration: BoxDecoration(
                color: foreground,
                borderRadius: BorderRadius.circular(8 * scale),
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5 * scale,
                ),
              ),
              child: Text(
                formatCompactCount(value),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
