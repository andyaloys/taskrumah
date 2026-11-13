import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _ymdFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _readableFormat = DateFormat('EEEE, d MMM yyyy', 'id_ID');

  /// Formats Date into YYYY-MM-DD string using local device calendar (WIB safe)
  static String formatYmd(DateTime date) {
    return _ymdFormat.format(date);
  }

  static String todayYmd() {
    return formatYmd(DateTime.now());
  }

  static String yesterdayYmd() {
    return formatYmd(DateTime.now().subtract(const Duration(days: 1)));
  }

  static String tomorrowYmd() {
    return formatYmd(DateTime.now().add(const Duration(days: 1)));
  }

  static String formatReadable(DateTime date) {
    return _readableFormat.format(date);
  }
}
