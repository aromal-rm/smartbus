import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimePickerField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? initialTime;

  const TimePickerField({
    super.key,
    required this.controller,
    required this.labelText,
    this.initialTime,
  });

  @override
  _TimePickerFieldState createState() => _TimePickerFieldState();
}

class _TimePickerFieldState extends State<TimePickerField> {
  @override
  void initState() {
    super.initState();
    if (widget.initialTime != null && widget.initialTime!.isNotEmpty) {
      widget.controller.text = widget.initialTime!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.access_time),
      ),
      readOnly: true,
      onTap: () async {
        final TimeOfDay? time = await showTimePicker(
          context: context,
          initialTime: widget.controller.text.isNotEmpty 
              ? _parseTimeOfDay(widget.controller.text) 
              : TimeOfDay.now(),
        );
        
        if (time != null) {
          final formattedTime = _formatTimeOfDay(time);
          setState(() {
            widget.controller.text = formattedTime;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select ${widget.labelText.toLowerCase()}';
        }
        return null;
      },
    );
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    final format = DateFormat.jm();
    final time = format.parse(timeString);
    return TimeOfDay(hour: time.hour, minute: time.minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dateTime);
  }
}
