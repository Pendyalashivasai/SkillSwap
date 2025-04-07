// import 'dart:io';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class StorageService {
//   final SupabaseClient _supabase;

//   StorageService(this._supabase);

//   Future<String> uploadProfileImage(String userId, File imageFile) async {
//     try {
//       final fileExt = imageFile.path.split('.').last;
//       final fileName = '$userId.$fileExt';
      
//       final response = await _supabase
//           .storage
//           .from('profile_images')
//           .upload(fileName, imageFile);

//       return _supabase
//           .storage
//           .from('profile_images')
//           .getPublicUrl(fileName);
//     } catch (e) {
//       print('StorageService: Error uploading image - $e');
//       rethrow;
//     }
//   }
// }