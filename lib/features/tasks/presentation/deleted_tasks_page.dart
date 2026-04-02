import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/deleted_task_model.dart';
import '../data/deleted_task_repository.dart';

class DeletedTasksPage extends StatefulWidget {
  const DeletedTasksPage({Key? key}) : super(key: key);

  @override
  State<DeletedTasksPage> createState() => _DeletedTasksPageState();
}

class _DeletedTasksPageState extends State<DeletedTasksPage> {
  late DeletedTaskRepository _repository;
  late Future<List<DeletedTaskModel>> _deletedTasksFuture;

  @override
  void initState() {
    super.initState();
    _initializeRepository();
  }

  void _initializeRepository() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _repository = DeletedTaskRepositoryImpl(userId: user.uid);
      _refreshDeletedTasks();
    }
  }

  void _refreshDeletedTasks() {
    setState(() {
      _deletedTasksFuture = _repository.getDeletedTasks();
    });
  }

  void _permanentlyDeleteTask(DeletedTaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete?'),
        content: Text(
          'Are you sure you want to permanently delete "${task.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _repository.deleteDeletedTask(task.id);
                _refreshDeletedTasks();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task permanently deleted'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _clearAllDeleted() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Trash?'),
        content: const Text(
          'This will permanently delete all items in trash. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _repository.clearAllDeletedTasks();
                _refreshDeletedTasks();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Trash cleared'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearAllDeleted,
            tooltip: 'Clear all trash',
          ),
        ],
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
                : [Colors.orange.shade400, Colors.orange.shade200],
          ),
        ),
        child: FutureBuilder<List<DeletedTaskModel>>(
          future: _deletedTasksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFFFFA34F),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              );
            }

            final deletedTasks = snapshot.data ?? [];

            if (deletedTasks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🗑️',
                      style: TextStyle(fontSize: 64), 
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Trash is empty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Deleted tasks will appear here',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: deletedTasks.length,
              itemBuilder: (context, index) {
                final task = deletedTasks[index];
                return _buildDeletedTaskCard(task, isDarkMode);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeletedTaskCard(DeletedTaskModel task, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.15),
        border: Border.all(
          color: isDarkMode
              ? Colors.red.withOpacity(0.3)
              : Colors.red.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _permanentlyDeleteTask(task),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.category,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              Text(
                'Deleted ${task.formattedDeletedAt}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}