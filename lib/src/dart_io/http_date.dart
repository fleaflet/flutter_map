// Frequently used character codes.
import 'package:flutter_map/src/dart_io/http_exception.dart';
// ignore_for_file: constant_identifier_names

class _CharCode {
  static const int NONE = -1;
  static const int SP = 0x20;
  static const int COMMA = 0x2C;
  static const int MINUS = 0x2D;
  static const int COLON = 0x3A;
  static const int LETTER_a = 0x61;
  static const int LETTER_z = 0x7A;
}

/// Utility functions for working with dates with HTTP specific date
/// formats.
class HttpDate {
  /// Format a date according to
  /// [RFC-1123](http://tools.ietf.org/html/rfc1123 "RFC-1123"),
  /// e.g. `Thu, 1 Jan 1970 00:00:00 GMT`.
  static String format(DateTime date) {
    final StringBuffer sb = StringBuffer();
    _formatTo(date, sb);
    return sb.toString();
  }

  static String _formatTo(DateTime date, StringSink sb) {
    final DateTime d = date.toUtc();
    sb
      ..write(_weekdayAbbreviations[d.weekday - 1])
      ..write(', ')
      ..write(d.day <= 9 ? '0' : '')
      ..write(d.day.toString())
      ..write(' ')
      ..write(_monthAbbreviations[d.month - 1])
      ..write(' ')
      ..write(d.year.toString())
      ..write(d.hour <= 9 ? ' 0' : ' ')
      ..write(d.hour.toString())
      ..write(d.minute <= 9 ? ':0' : ':')
      ..write(d.minute.toString())
      ..write(d.second <= 9 ? ':0' : ':')
      ..write(d.second.toString())
      ..write(' GMT');
    return sb.toString();
  }

  // From RFC-2616 section "3.3.1 Full Date",
  // http://tools.ietf.org/html/rfc2616#section-3.3.1
  //
  // HTTP-date    = rfc1123-date | rfc850-date | asctime-date
  // rfc1123-date = wkday "," SP date1 SP time SP "GMT"
  // rfc850-date  = weekday "," SP date2 SP time SP "GMT"
  // asctime-date = wkday SP date3 SP time SP 4DIGIT
  // date1        = 2DIGIT SP month SP 4DIGIT
  //                ; day month year (e.g., 02 Jun 1982)
  // date2        = 2DIGIT "-" month "-" 2DIGIT
  //                ; day-month-year (e.g., 02-Jun-82)
  // date3        = month SP ( 2DIGIT | ( SP 1DIGIT ))
  //                ; month day (e.g., Jun  2)
  // time         = 2DIGIT ":" 2DIGIT ":" 2DIGIT
  //                ; 00:00:00 - 23:59:59
  // wkday        = "Mon" | "Tue" | "Wed"
  //              | "Thu" | "Fri" | "Sat" | "Sun"
  // weekday      = "Monday" | "Tuesday" | "Wednesday"
  //              | "Thursday" | "Friday" | "Saturday" | "Sunday"
  // month        = "Jan" | "Feb" | "Mar" | "Apr"
  //              | "May" | "Jun" | "Jul" | "Aug"
  //              | "Sep" | "Oct" | "Nov" | "Dec"

  static const List<String> _weekdayAbbreviations = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _monthAbbreviations = <String>[
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

  /// Parse a date string in either of the formats
  /// [RFC-1123](http://tools.ietf.org/html/rfc1123 "RFC-1123"),
  /// [RFC-850](http://tools.ietf.org/html/rfc850 "RFC-850") or
  /// ANSI C's asctime() format. These formats are listed here.
  ///
  /// * Thu, 1 Jan 1970 00:00:00 GMT
  /// * Thursday, 1-Jan-1970 00:00:00 GMT
  /// * Thu Jan  1 00:00:00 1970
  ///
  /// For more information see [RFC-2616 section
  /// 3.1.1](http://tools.ietf.org/html/rfc2616#section-3.3.1
  /// "RFC-2616 section 3.1.1").
  static DateTime parse(String date) =>
      _parse(date, 0, date.length, _invalidHttpDate, isCookieDate: false);

  static Never _invalidHttpDate(String source, int start, int end) =>
      throw HttpException('Invalid HTTP date ${source.substring(start, end)}');

  /// Implements [parse] on a substring.
  ///
  /// If [isCookieDate] is `true`, also accepts `Thu, 1-Jan-1970 00:00:00 GMT`,
  /// with `-`s between day-month-year.
  /// This format was accepted by the special Cookie-date parser,
  /// which now uses this function too.
  static DateTime _parse(
    String source,
    int start,
    int end,
    Never Function(String, int, int) onError, {
    required bool isCookieDate,
  }) {
    // Almost same format after the week-day, only differ by one character.
    const int formatRfc1123 = _CharCode.SP;
    const int formatRfc850 = _CharCode.MINUS;
    // Separate format.
    const int formatAsctime = 0;

    int index = start;

    Never throwError() {
      onError(source, start, end);
    }

    bool maybeExpectChar(int charCode) {
      if (index < end && source.codeUnitAt(index) == charCode) {
        index++;
        return true;
      }
      return false;
    }

    void expectChar(int charCode) {
      if (!maybeExpectChar(charCode)) throwError();
    }

    // Detects one of three recognized formats.
    //
    // All three formats start with the week-day in different ways:
    // * `Mon `: [formatAsctime]
    // * `Mon,`: [formatRfc1123]
    // * `Monday,`: [formatRfc850]
    int expectWeekday() {
      for (var i = 0; i < _weekdayAbbreviations.length; i++) {
        final wkday =
            _weekdayAbbreviations[i]; // Three-letter day abbreviation.
        assert(wkday.length == 3, '3 letters expected');
        if (index + 3 <= end && _isTextNoCase(source, index, 3, wkday)) {
          final weekday = _weekdays[i]; // Unabbreviated day.
          // Check if following characters are the rest of the day name.
          if (index + weekday.length <= end &&
              _isTextNoCase(
                source,
                index + 3,
                weekday.length - 3,
                weekday,
                3,
              )) {
            index += weekday.length;
            expectChar(_CharCode.COMMA);
            return formatRfc850;
          }
          index += 3;
          if (index < end) {
            final nextChar = source.codeUnitAt(index);
            if (nextChar == _CharCode.COMMA) {
              index++;
              return formatRfc1123;
            }
            if (nextChar == _CharCode.SP) {
              index++;
              return formatAsctime;
            }
          }
          break;
        }
      }
      throwError();
    }

    int expectMonth() {
      for (var i = 0; i < _monthAbbreviations.length; i++) {
        final String monthAbbreviation = _monthAbbreviations[i];
        assert(monthAbbreviation.length == 3, '3 letters expected');
        if (index + 3 <= end &&
            _isTextNoCase(source, index, 3, monthAbbreviation)) {
          index += 3;
          return i;
        }
      }
      throwError();
    }

    int expectNum(int maxLength) {
      int value = 0;
      final int start = index;
      while (index < end) {
        final int digit = source.codeUnitAt(index) ^ 0x30;
        if (digit <= 9) {
          value = value * 10 + digit;
          index++;
          continue;
        }
        break;
      }
      final int length = index - start;
      if (length > 0 && length <= maxLength) {
        return value;
      }
      throwError();
    }

    final int format = expectWeekday();
    int year;
    int month;
    int day;
    int hours;
    int minutes;
    int seconds;
    if (format == formatAsctime) {
      month = expectMonth();
      expectChar(_CharCode.SP);
      if (source.codeUnitAt(index) == _CharCode.SP) index++;
      day = expectNum(2);
      expectChar(_CharCode.SP);
      hours = expectNum(2);
      expectChar(_CharCode.COLON);
      minutes = expectNum(2);
      expectChar(_CharCode.COLON);
      seconds = expectNum(2);
      expectChar(_CharCode.SP);
      year = expectNum(4);
    } else {
      final dateSeparator = format;
      final alternateDateSeparator =
          isCookieDate ? _CharCode.MINUS : _CharCode.NONE;
      expectChar(_CharCode.SP);
      day = expectNum(2);
      if (!maybeExpectChar(dateSeparator)) expectChar(alternateDateSeparator);
      month = expectMonth();
      if (!maybeExpectChar(dateSeparator)) expectChar(alternateDateSeparator);
      year = expectNum(4);
      expectChar(_CharCode.SP);
      hours = expectNum(2);
      expectChar(_CharCode.COLON);
      minutes = expectNum(2);
      expectChar(_CharCode.COLON);
      seconds = expectNum(2);
      if (index + 4 <= end && _isTextNoCase(source, index, 4, ' GMT')) {
        index += 4;
      } else {
        throwError();
      }
    }
    if (index != end) throwError();
    if (isCookieDate && year < 100) {
      year += year >= 70 ? 1900 : 2000;
    }
    return DateTime.utc(year, month + 1, day, hours, minutes, seconds);
  }
}

/// Checks if `source.substring(at, at + length)` is the same as [text].
///
/// If [offset] is non-zero, only checks against `text.substring(offset)`.
/// Starts by checking that [text] has length [length] - [offset].
///
/// Ignores case of ASCII letters.
///
/// The [text] should match the casing of the expected input to make
/// checking faster.
bool _isTextNoCase(
  String source,
  int at,
  int length,
  String text, [
  int offset = 0,
]) {
  if (text.length - offset != length) return false;
  for (var i = 0; i < length; i++) {
    int testChar = text.codeUnitAt(offset + i);
    final actualChar = source.codeUnitAt(at + i);
    final delta = testChar ^ actualChar;
    if (delta == 0) continue;
    if (delta == 0x20) {
      testChar |= 0x20; // To lower case if ASCII letter.
      if (testChar >= _CharCode.LETTER_a && testChar <= _CharCode.LETTER_z) {
        continue;
      }
    }
    return false;
  }
  return true;
}
