// currentDate is the current date, it is often passed around and variables are constantly resused. So this Provider wrapping the current date should provider an more reusable solution
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
