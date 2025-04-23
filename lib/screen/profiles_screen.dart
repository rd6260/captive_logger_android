import 'dart:convert';
import 'package:captive_logger_android/types/profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  List<Profile> profiles = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final profilesJson = prefs.getString('profiles') ?? '[]';

    List<dynamic> profilesList = jsonDecode(profilesJson);
    profiles = profilesList.map((e) => Profile.fromJson(e)).toList();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = jsonEncode(profiles.map((e) => e.toJson()).toList());
    await prefs.setString('profiles', profilesJson);
  }

  void _addProfile() {
    _showProfileDialog();
  }

  void _editProfile(int index) {
    _showProfileDialog(profile: profiles[index], index: index);
  }

  void _deleteProfile(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: const Text('Delete Profile', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to delete ${profiles[index].name}?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                setState(() {
                  profiles.removeAt(index);
                });
                _saveProfiles();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showProfileDialog({Profile? profile, int? index}) {
    final nameController = TextEditingController(text: profile?.name ?? '');
    final idController = TextEditingController(text: profile?.id ?? '');
    final passwordController = TextEditingController(text: profile?.password ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: Text(
            profile == null ? 'Add Profile' : 'Edit Profile',
            style: const TextStyle(color: Colors.white),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Profile Name',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a profile name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: idController,
                    decoration: const InputDecoration(
                      labelText: 'Username/ID',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(
                profile == null ? 'Add' : 'Save',
                style: const TextStyle(color: Colors.purple),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newProfile = Profile(
                    name: nameController.text,
                    id: idController.text,
                    password: passwordController.text,
                  );

                  setState(() {
                    if (index != null) {
                      profiles[index] = newProfile;
                    } else {
                      profiles.add(newProfile);
                    }
                  });

                  _saveProfiles();
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildNeumorphicContainer(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF13131F),
            offset: Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Color(0xFF292945),
            offset: Offset(-4, -4),
            blurRadius: 8,
            spreadRadius: 1,
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
          'Manage Profiles',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : profiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_off,
                        size: 64,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No profiles available',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _addProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF292945),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Add New Profile',
                          style: TextStyle(color: Colors.purple),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    return _buildNeumorphicContainer(
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          profile.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Username: ${profile.id}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Password: ${'•' * profile.password.length}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.purple),
                              onPressed: () => _editProfile(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProfile(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: profiles.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _addProfile,
              backgroundColor: Colors.purple,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}