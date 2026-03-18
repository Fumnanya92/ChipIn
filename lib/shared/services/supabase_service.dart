import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class SupabaseService {
  final SupabaseClient _supabase;

  SupabaseService(this._supabase);

  /// Upload ID document to Supabase Storage and update user profile
  Future<String> uploadIdDocument({
    required String userId,
    required File imageFile,
    required String documentType,
  }) async {
    try {
      // 1. Upload file to Supabase Storage
      final fileName = 'id_${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final fileBytes = await imageFile.readAsBytes();

      await _supabase.storage
          .from('id-documents')
          .uploadBinary(fileName, fileBytes);

      final fileUrl = _supabase.storage.from('id-documents').getPublicUrl(fileName);

      // 2. Update user profile with ID verification status
      await _supabase.from('users').update({
        'id_document_url': fileUrl,
        'id_document_type': documentType,
        'id_verification_status': 'pending', // pending, approved, rejected
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      return fileUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload selfie to Supabase Storage and update user profile
  Future<String> uploadSelfie({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // 1. Upload file to Supabase Storage
      final fileName = 'selfie_${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final fileBytes = await imageFile.readAsBytes();

      await _supabase.storage
          .from('id-documents')
          .uploadBinary(fileName, fileBytes);

      final fileUrl = _supabase.storage.from('id-documents').getPublicUrl(fileName);

      // 2. Update user profile with selfie URL
      await _supabase.from('users').update({
        'selfie_url': fileUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      return fileUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Mark user as fully ID verified and update trust score
  Future<void> markIdVerified(String userId) async {
    try {
      final userResponse = await _supabase.from('users').select('trust_score').eq('id', userId).single();
      final currentScore = userResponse['trust_score'] as int? ?? 0;
      final newScore = currentScore + 40;

      await _supabase.from('users').update({
        'id_verified': true,
        'id_verification_status': 'approved',
        'trust_score': newScore,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }
}