import 'package:intl/intl.dart';

/// Formats [amount] as Vietnamese dong, e.g. `formatVnd(1250000)` →
/// `1.250.000 ₫`.
String formatVnd(num amount) =>
    NumberFormat.currency(locale: 'vi_VN', decimalDigits: 0, symbol: '₫')
        .format(amount)
        // intl's vi_VN currency pattern uses a non-breaking space (U+00A0)
        // before the symbol; normalise it to a regular space.
        .replaceAll('\u00A0', ' ');

/// Formats [date] as `dd/MM/yyyy`, e.g. `07/10/2026`.
String formatDateVi(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

/// Formats [date] as `dd/MM/yyyy HH:mm`, e.g. `07/10/2026 14:30`.
String formatDateTimeVi(DateTime date) =>
    DateFormat('dd/MM/yyyy HH:mm').format(date);
