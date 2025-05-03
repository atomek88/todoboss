import 'package:flutter/material.dart';

/// A reusable widget for selecting priority levels with header and labels
class PrioritySlider extends StatelessWidget {
  final int priority;
  final Function(double) onChanged;
  final bool showHeader;

  const PrioritySlider({
    Key? key,
    required this.priority,
    required this.onChanged,
    this.showHeader = true,
  }) : super(key: key);

  // Get the color based on priority level
  Color _getPriorityColor(int priorityLevel) {
    switch (priorityLevel) {
      case 2:
        return Colors.redAccent;
      case 1:
        return Colors.amberAccent;
      default:
        return const Color.fromARGB(255, 105, 240, 174);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Optional priority header with current value
        if (showHeader)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Priority',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                priority == 0
                    ? 'Low'
                    : priority == 1
                        ? 'Medium'
                        : 'High',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: priority == 0
                      ? const Color.fromARGB(255, 105, 240, 174)
                      : priority == 1
                          ? Colors.amberAccent.shade700
                          : Colors.redAccent,
                ),
              ),
            ],
          ),

        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 10,
            activeTrackColor: _getPriorityColor(priority),
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayColor: _getPriorityColor(priority).withOpacity(0.2),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Column(
            children: [
              Slider(
                value: priority.toDouble(),
                min: 0,
                max: 2,
                divisions: 2,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
