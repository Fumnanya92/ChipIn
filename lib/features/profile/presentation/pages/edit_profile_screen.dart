import 'dart:io';
import 'package:chipin/core/theme/app_theme.dart';
import 'package:chipin/features/auth/presentation/providers/auth_provider.dart';
import 'package:chipin/features/profile/presentation/providers/profile_provider.dart';
import 'package:chipin/shared/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _locationCtrl;
  bool _saving = false;
  File? _pendingAvatar;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _locationCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider('me')).value;
      if (profile != null) {
        _nameCtrl.text = profile.fullName ?? '';
        _bioCtrl.text = profile.bio ?? '';
        _locationCtrl.text = profile.location ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      setState(() => _pendingAvatar = File(file.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      String? newAvatarUrl;

      // Upload new avatar if the user picked one
      if (_pendingAvatar != null) {
        final userId = ref.read(currentUserIdProvider);
        if (userId != null) {
          final supabase = ref.read(supabaseClientProvider);
          final bytes = await _pendingAvatar!.readAsBytes();
          final ext = _pendingAvatar!.path.split('.').last.toLowerCase();
          final storagePath = '$userId/avatar.$ext';
          await supabase.storage.from('avatars').uploadBinary(
                storagePath,
                bytes,
                fileOptions: FileOptions(
                  upsert: true,
                  contentType: 'image/$ext',
                ),
              );
          newAvatarUrl =
              supabase.storage.from('avatars').getPublicUrl(storagePath);
        }
      }

      await ref.read(profileNotifierProvider.notifier).updateProfile(
            fullName: _nameCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
            location: _locationCtrl.text.trim(),
            avatarUrl: newAvatarUrl,
          );
      // Refresh both the auth state and the profile cache so changes show immediately.
      ref.invalidate(userProfileProvider('me'));
      await ref.read(authNotifierProvider.notifier).build();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save changes. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider('me'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => _buildForm(profile),
      ),
    );
  }

  Widget _buildForm(UserModel? profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar — tap to change
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: _pendingAvatar != null
                          ? FileImage(_pendingAvatar!) as ImageProvider
                          : (profile?.avatarUrl != null
                              ? NetworkImage(profile!.avatarUrl!)
                              : null),
                      child: (_pendingAvatar == null &&
                              profile?.avatarUrl == null)
                          ? Text(
                              (profile?.displayName.isNotEmpty == true)
                                  ? profile!.displayName[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            _FieldLabel('Display Name'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              decoration: _inputDecor('Your full name'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),

            _FieldLabel('Bio'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _bioCtrl,
              decoration: _inputDecor('A short bio about yourself'),
              maxLines: 3,
              maxLength: 160,
            ),
            const SizedBox(height: 20),

            _FieldLabel('Location'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _locationCtrl,
              decoration: _inputDecor('City, Country (optional)'),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  static InputDecoration _inputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
