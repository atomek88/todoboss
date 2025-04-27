import 'package:flutter/material.dart';

/// A reusable widget for selecting priority levels
class PrioritySlider extends StatelessWidget {
  final int priority;
  final Function(double) onChanged;

  const PrioritySlider({
    Key? key,
    required this.priority,
    required this.onChanged,
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
              // Labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Low',
                      style: TextStyle(
                        fontWeight: priority == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: priority == 0
                            ? const Color.fromARGB(255, 105, 240, 174)
                            : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Medium',
                      style: TextStyle(
                        fontWeight: priority == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: priority == 1
                            ? Colors.amberAccent.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'High',
                      style: TextStyle(
                        fontWeight: priority == 2
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: priority == 2
                            ? Colors.redAccent
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
