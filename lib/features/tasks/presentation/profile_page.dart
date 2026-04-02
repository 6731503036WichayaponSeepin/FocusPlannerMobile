import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/task_repository.dart';
import '../data/task_model.dart';
import 'package:intl/intl.dart';
import '../../../core/services/level_service.dart';
import '../presentation/deleted_tasks_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  late TaskRepository _repository;
  late LevelService _levelService;
  late Future<Map<String, dynamic>> _stats;
  late Future<List<TaskModel>> _completedTasks;
  
  String _fullName = '';
  String _bio = '';
  String _gender = 'Not specified';
  String _dateOfBirth = 'Not set';
  String? _profilePhotoUrl;
  String? _selectedAssetImage;
  bool _isLoadingProfile = true;

  // ✅ Level Variables
  int _userLevel = 1;
  int _completedTasksCount = 0;
  int _exp = 0;

  final List<String> _catImages = [
    'assets/images/output (1).png',
    'assets/images/output (2).png',
    'assets/images/output (3).png',
    'assets/images/output (4).png',
    'assets/images/output (5).png',
    'assets/images/output (6).png',
    'assets/images/output (7).png',
    'assets/images/output (8).png',
    'assets/images/output (9).png',
    'assets/images/output (10).png',
    'assets/images/output (11).png',
    'assets/images/output (12).png',
    'assets/images/output (13).png',
    'assets/images/output (14).png',
    'assets/images/output (15).png',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _repository = TaskRepositoryImpl(userId: user.uid);
    }
    _levelService = LevelService();
    _loadProfileData();
    _loadStats();
    _loadCompletedTasks();
    _loadUserLevel();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (mounted) {
          if (doc.exists) {
            setState(() {
              _fullName = doc['fullName'] ?? user.displayName ?? '';
              _bio = doc['bio'] ?? '';
              _gender = doc['gender'] ?? 'Not specified';
              _dateOfBirth = doc['dateOfBirth'] ?? 'Not set';
              _selectedAssetImage = doc['selectedAssetImage'];
              _profilePhotoUrl = doc['profilePhotoUrl'] ?? user.photoURL;
              _isLoadingProfile = false;
            });
          } else {
            setState(() {
              _fullName = user.displayName ?? '';
              _profilePhotoUrl = user.photoURL;
              _isLoadingProfile = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  // ✅ Load User Level
  Future<void> _loadUserLevel() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final levelData = await _levelService.getUserLevel(user.uid);
        setState(() {
          _userLevel = levelData['level'];
          _completedTasksCount = levelData['completedTasks'];
          _exp = levelData['exp'];
        });
      }
    } catch (e) {
      debugPrint('Error loading user level: $e');
    }
  }

  Future<void> _selectCatImage(String imagePath) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'selectedAssetImage': imagePath,
          'profilePhotoUrl': null,
        }, SetOptions(merge: true));

        setState(() {
          _selectedAssetImage = imagePath;
          _profilePhotoUrl = null;
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showCatImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B4B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose Cat Avatar",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                itemCount: _catImages.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final image = _catImages[index];
                  final selected = _selectedAssetImage == image;

                  return GestureDetector(
                    onTap: () => _selectCatImage(image),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? Colors.orange
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(image),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10)
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _fullName);
    final bioController = TextEditingController(text: _bio);

    String selectedGender = _gender;
    String selectedDate = _dateOfBirth;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Full Name
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// Bio
                    TextField(
                      controller: bioController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// Gender
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['Male', 'Female', 'Other', 'Not specified']
                          .map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedGender = value ?? 'Not specified';
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    /// Date of Birth
                    GestureDetector(
                      onTap: () async {
                        DateTime initialDate = DateTime.now();

                        try {
                          if (selectedDate != 'Not set') {
                            initialDate = DateTime.parse(selectedDate);
                          }
                        } catch (_) {}

                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initialDate,
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );

                        if (picked != null) {
                          setStateDialog(() {
                            selectedDate =
                                DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date of Birth',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedDate,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _saveProfileData(
                      nameController.text,
                      bioController.text,
                      selectedGender,
                      selectedDate,
                    );

                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveProfileData(
    String name,
    String bio,
    String gender,
    String dateOfBirth,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'fullName': name,
          'bio': bio,
          'gender': gender,
          'dateOfBirth': dateOfBirth,
          'profilePhotoUrl': _profilePhotoUrl,
          'selectedAssetImage': _selectedAssetImage,
        }, SetOptions(merge: true));

        setState(() {
          _fullName = name;
          _bio = bio;
          _gender = gender;
          _dateOfBirth = dateOfBirth;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    _loadProfileData();
    _loadStats();
    _loadCompletedTasks();
    _loadUserLevel();
  }

  Future<void> _loadStats() async {
    setState(() {
      _stats = Future.wait([
        _repository.getTotalTasksCount(),
        _repository.getCompletedTasksCount(),
        _repository.getPendingTasksCount(),
        _repository.getTotalFocusTimeSpent(),
      ]).then((results) {
        return {
          'total': results[0],
          'completed': results[1],
          'pending': results[2],
          'focusTime': results[3],
        };
      });
    });
  }

  void _loadCompletedTasks() {
    setState(() {
      _completedTasks = _repository.getCompletedTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final currentUser = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Container(
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
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  _buildAvatarSection(),
                  const SizedBox(height: 20),
                  // ✅ Level Card
                  _buildLevelCard(isDarkMode),
                  const SizedBox(height: 20),
                  _buildProfileCard(currentUser),
                  const SizedBox(height: 20),
                  // ✅ Trash Button
                  _buildTrashButton(isDarkMode),
                  const SizedBox(height: 20),
                  _buildStatsSection(isDarkMode),
                  const SizedBox(height: 20),
                  _buildCompletedTasksSection(isDarkMode),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Trash Button (ปรับสีเหมือน Profile Card)
  Widget _buildTrashButton(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DeletedTasksPage(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),  // ✅ เปลี่ยน
            border: Border.all(
              color: Colors.white.withOpacity(0.2),  // ✅ เปลี่ยน
            ),
            borderRadius: BorderRadius.circular(16),  // ✅ เปลี่ยน
          ),
          child: Row(
            children: [
              // ✅ Icon Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),  // ✅ เปลี่ยน
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trash',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View deleted tasks',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Level Card Widget
  Widget _buildLevelCard(bool isDarkMode) {
    final levelProgress = _levelService.getLevelProgress(_completedTasksCount);
    final progressPercentage = levelProgress['progressPercentage'] as double;
    final tasksUntilNextLevel = levelProgress['tasksUntilNextLevel'] as int;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.3),
            Theme.of(context).primaryColor.withOpacity(0.1),
          ],
        ),
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // ✅ Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_userLevel',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
                child: Icon(
                  Icons.star_rounded,
                  size: 36,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress to Level ${_userLevel + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    '$_exp/5',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressPercentage / 100,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ✅ Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Complete $tasksUntilNextLevel more task${tasksUntilNextLevel > 1 ? 's' : ''} to reach Level ${_userLevel + 1}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Avatar Section
  Widget _buildAvatarSection() {
    return Stack(
      children: [
        CustomPaint(
          size: const Size(double.infinity, 220),
          painter: WaveHeaderPainter(
            isDarkMode: Theme.of(context).brightness == Brightness.dark,
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: Column(
              children: [

                const SizedBox(height: 20),

                /// Avatar
                Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _selectedAssetImage != null
                              ? Image.asset(
                                  _selectedAssetImage!,
                                  key: ValueKey(_selectedAssetImage),
                                  fit: BoxFit.cover,
                                )
                              : (_profilePhotoUrl != null
                                  ? Image.network(
                                      _profilePhotoUrl!,
                                      key: ValueKey(_profilePhotoUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : _buildDefaultAvatar()),
                        ),
                      ),
                    ),

                    /// ปุ่มแก้รูป
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showCatImagePicker,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// ชื่อ
                Text(
                  _fullName.isNotEmpty ? _fullName : "User",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                /// Bio
                if (_bio.isNotEmpty)
                  Text(
                    _bio,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),

                if (_bio.isEmpty)
                  Text(
                    "Add your bio",
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),

                const SizedBox(height: 12),

                /// ปุ่ม Edit Profile
                GestureDetector(
                  onTap: _showEditProfileDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ✅ Profile Card
  Widget _buildProfileCard(User? user) {
    final email = user?.email ?? "User";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          _buildProfileItem(
            icon: Icons.email,
            title: "Email",
            value: email,
          ),
          const Divider(color: Colors.white30),
          _buildProfileItem(
            icon: Icons.person,
            title: "Gender",
            value: _gender,
          ),
          const Divider(color: Colors.white30),
          _buildProfileItem(
            icon: Icons.cake,
            title: "Date of Birth",
            value: _dateOfBirth,
          ),
        ],
      ),
    );
  }

  // ✅ Profile Item
  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Text(
          _fullName.isNotEmpty ? _fullName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ✅ Stats Section
  Widget _buildStatsSection(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color.fromARGB(255, 41, 28, 114).withOpacity(0.6)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _stats,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFA34F),
                    ),
                  );
                }
                final stats = snapshot.data!;
                return Row(
                  children: [
                    Text(
                      '🏆',
                      style: TextStyle(fontSize: 40),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Focus Completed',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${stats['completed']}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color.fromARGB(255, 41, 28, 114).withOpacity(0.6)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _stats,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFA34F),
                    ),
                  );
                }
                final stats = snapshot.data!;
                final focusHours = (stats['focusTime'] as int) ~/ 60;
                final focusMins = (stats['focusTime'] as int) % 60;
                return Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black54,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Focus Sessions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          '${stats['completed']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.access_time,
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black54,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Total Focus Time',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          '$focusHours hrs $focusMins mins',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Completed Tasks Section
  Widget _buildCompletedTasksSection(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color.fromARGB(255, 41, 28, 114).withOpacity(0.6)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Completed Tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '✓',
                  style: TextStyle(fontSize: 20, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<TaskModel>>(
              future: _completedTasks,
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
                  return Text(
                    'Error loading tasks: ${snapshot.error}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text(
                    'No completed tasks yet',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.6)
                          : Colors.grey,
                      fontSize: 14,
                    ),
                  );
                }
                final tasks = snapshot.data!;
                return Column(
                  children: List.generate(
                    tasks.length,
                    (index) {
                      final task = tasks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCompletedTaskItem(task, isDarkMode),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedTaskItem(TaskModel task, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.green.withOpacity(0.15)
            : Colors.green.shade50,
        border: Border.all(
          color: isDarkMode
              ? Colors.green.withOpacity(0.3)
              : Colors.green.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 28),
              Text(
                'Focus: ${task.focusTimeSpent ?? 0} mins',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.6)
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WaveHeaderPainter extends CustomPainter {
  final bool isDarkMode;

  WaveHeaderPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 60);
    path.quadraticBezierTo(size.width * 0.25, 40, size.width * 0.5, 60);
    path.quadraticBezierTo(size.width * 0.75, 80, size.width, 60);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);

    final circlePaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.75, 55), 6, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.82, 70), 4, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.88, 50), 3, circlePaint);
  }

  @override
  bool shouldRepaint(WaveHeaderPainter oldDelegate) => false;
}