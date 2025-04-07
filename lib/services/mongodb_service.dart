import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

class MongoDBService {
  // Change this to your backend server URL
  static const String baseUrl = 'http://localhost:3001';
  final Db _db;
  final String _gridFSBucket = 'profile_images';
  late GridFS _gridFS;

  MongoDBService(this._db) {
    _gridFS = GridFS(_db, _gridFSBucket);
  }

  static Future<MongoDBService> initialize() async {
    try {
      final db = await Db.create(
        'mongodb+srv://pendyalashivasai19:YR2VbNOfTgdblimQ@cluster0.m8rdqqe.mongodb.net/skillswap?retryWrites=true&w=majority'
      );
      await db.open();
      print('MongoDB connected successfully');
      return MongoDBService(db);
    } catch (e) {
      print('MongoDB connection error: $e');
      rethrow;
    }
  }

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      final fileId = ObjectId();
      final fileName = 'profile_$userId${path.extension(imageFile.path)}';

      // Upload to GridFS
      final gridFile = _gridFS.createFile(
        imageFile.openRead(),
        fileName,
        {
          '_id': fileId,
          'contentType': 'image/${path.extension(fileName).substring(1)}',
          'userId': userId,
          'uploadDate': DateTime.now(),
        },
      );
      await gridFile.save();

      // Return proper URL format
      final imageUrl = '$baseUrl/images/${fileId.toHexString()}';
      print('MongoDBService: Generated image URL - $imageUrl');
      return imageUrl;
    } catch (e) {
      print('MongoDBService: Error uploading image - $e');
      rethrow;
    }
  }

  Future<File> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) throw Exception('Could not decode image');

    // Resize if too large
    var resized = image;
    if (image.width > 1024 || image.height > 1024) {
      resized = img.copyResize(
        image,
        width: image.width > image.height ? 1024 : null,
        height: image.height >= image.width ? 1024 : null,
      );
    }

    // Compress
    final compressed = img.encodeJpg(resized, quality: 85);
    final tempPath = file.path.replaceAll(
      path.extension(file.path),
      '_compressed${path.extension(file.path)}'
    );
    final compressedFile = File(tempPath);
    await compressedFile.writeAsBytes(compressed);
    return compressedFile;
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      final result = await _db.collection('users').update(
        where.eq('_id', userId),
        {'\$set': updates},
      );
      
      if (result['nModified'] == 0) {
        throw Exception('User not found or not modified');
      }
      print('MongoDBService: User updated successfully');
    } catch (e) {
      print('MongoDBService: Error updating user - $e');
      rethrow;
    }
  }

  Future<List<int>> getProfileImage(String fileId) async {
    try {
      final file = await _gridFS.files.findOne(
        where.eq('_id', ObjectId.parse(fileId))
      );
      
      if (file == null) {
        throw Exception('Image not found');
      }

      final chunks = await _gridFS.chunks.find(
        where.eq('files_id', ObjectId.parse(fileId))
      ).toList();

      // Sort chunks by n (sequence number)
      chunks.sort((a, b) => (a['n'] as int).compareTo(b['n'] as int));

      // Combine all chunks into a single byte array
      final bytes = <int>[];
      for (var chunk in chunks) {
        bytes.addAll(chunk['data'] as List<int>);
      }

      return bytes;
    } catch (e) {
      print('MongoDBService: Error getting image - $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final user = await _db.collection('users').findOne(where.eq('_id', userId));
      
      if (user != null && user['profileImageUrl'] != null) {
        // Extract file ID from MongoDB URL
        final fileId = user['profileImageUrl'].toString().split('/images/').last;
        // Construct proper URL with file ID
        user['profileImageUrl'] = '$baseUrl/images/$fileId';
        print('MongoDBService: Constructed profileImageUrl - ${user['profileImageUrl']}');
      }
      return user;
    } catch (e) {
      print('MongoDBService: Error getting user - $e');
      rethrow;
    }
  }
}