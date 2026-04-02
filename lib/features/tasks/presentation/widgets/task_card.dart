import 'package:flutter/material.dart';
import '../../data/task_model.dart';
import '../task_detail_page.dart';

class TaskCardNew extends StatelessWidget {
  const TaskCardNew({
    super.key,
    required this.task,
    this.onTaskUpdated,
  });

  final TaskModel task;
  final VoidCallback? onTaskUpdated;

  // ✅ ฟังก์ชันกำหนดสีตามหมวดหมู่
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return const Color(0xFFFFC966);  
      case 'reading':
        return const Color.fromARGB(255, 109, 143, 231);  
      case 'personal':
        return const Color.fromARGB(255, 183, 92, 235);  
      case 'health':
        return const Color.fromARGB(255, 89, 221, 111);  
      default:
        return const Color(0xFF999999);  // สีเทา default
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(task.category);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailPage(task: task),
          ),
        ).then((_) => onTaskUpdated?.call());
      },
      child: Container(
        // ✅ เพิ่มแถบสีด้านซ้าย
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: categoryColor,
              width: 5,  // ← ความหนาของแถบสี
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // ✅ Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ✅ Description
            Text(
              task.description ?? '',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // ✅ Footer row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task.dueDate != null
                          ? '${task.dueDate!.day.toString().padLeft(2, '0')}/${task.dueDate!.month.toString().padLeft(2, '0')}/${task.dueDate!.year}'
                          : 'No date',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                // ✅ Priority badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: task.priority.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.priority.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}