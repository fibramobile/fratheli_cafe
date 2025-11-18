import 'package:intl/intl.dart';

final _brlFormatter =
NumberFormat.simpleCurrency(locale: 'pt_BR', decimalDigits: 2);

String brl(double value) => _brlFormatter.format(value);
