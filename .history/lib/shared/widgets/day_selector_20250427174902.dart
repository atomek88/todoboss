import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A reusable widget for selecting days of the week
class DaySelector extends ConsumerWidget {
  final Set<int> selectedDays;
  final Function(Set<int>) onDaysChanged;

  const DaySelector({
    Key? key,
    required this.selectedDays,
    required this.onDaysChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Day names in order Monday to Sunday
    final List<String> dayNames = [
      'Mon', // Index 0 maps to weekday 1 (Monday)
      'Tue', // Index 1 maps to weekday 2 (Tuesday)
      'Wed', // Index 2 maps to weekday 3 (Wednesday)
      'Thu', // Index 3 maps to weekday 4 (Thursday)
      'Fri', // Index 4 maps to weekday 5 (Friday)
      'Sat', // Index 5 maps to weekday 6 (Saturday)
      'Sun' // Index 6 maps to weekday 7 (Sunday)
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Text(
            'Select days:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: List.generate(7, (index) {
            final weekday = index + 1; // Convert to 1-based weekday
            final isSelected = selectedDays.contains(weekday);

            return FilterChip(
              label: Text(dayNames[index]),
              selected: isSelected,
              onSelected: (selected) {
                final currentDays = Set<int>.from(selectedDays);
                if (selected) {
                  currentDays.add(weekday);
                } else {
                  currentDays.remove(weekday);
                }
                onDaysChanged(currentDays);
              },
              backgroundColor: Colors.grey.shade200,
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue.shade800,
            );
          }),
        ),
      ],
    );
  }
}
