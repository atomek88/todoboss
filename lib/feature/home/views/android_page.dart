import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class AndroidSpecificPage extends ConsumerStatefulWidget {
  const AndroidSpecificPage({super.key});

  @override
  ConsumerState<AndroidSpecificPage> createState() => _AndroidSpecificPageState();
}

class _AndroidSpecificPageState extends ConsumerState<AndroidSpecificPage> {
  final DateTime _initialDate = DateTime.now();
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
    Colors.blue,
    Colors.green,
    Colors.indigo,
    Colors.orange,
    Colors.pink,
    Colors.purple,
    Colors.red,
    Colors.teal,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Android Features'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showBottomSheet(context);
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Material Design equivalent of large title header
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Android Features'),
              background: Container(color: Theme.of(context).primaryColor.withOpacity(0.1)),
            ),
          ),

          // Content starts here
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Material Design segmented control equivalent
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
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(
                        value: 0,
                        label: Text('Daily'),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        label: Text('Weekly'),
                      ),
                      ButtonSegment<int>(
                        value: 2,
                        label: Text('Monthly'),
                      ),
                    ],
                    selected: {_selectedSegment},
                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() {
                        _selectedSegment = newSelection.first;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Material Design date picker
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
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${_initialDate.day}/${_initialDate.month}/${_initialDate.year}',
                                style: const TextStyle(fontSize: 18),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.calendar_today),
                                label: const Text('Change'),
                                onPressed: () {
                                  _selectDate(context);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CalendarDatePicker(
                            initialDate: _initialDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            onDateChanged: (DateTime newDate) {},
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Material Design text field
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
                  TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Enter a note for this date',
                      prefixIcon: const Icon(Icons.edit),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _textController.clear();
                        },
                      ),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Material Design slider
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
                        Icons.alarm,
                        color: Colors.grey,
                      ),
                      Expanded(
                        child: Slider(
                          value: _sliderValue,
                          onChanged: (value) {
                            setState(() {
                              _sliderValue = value;
                            });
                          },
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          label: '${(_sliderValue * 12).round()}:00',
                        ),
                      ),
                      Text(
                        '${(_sliderValue * 12).round()}:00',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Material Design switch
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
                        Switch(
                          value: _switchValue,
                          onChanged: (bool value) {
                            setState(() {
                              _switchValue = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Material Design list with context menu
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Today\'s Schedule',
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

          // Material Design list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _segmentColors[
                          index % _segmentColors.length],
                      radius: 6,
                    ),
                    title: Text(_events[index]),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Show details
                    },
                    onLongPress: () {
                      _showContextMenu(context, _events[index]);
                    },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new event
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      // Update date
    }
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add Event'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Calendar'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Clear All Events', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, String event) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Event Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, event);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String event) {
    final TextEditingController controller = TextEditingController(text: event);

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Edit Event'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Update the event here
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}