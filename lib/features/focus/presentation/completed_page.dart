import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'package:focus_planner_new/features/tasks/data/task_repository.dart';
import '../../../core/services/level_service.dart';


class CompletedPage extends StatefulWidget {
  final String taskTitle;
  final int focusTimeMinutes;
  final String taskId;

  const CompletedPage({
    Key? key,
    required this.taskTitle,
    required this.focusTimeMinutes,
    required this.taskId,
  }) : super(key: key);

  @override
  State<CompletedPage> createState() => _CompletedPageState();
}

class _CompletedPageState extends State<CompletedPage> {
  late ConfettiController _confettiController;
  late TaskRepository _repository;
  late LevelService _levelService;
  bool _isSaving = false;
  bool _isLevelUp = false;
  int _newLevel = 1;
  int _previousLevel = 1;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _repository = TaskRepositoryImpl(userId: user.uid);
      _levelService = LevelService();
    }
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
    _confettiController.play();
    _saveCompletedTask();
  }

  Future<void> _saveCompletedTask() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final task = await _repository.getTaskById(widget.taskId);
      if (task != null) {
        // ✅ Complete task
        await _repository.completeTask(task, widget.focusTimeMinutes);

        // ✅ Update Level
        final userLevel = await _levelService.getUserLevel(user.uid);
        final currentCompletedTasks = userLevel['completedTasks'] as int;

        final result = await _levelService.updateLevelOnTaskCompletion(
          user.uid,
          currentCompletedTasks,
        );

        if (mounted) {
          setState(() {
            _isSaving = false;
            _isLevelUp = result['isLevelUp'] as bool? ?? false;
            _newLevel = result['level'] as int? ?? 1;
            _previousLevel = result['previousLevel'] as int? ?? 1;
          });

          // ✅ Show Level Up Animation if needed
          if (_isLevelUp) {
            _showLevelUpAnimation();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Level Up Animation
  void _showLevelUpAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.95),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              // ✅ Animation Icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.yellow.withOpacity(0.3),
                      ),
                      child: Center(
                        child: Text(
                          '⭐',
                          style: TextStyle(fontSize: 60),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              // ✅ Level Up Text
              const Text(
                'LEVEL UP! 🎉',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              // ✅ Level Info
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'You reached ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: 'Level $_newLevel',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Keep up the great work! 💪',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              // ✅ Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Awesome!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                : [Colors.orange.shade400, Colors.orange.shade200],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    // ✅ Checkmark Circle
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // ✅ Background Glow
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // ✅ Checkmark Circle
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 8,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '✓',
                                    style: TextStyle(
                                      fontSize: 80,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // ✅ Celebration Emoji
                        Positioned(
                          bottom: 20,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 1000),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, -30 * value),
                                child: Opacity(
                                  opacity: value,
                                  child: Text(
                                    '🎉',
                                    style: TextStyle(fontSize: 60),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // ✅ Completed Text
                    const Text(
                      'Completed!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ✅ Task Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        widget.taskTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ✅ Focus Time
                    Text(
                      'Focus Time: ${widget.focusTimeMinutes} minutes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    // ✅ Level Up Badge
                    if (_isLevelUp) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.yellow.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.yellow,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '⭐ ',
                              style: TextStyle(fontSize: 18),
                            ),
                            Text(
                              'Level $_newLevel',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellow,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 80),
                    // ✅ Back to Tasks Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  Navigator.of(context).popUntil(
                                    (route) =>
                                        route.settings.name == '/' ||
                                        route.isFirst,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).primaryColor,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isSaving ? 'Saving...' : 'Back to Tasks',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.black87
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              // ✅ Confetti
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: 3.14159,
                  maxBlastForce: 36,
                  minBlastForce: 8,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  gravity: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (index == 2) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Focus',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}