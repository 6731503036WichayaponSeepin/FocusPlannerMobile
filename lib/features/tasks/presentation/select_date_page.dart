import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class SelectDatePage extends StatefulWidget {
  final DateTime? initialDate;

  const SelectDatePage({
    Key? key,
    this.initialDate,
  }) : super(key: key);

  @override
  State<SelectDatePage> createState() => _SelectDatePageState();
}

class _SelectDatePageState extends State<SelectDatePage> {
  late DateTime _selectedDate;
  late DateTime _focusedDate;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _focusedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Date'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Container(
        // ✅ เปลี่ยน gradient เป็นสีเข้มเหมือน login
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? const [
                    Color.fromARGB(255, 3, 1, 59),
                    Color.fromARGB(255, 41, 28, 114),
                  ]
                : [Colors.purple.shade800, Colors.purple.shade600],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // ✅ Calendar Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      // ✅ เปลี่ยนสี card ตามธีม
                      color: isDarkMode
                          ? const Color.fromARGB(255, 41, 28, 114)
                              .withOpacity(0.6)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2024, 1, 1),
                      lastDay: DateTime.utc(2026, 12, 31),
                      focusedDay: _focusedDate,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDate, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDate = selectedDay;
                          _focusedDate = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDate = focusedDay;
                      },
                      calendarFormat: _calendarFormat,
                      // ✅ Styling
                      headerStyle: HeaderStyle(
                        formatButtonDecoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        formatButtonTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.white
                              : Colors.purple.shade800,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: isDarkMode
                              ? Colors.white
                              : Colors.purple.shade800,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: isDarkMode
                              ? Colors.white
                              : Colors.purple.shade800,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        // ✅ Selected Day
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        selectedTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        // ✅ Today
                        todayDecoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.shade400,
                            width: 2,
                          ),
                        ),
                        todayTextStyle: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                        // ✅ Default Days
                        defaultDecoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        defaultTextStyle: TextStyle(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade800,
                        ),
                        // ✅ Outside Days
                        outsideTextStyle: TextStyle(
                          color: isDarkMode
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                        // ✅ Disabled Days
                        disabledTextStyle: TextStyle(
                          color: isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        // ✅ Weekend
                        weekendTextStyle: TextStyle(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade800,
                        ),
                        // ✅ Holidays/Events
                        holidayDecoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.shade50,
                        ),
                        holidayTextStyle: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.8)
                              : Colors.purple.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        weekendStyle: TextStyle(
                          color: isDarkMode
                              ? Colors.orange.shade300
                              : Colors.orange.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      // ✅ Row Height
                      rowHeight: 50,
                      // ✅ Disable Animations
                      enabledDayPredicate: (day) {
                        return true;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // ✅ Selected Date Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color.fromARGB(255, 41, 28, 114)
                              .withOpacity(0.6)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Selected Date',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy')
                              .format(_selectedDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getDayDescription(_selectedDate),
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.black87
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // ✅ Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? Colors.white.withOpacity(0.12)
                                : Colors.white.withOpacity(0.15),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, _selectedDate);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Select',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.black87
                                  : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDayDescription(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == today) {
      return 'Today';
    } else if (selectedDay == tomorrow) {
      return 'Tomorrow';
    } else if (selectedDay.isBefore(today)) {
      return 'Past';
    } else {
      final daysAhead = selectedDay.difference(today).inDays;
      if (daysAhead < 7) {
        return 'In $daysAhead days';
      } else {
        return DateFormat('MMM d').format(date);
      }
    }
  }
}