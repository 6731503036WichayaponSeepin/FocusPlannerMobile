import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'select_date_page.dart';
import '../data/task_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({Key? key}) : super(key: key);

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final titleCtl = TextEditingController();
  final descriptionCtl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  String _selectedCategory = 'Work';
  Priority _selectedPriority = Priority.none;
  bool _autoPriority = true;
  late int _focusTime;
  List<ReminderModel> _reminders = [];

  final categories = ['Work', 'Reading', 'Personal', 'Health'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFocusTimeFromSettings();
  }

  Future<void> _loadFocusTimeFromSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _focusTime = prefs.getInt('focusTime') ?? 25;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _focusTime = 25;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    titleCtl.dispose();
    descriptionCtl.dispose();
    super.dispose();
  }

  String? _validateTitle(String? v) {
    if (v == null || v.trim().isEmpty) return 'กรุณากรอกชื่องาน';
    if (v.length < 3) return 'ชื่องานต้องมีอย่างน้อย 3 ตัวอักษร';
    return null;
  }

  void _calculateAutoPriority() {
    if (!_autoPriority || _selectedDate == null) {
      _selectedPriority = Priority.none;
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );

    final daysUntilDue = dueDate.difference(today).inDays;

    setState(() {
      if (daysUntilDue <= 3 && daysUntilDue >= 0) {
        _selectedPriority = Priority.high;
      } else if (daysUntilDue >= 4 && daysUntilDue <= 6) {
        _selectedPriority = Priority.medium;
      } else if (daysUntilDue > 6) {
        _selectedPriority = Priority.low;
      } else if (daysUntilDue < 0) {
        _selectedPriority = Priority.high;
      }
    });
  }

  Future<void> _selectDate() async {
    final result = await Navigator.push<DateTime>(
      context,
      MaterialPageRoute(
        builder: (context) => SelectDatePage(
          initialDate: _selectedDate,
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedDate = result);
      _calculateAutoPriority();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Due Date';
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  String _getDaysUntil() {
    if (_selectedDate == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );
    final daysUntilDue = dueDate.difference(today).inDays;

    if (daysUntilDue == 0) return '(Today)';
    if (daysUntilDue == 1) return '(Tomorrow)';
    if (daysUntilDue > 1) return '(In $daysUntilDue days)';
    if (daysUntilDue < 0) return '(${-daysUntilDue} days overdue!)';
    return '';
  }

  void _showFocusTimeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Focus Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current: $_focusTime minutes',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              child: Column(
                children: [15, 20, 25, 30, 45, 60]
                    .map(
                      (minutes) => ListTile(
                        title: Text('$minutes minutes'),
                        selected: _focusTime == minutes,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _focusTime = minutes);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ เพิ่ม reminder
  Future<void> _addReminder() async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (result != null) {
      setState(() {
        _reminders.add(
          ReminderModel(
            id: const Uuid().v4(),
            time: result,
            isEnabled: true,
          ),
        );
      });
    }
  }

  // ✅ ลบ reminder
  void _removeReminder(String id) {
    setState(() {
      _reminders.removeWhere((r) => r.id == id);
    });
  }

  // ✅ ดึงเวลาจาก reminder ทั้งหมด
  List<DateTime> _getReminderDateTimes() {
    if (_selectedDate == null) return [];

    return _reminders.map((reminder) {
      return DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        reminder.time.hour,
        reminder.time.minute,
      );
    }).toList();
  }

  void _createTask() {
    if (!formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();

    final task = TaskModel(
      id: const Uuid().v4(),
      title: titleCtl.text.trim(),
      description: descriptionCtl.text.trim(),
      category: _selectedCategory,
      dueDate: _selectedDate,
      priority: _selectedPriority,
      isCompleted: false,
      reminders: _reminders,
      // ✅ เพิ่ม reminder times
      reminderTimes: _getReminderDateTimes(),

      userId: user.uid,
      createdAt: now,
      updatedAt: now,
    );

    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        body: Container(
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
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFFFFA34F),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Task'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Container(
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Title Input
                Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task Title',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: titleCtl,
                        validator: _validateTitle,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.white,
                        ),
                        decoration: _inputDecoration(
                          'Enter task title',
                          isDarkMode: isDarkMode,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ Description Input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descriptionCtl,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.white,
                      ),
                      maxLines: 4,
                      decoration: _inputDecoration(
                        'Enter task description',
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ✅ Category Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => _selectedCategory = category);
                              },
                              backgroundColor: Colors.white.withOpacity(0.1),
                              selectedColor: _getCategoryColor(category)
                                  .withOpacity(0.3),
                              side: BorderSide(
                                color: isSelected
                                    ? _getCategoryColor(category)
                                    : Colors.white.withOpacity(0.2),
                              ),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? _getCategoryColor(category)
                                    : Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ✅ Due Date Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due Date',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.08)
                              : Colors.white.withOpacity(0.08),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white.withOpacity(0.8),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(_selectedDate),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_selectedDate != null)
                                    Text(
                                      _getDaysUntil(),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ✅ Auto Priority Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.08),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto Priority',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Set priority based on due date',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _autoPriority,
                        onChanged: (value) {
                          setState(() => _autoPriority = value);
                          if (value) {
                            _calculateAutoPriority();
                          }
                        },
                        activeColor: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ Priority Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Priority',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (_autoPriority && _selectedDate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedPriority.color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _selectedPriority.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AbsorbPointer(
                      absorbing: _autoPriority,
                      child: Opacity(
                        opacity: _autoPriority ? 0.6 : 1.0,
                        child: Wrap(
                          spacing: 8,
                          children: [
                            Priority.low,
                            Priority.medium,
                            Priority.high,
                          ]
                              .map((priority) {
                                final isSelected =
                                    _selectedPriority == priority;
                                return FilterChip(
                                  label: Text(priority.label),
                                  selected: isSelected,
                                  onSelected: _autoPriority
                                      ? null
                                      : (_) {
                                          setState(
                                            () =>
                                                _selectedPriority = priority,
                                          );
                                        },
                                  backgroundColor:
                                      Colors.white.withOpacity(0.1),
                                  selectedColor:
                                      priority.color.withOpacity(0.3),
                                  side: BorderSide(
                                    color: isSelected
                                        ? priority.color
                                        : Colors.white.withOpacity(0.2),
                                  ),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? priority.color
                                        : Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ✅ Focus Time Setting
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.08),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Focus Time',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_focusTime minutes (from settings)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ REMINDERS SECTION
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reminders',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (_reminders.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_reminders.length} reminder${_reminders.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // ✅ กรอบหลัก - คลิกทั้งกรอบเพิ่มเวลา
                    if (_reminders.isEmpty)
                      GestureDetector(
                        onTap: _addReminder,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.08)
                                : Colors.white.withOpacity(0.08),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '+ Set a reminder',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          // ✅ List reminders ที่มีอยู่
                          ..._reminders.asMap().entries.map((entry) {
                            final index = entry.key;
                            final reminder = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.white.withOpacity(0.08),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.notifications_active,
                                        color:
                                            Theme.of(context).primaryColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Reminder ${index + 1}',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            reminder.time.format(context),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        _removeReminder(reminder.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),

                          // ✅ Reminder baru - คลิกทั้งกรอบเพิ่มเวลาใหม่
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _addReminder,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  style: BorderStyle.solid,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    color:
                                        Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add Reminder',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // ✅ Action Buttons
                Row(
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
                        onPressed: _createTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Create Task',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint, {
    required bool isDarkMode,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.5),
      ),
      filled: true,
      fillColor: isDarkMode
          ? Colors.white.withOpacity(0.08)
          : Colors.white.withOpacity(0.08),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.white,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return const Color(0xFFFFC966);
      case 'reading':
        return const Color(0xFFADBDE6);
      case 'personal':
        return const Color(0xFF92C4B7);
      case 'health':
        return const Color(0xFFE8A8A8);
      default:
        return const Color(0xFF999999);
    }
  }
}