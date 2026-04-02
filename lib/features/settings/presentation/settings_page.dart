import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_planner_new/features/auth/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SharedPreferences _prefs;
  int _focusTimeMinutes = 25;
  int _breakTimeMinutes = 5;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      setState(() {
        _focusTimeMinutes = _prefs.getInt('focusTime') ?? 25;
        _breakTimeMinutes = _prefs.getInt('breakTime') ?? 5;
        _notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;
        _soundEnabled = _prefs.getBool('sound') ?? true;
        _vibrationEnabled = _prefs.getBool('vibration') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _saveFocusTime(int minutes) async {
    final oldValue = _focusTimeMinutes;
    try {
      await _prefs.setInt('focusTime', minutes);
      setState(() => _focusTimeMinutes = minutes);
      
      await NotificationService().notifySettingChanged(
        settingName: 'Focus Time',
        oldValue: '$oldValue minutes',
        newValue: '$minutes minutes',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Focus time updated to $minutes minutes'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  Future<void> _saveBreakTime(int minutes) async {
    final oldValue = _breakTimeMinutes;
    try {
      await _prefs.setInt('breakTime', minutes);
      setState(() => _breakTimeMinutes = minutes);
      
      await NotificationService().notifySettingChanged(
        settingName: 'Break Time',
        oldValue: '$oldValue minutes',
        newValue: '$minutes minutes',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Break time updated to $minutes minutes'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  // ✅ Save Notifications
  Future<void> _saveNotifications(bool enabled) async {
    try {
      await _prefs.setBool('notificationsEnabled', enabled);
      if (mounted) {
        setState(() => _notificationsEnabled = enabled);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  Future<void> _saveSound(bool enabled) async {
    try {
      await _prefs.setBool('sound', enabled);
      if (mounted) {
        setState(() => _soundEnabled = enabled);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  Future<void> _saveVibration(bool enabled) async {
    try {
      await _prefs.setBool('vibration', enabled);
      if (mounted) {
        setState(() => _vibrationEnabled = enabled);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
        (route) => false,
      );
    }
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
              'Current: $_focusTimeMinutes minutes',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              child: Column(
                children: [5, 10, 15, 20, 25, 30, 45, 60]
                  .map(
                    (minutes) => ListTile(
                      title: Text('$minutes minutes'),
                      selected: _focusTimeMinutes == minutes,
                      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.3),
                      onTap: () {
                        Navigator.pop(context);
                        _saveFocusTime(minutes);
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

  void _showBreakTimeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Break Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current: $_breakTimeMinutes minutes',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              child: Column(
                children: [1, 3, 5, 10, 15, 20]
                  .map(
                    (minutes) => ListTile(
                      title: Text('$minutes minutes'),
                      selected: _breakTimeMinutes == minutes,
                      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.3),
                      onTap: () {
                        Navigator.pop(context);
                        _saveBreakTime(minutes);
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

  // ✅ Show Notifications Dialog
  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Notifications'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Enable Notifications
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  subtitle: const Text('Receive notifications and reminders'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setStateDialog(() {
                      _notificationsEnabled = value;
                      _saveNotifications(value);
                    });
                  },
                ),
                const Divider(),
                
                // ✅ Sound
                SwitchListTile(
                  title: const Text('Sound'),
                  subtitle: const Text('Play sound on notification'),
                  value: _soundEnabled,
                  onChanged: _notificationsEnabled
                      ? (value) {
                          setStateDialog(() {
                            _soundEnabled = value;
                            _saveSound(value);
                          });
                        }
                      : null,
                ),
                
                // ✅ Vibration
                SwitchListTile(
                  title: const Text('Vibration'),
                  subtitle: const Text('Vibrate on notification'),
                  value: _vibrationEnabled,
                  onChanged: _notificationsEnabled
                      ? (value) {
                          setStateDialog(() {
                            _vibrationEnabled = value;
                            _saveVibration(value);
                          });
                        }
                      : null,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Focus Planner'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Focus Planner',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'A productivity app to help you focus and manage your tasks effectively using the Pomodoro technique.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                '© 2024 Focus Planner. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection(
                '📝 Creating Tasks',
                '1. Go to Home tab\n2. Click the + button\n3. Fill in task details\n4. Select due date\n5. Set priority level',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                '⏱️ Focus Timer',
                '1. Go to Focus tab\n2. Select urgent task\n3. Click "Start Focus"\n4. Timer will count down\n5. Task auto-saves',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                '📊 Profile & Stats',
                '• View completed tasks\n• Track focus time\n• Check your level\n• Monitor progress',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                '⚙️ Settings',
                '• Customize focus time\n• Adjust break duration\n• Toggle notifications\n• Enable vibration',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
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
                  : [Colors.orange.shade400, Colors.orange.shade200],
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
        title: const Text('Settings'),
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
                : [Colors.orange.shade400, Colors.orange.shade200],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // ✅ Display Section
              _buildSectionHeader('Display & Theme', isDarkMode),
              const SizedBox(height: 12),

              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return _buildSettingCard(
                    icon: themeProvider.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    title: 'Theme',
                    subtitle: themeProvider.isDarkMode
                        ? 'Dark Mode'
                        : 'Light Mode',
                    onTap: () {
                      themeProvider.toggleTheme();
                    },
                    isDarkMode: isDarkMode,
                  );
                },
              ),
              const SizedBox(height: 24),

              // ✅ Timer Settings Section
              _buildSectionHeader('Timer Settings', isDarkMode),
              const SizedBox(height: 12),

              _buildSettingCard(
                icon: Icons.timer,
                title: 'Focus Time',
                subtitle: '$_focusTimeMinutes minutes per session',
                onTap: _showFocusTimeDialog,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),

              _buildSettingCard(
                icon: Icons.lunch_dining,
                title: 'Break Time',
                subtitle: '$_breakTimeMinutes minutes per break',
                onTap: _showBreakTimeDialog,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 24),

              // ✅ Notification Settings Section
              _buildSectionHeader('Notifications', isDarkMode),
              const SizedBox(height: 12),

              _buildSettingCard(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                subtitle: _notificationsEnabled
                    ? 'Enabled'
                    : 'Disabled',
                onTap: _showNotificationsDialog,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 24),

              // ✅ About & Help Section
              _buildSectionHeader('About & Help', isDarkMode),
              const SizedBox(height: 12),

              _buildSettingCard(
                icon: Icons.help_rounded,
                title: 'Help & Support',
                subtitle: 'Learn how to use the app',
                onTap: _showHelpDialog,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),

              _buildSettingCard(
                icon: Icons.info_rounded,
                title: 'About Focus Planner',
                subtitle: 'Version 1.0.0',
                onTap: _showAboutDialog,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 32),

              // ✅ Logout Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.2),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.white,
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}