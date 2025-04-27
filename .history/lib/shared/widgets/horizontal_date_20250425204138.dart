import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class HorizontalDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime)? onDateChanged;
  final int visibleItemCount;

  const HorizontalDatePicker({
    Key? key,
    required this.initialDate,
    this.onDateChanged,
    this.visibleItemCount = 5,
  }) : super(key: key);

  @override
  _HorizontalDatePickerState createState() => _HorizontalDatePickerState();
}

class _HorizontalDatePickerState extends State<HorizontalDatePicker> {
  late DateTime _currentDate;
  final ScrollController _scrollController = ScrollController();
  final double _itemExtent = 100.0;
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
    _generateDates();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToInitialDate());
  }

  void _generateDates() {
    _dates = List.generate(
        365, (index) => DateTime.now().add(Duration(days: index - 180)));
  }

  void _jumpToInitialDate() {
    int centerIndex =
        _dates.indexWhere((date) => _isSameDay(date, _currentDate));
    _scrollController
        .jumpTo((centerIndex - (widget.visibleItemCount ~/ 2)) * _itemExtent);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _onScrollEnd() {
    int index = (_scrollController.offset / _itemExtent).round();
    DateTime selectedDate = _dates[index];
    setState(() => _currentDate = selectedDate);
    if (widget.onDateChanged != null) widget.onDateChanged!(selectedDate);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF39060), Color(0xFF8C67C8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollEndNotification>(
              onNotification: (notification) {
                _onScrollEnd();
                return true;
              },
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemExtent: _itemExtent,
                itemCount: _dates.length,
                itemBuilder: (context, index) {
                  final date = _dates[index];
                  final isSelected = _isSameDay(date, _currentDate);

                  return Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: isSelected ? 20 : 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: Colors.white.withOpacity(isSelected ? 1.0 : 0.5),
                      ),
                      child: Text(DateFormat('MMM d').format(date)),
                    ),
                  );
                },
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
                15,
                (_) => Container(
                      height: 6,
                      width: 1.5,
                      color: Colors.white.withOpacity(0.4),
                    )),
          ),
        ],
      ),
    );
  }
}
