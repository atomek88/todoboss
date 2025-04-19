import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

@RoutePage()
class IOSSpecificPage extends ConsumerStatefulWidget {
  const IOSSpecificPage({super.key});

  @override
  ConsumerState<IOSSpecificPage> createState() => _IOSSpecificPageState();
}

class _IOSSpecificPageState extends ConsumerState<IOSSpecificPage> {
  final DateTime _initialDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  final List<String> _events = [
    'Morning Coffee',
    'Team Meeting',
    'Lunch with Client',
    'Project Review',
    'Gym Session',
    'Dinner with Family',
    'Reading Time',
    'Meditation'
  ];

  final List<Color> _segmentColors = [
    CupertinoColors.systemBlue,
    CupertinoColors.systemGreen,
    CupertinoColors.systemIndigo,
    CupertinoColors.systemOrange,
    CupertinoColors.systemPink,
    CupertinoColors.systemPurple,
    CupertinoColors.systemRed,
    CupertinoColors.systemTeal,
  ];

  int _selectedSegment = 0;
  double _sliderValue = 0.5;
  bool _switchValue = true;
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('iOS Features'),
        // This creates the iOS-style large title effect when scrolling
        transitionBetweenRoutes: false,
      ),
      child: SafeArea(
        child: CustomScrollView(
          // Use of Slivers for iOS-style scrolling behavior
          slivers: [
            // iOS-style large title header
            CupertinoSliverNavigationBar(
              largeTitle: const Text('iOS Features'),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.info_circle),
                onPressed: () {
                  _showActionSheet(context);
                },
              ),
            ),

            // Content starts here
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // iOS-style segmented control
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'View Mode',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    CupertinoSlidingSegmentedControl<int>(
                      backgroundColor: CupertinoColors.systemGrey5,
                      thumbColor: CupertinoColors.white,
                      groupValue: _selectedSegment,
                      onValueChanged: (int? value) {
                        if (value != null) {
                          setState(() {
                            _selectedSegment = value;
                          });
                        }
                      },
                      children: const {
                        0: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text('Daily'),
                        ),
                        1: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text('Weekly'),
                        ),
                        2: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text('Monthly'),
                        ),
                      },
                    ),

                    const SizedBox(height: 24),

                    // iOS-style date picker
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Select Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: CupertinoColors.systemGrey5,
                          width: 1,
                        ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: _initialDate,
                        onDateTimeChanged: (DateTime newDate) {
                          setState(() {
                            _selectedDate = newDate;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // iOS-style text field
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Add Note',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    CupertinoTextField(
                      controller: _textController,
                      placeholder: 'Enter a note for this date',
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: CupertinoColors.systemGrey5,
                          width: 1,
                        ),
                      ),
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 12.0),
                        child: Icon(
                          CupertinoIcons.pencil,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      suffix: CupertinoButton(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: const Icon(
                          CupertinoIcons.clear_circled,
                          color: CupertinoColors.systemGrey,
                        ),
                        onPressed: () {
                          _textController.clear();
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // iOS-style slider
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Reminder Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.alarm,
                          color: CupertinoColors.systemGrey,
                        ),
                        Expanded(
                          child: CupertinoSlider(
                            value: _sliderValue,
                            onChanged: (value) {
                              setState(() {
                                _sliderValue = value;
                              });
                            },
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                          ),
                        ),
                        Text(
                          '${(_sliderValue * 12).round()}:00',
                          style: const TextStyle(
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // iOS-style switch
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Enable Notifications',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          CupertinoSwitch(
                            value: _switchValue,
                            onChanged: (bool value) {
                              setState(() {
                                _switchValue = value;
                              });
                            },
                            activeColor: CupertinoColors.activeBlue,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // iOS-style context menu
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Today\'s Schedule (Long press for options)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // iOS-style list with context menu
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return CupertinoContextMenu(
                    actions: [
                      CupertinoContextMenuAction(
                        child: const Text('Edit'),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditDialog(context, _events[index]);
                        },
                      ),
                      CupertinoContextMenuAction(
                        isDestructiveAction: true,
                        child: const Text('Delete'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: CupertinoColors.systemGrey5,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _segmentColors[
                                    index % _segmentColors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _events[index],
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.right_chevron,
                              color: CupertinoColors.systemGrey,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: _events.length,
              ),
            ),

            // Add some space at the bottom
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Options'),
        message: const Text('Choose an action'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Add Event'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Share Calendar'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Clear All Events'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String event) {
    final TextEditingController controller = TextEditingController(text: event);

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Edit Event'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CupertinoColors.systemGrey5,
                width: 1,
              ),
            ),
          ),
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              // Update the event here
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
