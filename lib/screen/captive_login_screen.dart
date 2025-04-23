import 'dart:convert';
import 'package:captive_logger_android/screen/profiles_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:captive_logger_android/types/profile.dart';

class CaptiveLoginScreen extends StatefulWidget {
  const CaptiveLoginScreen({super.key});

  @override
  State<CaptiveLoginScreen> createState() => _CaptiveLoginScreenState();
}

class _CaptiveLoginScreenState extends State<CaptiveLoginScreen> with SingleTickerProviderStateMixin {
  bool isLoading = false;
  bool isLoggedIn = false;
  Profile? currentProfile;
  List<Profile> profiles = [];
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _checkLoginStatus();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Create curved animation
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Start animation
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Check if user is already logged in
  Future<void> _checkLoginStatus() async {
    try {
      const url = "http://172.16.16.16:8090/live";
      final response = await http.get(Uri.parse(url));
      
      // If we can access this endpoint, user is logged in
      if (response.statusCode == 200) {
        setState(() {
          isLoggedIn = true;
        });
      }
    } catch (e) {
      // Error means not logged in or no connectivity
      setState(() {
        isLoggedIn = false;
      });
    }
  }

  Future<void> _loadProfiles() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final profilesJson = prefs.getString('profiles') ?? '[]';
    final lastUsedProfileName = prefs.getString('lastUsedProfile');

    List<dynamic> profilesList = jsonDecode(profilesJson);
    profiles = profilesList.map((e) => Profile.fromJson(e)).toList();

    if (lastUsedProfileName != null && profiles.isNotEmpty) {
      currentProfile = profiles.firstWhere(
        (profile) => profile.name == lastUsedProfileName,
        orElse: () => profiles.first,
      );
    } else if (profiles.isNotEmpty) {
      currentProfile = profiles.first;
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveLastUsedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (currentProfile != null) {
      await prefs.setString('lastUsedProfile', currentProfile!.name);
    }
  }

  Future<void> _toggleConnection() async {
    if (isLoggedIn) {
      await _logout();
    } else {
      await _login();
    }
  }

  Future<void> _login() async {
    if (currentProfile == null) {
      _showSnackBar('No profile selected');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      const url = "http://172.16.16.16:8090/httpclient.html";
      final response = await http.post(
        Uri.parse(url),
        body: {
          "mode": "191",
          "username": currentProfile!.id,
          "password": currentProfile!.password,
          "a": DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          isLoggedIn = true;
        });
        _showSnackBar('Login successful');
      } else {
        _showSnackBar('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    if (currentProfile == null) {
      _showSnackBar('No profile selected for logout');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      const url = "http://172.16.16.16:8090/httpclient.html";
      final response = await http.post(
        Uri.parse(url),
        body: {
          "mode": "193",
          "username": currentProfile!.id,
          "a": DateTime.now().millisecondsSinceEpoch.toString(),
          "producttype": "",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          isLoggedIn = false;
        });
        _showSnackBar('Logout successful');
      } else {
        _showSnackBar('Logout failed: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error during logout: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showProfileSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Select Profile', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: profiles.isEmpty
                ? const Text('No profiles available', style: TextStyle(color: Colors.white70))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      final profile = profiles[index];
                      return _buildNeumorphicContainerSmall(
                        ListTile(
                          title: Text(profile.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(profile.id, style: const TextStyle(color: Colors.white70)),
                          onTap: () {
                            setState(() {
                              currentProfile = profile;
                            });
                            _saveLastUsedProfile();
                            Navigator.pop(context);
                          },
                          trailing: currentProfile?.name == profile.name
                              ? const Icon(Icons.check_circle, color: Colors.purple)
                              : null,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              child: const Text('Manage Profiles', style: TextStyle(color: Colors.purple)),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilesScreen()),
                ).then((_) => _loadProfiles());
              },
            ),
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNeumorphicContainer(Widget child, {EdgeInsets? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF13131F),
            offset: Offset(5, 5),
            blurRadius: 12,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Color(0xFF292945),
            offset: Offset(-5, -5),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildNeumorphicContainerSmall(Widget child, {EdgeInsets? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF13131F),
            offset: Offset(3, 3),
            blurRadius: 6,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color(0xFF292945),
            offset: Offset(-3, -3),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
        title: const Text(
          'WiFi Captive Login',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : FadeTransition(
              opacity: _animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(_animation),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        // Connection Status Card
                        _buildNeumorphicContainer(
                          Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isLoggedIn ? Colors.purple.withOpacity(0.2) : Colors.red.withOpacity(0.1),
                                ),
                                child: Icon(
                                  isLoggedIn ? Icons.wifi : Icons.wifi_off,
                                  size: 40,
                                  color: isLoggedIn ? Colors.purple : Colors.red,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isLoggedIn ? 'Connected' : 'Disconnected',
                                style: TextStyle(
                                  color: isLoggedIn ? Colors.purple : Colors.red,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (currentProfile != null && isLoggedIn)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Logged in as ${currentProfile!.name}',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Current Profile Selector
                        _buildNeumorphicContainer(
                          InkWell(
                            onTap: _showProfileSelectionDialog,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF292945),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.purple,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Current Profile',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            currentProfile?.name ?? 'No Profile Selected',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (currentProfile != null)
                                            Text(
                                              currentProfile!.id,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.purple,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Login/Logout Button
                        _buildNeumorphicContainer(
                          GestureDetector(
                            onTap: currentProfile == null ? null : _toggleConnection,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: currentProfile == null
                                      ? [Colors.grey.shade800, Colors.grey.shade900]
                                      : isLoggedIn
                                          ? [Colors.red.shade700, Colors.red.shade900]
                                          : [Colors.purple.shade700, Colors.purple.shade900],
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isLoggedIn ? Icons.logout : Icons.login,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isLoggedIn ? 'Logout' : 'Login',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: 30),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}