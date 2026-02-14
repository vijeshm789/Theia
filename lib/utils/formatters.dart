import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrencyFormat = NumberFormat.compactCurrency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _percentFormat = NumberFormat.decimalPercentPattern(
    decimalDigits: 2,
  );

  static final NumberFormat _numberFormat = NumberFormat('#,##0.00');

  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy hh:mm a');
  static final DateFormat _shortDateFormat = DateFormat('MMM dd');
  static final DateFormat _chartDateFormat = DateFormat('dd/MM');

  static String formatCurrency(double value) {
    return _currencyFormat.format(value);
  }

  static String formatCompactCurrency(double value) {
    return _compactCurrencyFormat.format(value);
  }

  static String formatPercent(double value) {
    return _percentFormat.format(value / 100);
  }

  static String formatNumber(double value) {
    return _numberFormat.format(value);
  }

  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  static String formatShortDate(DateTime dateTime) {
    return _shortDateFormat.format(dateTime);
  }

  static String formatChartDate(DateTime dateTime) {
    return _chartDateFormat.format(dateTime);
  }

  static String formatPriceChange(double change) {
    final prefix = change >= 0 ? '+' : '';
    return '$prefix${_numberFormat.format(change)}';
  }

  static String formatPercentChange(double change) {
    final prefix = change >= 0 ? '+' : '';
    return '$prefix${change.toStringAsFixed(2)}%';
  }

  static String timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '${minutes}m ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '${hours}h ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '${days}d ago';
    } else {
      return formatShortDate(dateTime);
    }
  }
}
