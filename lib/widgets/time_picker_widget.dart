import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class TimePickerWidget extends StatefulWidget {
  final Function(String) onTimeSelected;
  final String? initialTime;

  const TimePickerWidget({
    super.key,
    required this.onTimeSelected,
    this.initialTime,
  });

  @override
  State<TimePickerWidget> createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  late int _selectedHour;
  late int _selectedMinute;
  
  final FixedExtentScrollController _hourController = FixedExtentScrollController();
  final FixedExtentScrollController _minuteController = FixedExtentScrollController();
  
  @override
  void initState() {
    super.initState();
    
    // Parse initial time if provided
    if (widget.initialTime != null && widget.initialTime!.isNotEmpty) {
      final parts = widget.initialTime!.split(':');
      _selectedHour = int.tryParse(parts[0]) ?? DateTime.now().hour;
      _selectedMinute = int.tryParse(parts[1]) ?? 0;
    } else {
      // Default to current time
      final now = DateTime.now();
      _selectedHour = now.hour;
      _selectedMinute = now.minute;
    }
    
    // Initialize scroll controllers with the selected values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hourController.jumpToItem(_selectedHour);
      _minuteController.jumpToItem(_selectedMinute);
    });
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _updateSelectedTime() {
    final formattedHour = _selectedHour.toString().padLeft(2, '0');
    final formattedMinute = _selectedMinute.toString().padLeft(2, '0');
    widget.onTimeSelected("$formattedHour:$formattedMinute");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              'Saati Seçin',
              style: theme.textTheme.headlineSmall,
            ),
          ),
          SizedBox(
            height: 200,
            width: 150,
            child: Row(
              children: [
                // Hours wheel
                Expanded(
                  child: _buildScrollableTimeWheel(
                    controller: _hourController,
                    itemCount: 24,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedHour = index;
                        _updateSelectedTime();
                      });
                    },
                    formatValue: (index) => index.toString().padLeft(2, '0'),
                  ),
                ),
                
                // Divider
                Text(
                  ':',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                
                // Minutes wheel
                Expanded(
                  child: _buildScrollableTimeWheel(
                    controller: _minuteController,
                    itemCount: 60,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedMinute = index;
                        _updateSelectedTime();
                      });
                    },
                    formatValue: (index) => index.toString().padLeft(2, '0'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: const Color(0xFF1A2D50),
            ),
            child: const Text(
              'Tamam',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableTimeWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required Function(int) onSelectedItemChanged,
    required String Function(int) formatValue,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The scroll wheel
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 50,
            perspective: 0.006,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onSelectedItemChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: itemCount,
              builder: (context, index) {
                return Center(
                  child: Text(
                    formatValue(index),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: controller.selectedItem == index 
                          ? Theme.of(context).secondaryHeaderColor 
                          : Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Selection highlight
          IgnorePointer(
            child: Center(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).primaryColor.withValues(alpha: .3),
                      width: 1,
                    ),
                    bottom: BorderSide(
                      color: Theme.of(context).primaryColor.withValues(alpha: .3),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> showCustomTimePicker(
  BuildContext context, {
  String? initialTime,
}) async {
  String? selectedTime;
  
  await showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 50),
        child: TimePickerWidget(
          initialTime: initialTime,
          onTimeSelected: (time) {
            selectedTime = time;
          },
        ),
      );
    },
  );
  
  return selectedTime;
}