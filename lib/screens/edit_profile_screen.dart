import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_provider.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _bioController;
  late TextEditingController _skillsController;

  String? _selectedCourse;
  String? _selectedYear;
  String? _selectedBranch;

  bool _isSaving = false;

  final Map<String, List<String>> _courseYears = {
    'BTech': ['Year 1', 'Year 2', 'Year 3', 'Year 4'],
    'BSc': ['Year 1', 'Year 2', 'Year 3'],
    'BBA': ['Year 1', 'Year 2', 'Year 3'],
    'BCA': ['Year 1', 'Year 2', 'Year 3'],
  };

  final Map<String, List<String>> _courseBranches = {
    'BTech': [
      'Computer Science',
      'IT',
      'ECE',
      'Mechanical',
      'Civil',
      'Chemical',
    ],
    'BSc': ['Physics', 'Chemistry', 'Mathematics', 'Biology'],
    'BBA': ['Finance', 'Marketing', 'HR'],
    'BCA': ['Computer Applications'],
  };

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _bioController = TextEditingController(text: user.bio);
    _skillsController = TextEditingController(text: user.skills.join(', '));

    // Initialize dropdowns if they match the predefined options
    _selectedCourse = _courseYears.containsKey(user.course)
        ? user.course
        : null;

    if (_selectedCourse != null) {
      final validYears = _courseYears[_selectedCourse]!;
      _selectedYear = validYears.contains(user.year) ? user.year : null;

      final validBranches = _courseBranches[_selectedCourse]!;
      _selectedBranch = validBranches.contains(user.branch)
          ? user.branch
          : null;
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      final skills = _skillsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final course = _selectedCourse ?? '';
      final year = _selectedYear ?? '';
      final branch = _selectedBranch ?? '';

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'bio': _bioController.text.trim(),
        'branch': branch,
        'course': course,
        'year': year,
        'skills': skills,
      });

      // Also update the local Riverpod state
      ref
          .read(userProvider.notifier)
          .updateProfile(
            bio: _bioController.text.trim(),
            branch: branch,
            course: course,
            year: year,
            skills: skills,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile updated successfully.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving profile: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.accent,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bio
              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                hint: 'Tell us about yourself...',
                maxLines: 4,
              ),
              const SizedBox(height: AppTheme.spaceMd),

              // Course & Year
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildDropdownField(
                      label: 'Course',
                      value: _selectedCourse,
                      items: _courseYears.keys.toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCourse = val;
                          _selectedYear = null;
                          _selectedBranch = null;
                        });
                      },
                      hint: 'Select Course',
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMd),
                  Expanded(
                    flex: 1,
                    child: _buildDropdownField(
                      label: 'Year',
                      value: _selectedYear,
                      items: _selectedCourse != null
                          ? _courseYears[_selectedCourse]!
                          : [],
                      onChanged: (val) {
                        setState(() {
                          _selectedYear = val;
                        });
                      },
                      hint: 'Select',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMd),

              // Branch
              _buildDropdownField(
                label: 'Branch / Major',
                value: _selectedBranch,
                items: _selectedCourse != null
                    ? _courseBranches[_selectedCourse]!
                    : [],
                onChanged: (val) {
                  setState(() {
                    _selectedBranch = val;
                  });
                },
                hint: 'Select Branch',
              ),
              const SizedBox(height: AppTheme.spaceMd),

              // Skills
              _buildTextField(
                controller: _skillsController,
                label: 'Skills',
                hint: 'Comma separated (e.g. Flutter, Firebase, Python)',
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    required String hint,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          readOnly: readOnly,
          maxLines: maxLines,
          style: TextStyle(
            color: readOnly ? Colors.white38 : Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: AppTheme.accent.withValues(alpha: 0.5),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          dropdownColor: AppTheme.navyMedium,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: items.map((item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: items.isEmpty ? null : onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: AppTheme.accent.withValues(alpha: 0.5),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
