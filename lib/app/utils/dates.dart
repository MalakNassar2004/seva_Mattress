/// Date and time formatting shared by every screen, so dates read the
/// same everywhere ("Oct 24, 2024", "8:42 AM", "Today — Thursday, Oct 24").
library;

const _months = [
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

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// "Oct 24, 2024"
String formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

/// "Oct 24"
String formatShortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

/// "8:42 AM"
String formatTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// "Today, 8:15 AM" / "Yesterday, 4:30 PM" / "Oct 18, 2024 · 2:15 PM"
String formatWhen(DateTime d) {
  final days = dateOnly(DateTime.now()).difference(dateOnly(d)).inDays;
  if (days == 0) return 'Today, ${formatTime(d)}';
  if (days == 1) return 'Yesterday, ${formatTime(d)}';
  return '${formatDate(d)} · ${formatTime(d)}';
}

/// "Thursday, Oct 24, 2024 at 8:15 AM"
String formatFull(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${formatDate(d)} at ${formatTime(d)}';

/// Group header: "Today — Thursday, Oct 24" / "Yesterday — ..." /
/// "Monday, Oct 21, 2024".
String formatDayHeader(DateTime d) {
  final days = dateOnly(DateTime.now()).difference(dateOnly(d)).inDays;
  final day = '${_weekdays[d.weekday - 1]}, ${formatShortDate(d)}';
  if (days == 0) return 'Today — $day';
  if (days == 1) return 'Yesterday — $day';
  return '${_weekdays[d.weekday - 1]}, ${formatDate(d)}';
}

/// "Just now" / "8m ago" / "2h ago" / "Yesterday" / "Oct 18"
String formatAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24 && dateOnly(d) == dateOnly(DateTime.now())) {
    return '${diff.inHours}h ago';
  }
  final days = dateOnly(DateTime.now()).difference(dateOnly(d)).inDays;
  if (days == 1) return 'Yesterday';
  return formatShortDate(d);
}
