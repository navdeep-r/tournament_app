import 'package:intl/intl.dart';

// ─── Date Formatter ───────────────────────────────────────────────────────────
abstract class DateFormatter {
  static String formatDate(DateTime dt) =>
      DateFormat('d MMM yyyy').format(dt);

  static String formatDateTime(DateTime dt) =>
      DateFormat('d MMM yyyy, h:mm a').format(dt);

  static String formatTime(DateTime dt) =>
      DateFormat('h:mm a').format(dt);

  static String formatShortDate(DateTime dt) =>
      DateFormat('d MMM').format(dt);

  static String formatDayOfWeek(DateTime dt) =>
      DateFormat('EEEE').format(dt);

  /// "2h 30m" or "45m" or "Starts in 3d"
  static String formatCountdown(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return 'Started';
    if (diff.inDays >= 1) return 'Starts in ${diff.inDays}d';
    if (diff.inHours >= 1) {
      final mins = diff.inMinutes.remainder(60);
      return '${diff.inHours}h ${mins}m';
    }
    return '${diff.inMinutes}m';
  }

  /// "Registration closes in 2h 30m"
  static String formatRegistrationDeadline(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return 'Registration closed';
    return 'Registration closes in ${formatCountdown(deadline)}';
  }

  static bool isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  static bool isTomorrow(DateTime dt) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day;
  }

  /// "Today", "Tomorrow", or "19 Apr"
  static String formatRelativeDate(DateTime dt) {
    if (isToday(dt)) return 'Today';
    if (isTomorrow(dt)) return 'Tomorrow';
    return formatShortDate(dt);
  }
}

// ─── Currency Formatter ───────────────────────────────────────────────────────
abstract class CurrencyFormatter {
  static final _rupeeFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Converts paise to formatted rupee string: 20000 → "₹200"
  static String fromPaise(int paise) =>
      _rupeeFormat.format(paise / 100);

  /// Formats rupee amount directly: 200 → "₹200"
  static String fromRupees(double rupees) =>
      _rupeeFormat.format(rupees);

  /// "₹200" with discount strike-through text pieces
  static String discountLabel(int discountPaise) =>
      '- ${fromPaise(discountPaise)}';

  /// Convert paise to double rupees
  static double paiseToRupees(int paise) => paise / 100;
}
