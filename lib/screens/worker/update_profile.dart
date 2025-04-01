import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // User data
  String? workerId;
  String? authToken;
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  
  // Skills list - make this dynamic based on your actual skills data
  final List<String> _availableSkills = [
    'Plumbing', 'Electrical', 'Carpentry', 'Painting', 
    'Cleaning', 'Gardening', 'Moving', 'Repair', 'Installation'
  ];
  final List<String> _selectedSkills = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      workerId = prefs.getString('user_id');
      authToken = prefs.getString('auth_token');
      
      // For demo purposes, pre-fill with sample data
      // In a real app, you would fetch this from your API
      _nameController.text = prefs.getString('username') ?? 'John Doe';
      _phoneController.text = '+1 234 567 8900';
      _emailController.text = 'worker@example.com';
      _aboutController.text = 'Professional with 5+ years of experience in home services.';
      _locationController.text = 'New York, NY';
      _specializationController.text = 'Home Maintenance';
      
      // Sample selected skills
      _selectedSkills.addAll(['Plumbing', 'Repair', 'Installation']);
      
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API request delay
      await Future.delayed(const Duration(seconds: 2));

      // Here you would normally send the data to your API
      // For demo purposes, we'll just save some basic info to SharedPreferences
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', _nameController.text);
        
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Pop back to home screen after success
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context, true); // Return true to indicate successful update
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 20, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.yellow[700],
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool multiline = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLines: multiline ? 4 : 1,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.yellow[700]),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.yellow[700]!.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.yellow[700]!),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
        ),
        validator: validator ?? (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.yellow[700],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellow[700]!.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                          height: 120,
                          width: 120,
                        ),
                      )
                    : Center(
                        child: Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : 'W',
                          style: const TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.yellow[700]!, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.yellow[700],
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: Text(
              'Change Profile Picture',
              style: TextStyle(
                color: Colors.yellow[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.yellow[700]!.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Skills',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSkills.map((skill) {
              final isSelected = _selectedSkills.contains(skill);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSkills.remove(skill);
                    } else {
                      _selectedSkills.add(skill);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.yellow[700]
                        : Colors.yellow[700]!.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.yellow[700]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.yellow[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedSkills.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Please select at least one skill',
                style: TextStyle(color: Colors.red[300], fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        elevation: 0,
        title: const Text(
          'Update Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.yellow[700]),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildProfileImageSection(),
                      const SizedBox(height: 30),
                      
                      _buildSectionTitle('Personal Information'),
                      _buildTextField(
                        label: 'Full Name',
                        controller: _nameController,
                        icon: Icons.person,
                      ),
                      _buildTextField(
                        label: 'Phone Number',
                        controller: _phoneController,
                        icon: Icons.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          // Add phone validation logic if needed
                          return null;
                        },
                      ),
                      _buildTextField(
                        label: 'Email',
                        controller: _emailController,
                        icon: Icons.email,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        label: 'Location',
                        controller: _locationController,
                        icon: Icons.location_on,
                      ),
                      
                      _buildSectionTitle('Professional Information'),
                      _buildTextField(
                        label: 'Specialization',
                        controller: _specializationController,
                        icon: Icons.work,
                      ),
                      _buildTextField(
                        label: 'About Me',
                        controller: _aboutController,
                        icon: Icons.description,
                        multiline: true,
                      ),
                      
                      const SizedBox(height: 10),
                      _buildSectionTitle('Skills'),
                      const SizedBox(height: 8),
                      _buildSkillsSelector(),
                      
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selectedSkills.isEmpty ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[700],
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: Colors.grey,
                            disabledForegroundColor: Colors.black54,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            'SAVE CHANGES',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _aboutController.dispose();
    _locationController.dispose();
    _specializationController.dispose();
    super.dispose();
  }
}