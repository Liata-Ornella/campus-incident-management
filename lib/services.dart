import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<UserCredential> registerStudent({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;

    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': fullName.trim(),
        'email': email.trim(),
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await credential.user!.delete();
      rethrow;
    }

    return credential;
  }

  static Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snapshot = await _db.collection('users').doc(uid).get();
    return snapshot.data();
  }

  static Future<void> logout() => _auth.signOut();
}

class IncidentService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _cloudName = 'cdcshvd9';
  static const String _uploadPreset = 'campuscare_incidents';
  static const String _folder = 'campuscare/incidents';

  static const List<String> categories = [
    'Safety',
    'Security',
    'Health',
    'Infrastructure',
    'Harassment',
    'Other',
  ];

  static const List<String> statuses = [
    'submitted',
    'under review',
    'in progress',
    'resolved',
  ];

  static Future<String> uploadImage(String imagePath) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = _folder;

    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('Image upload failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final imageUrl = data['secure_url'];

    if (imageUrl is! String || imageUrl.isEmpty) {
      throw Exception('Cloudinary did not return an image URL.');
    }

    return imageUrl;
  }

  static Future<void> createIncident({
    required String title,
    required String description,
    required String category,
    required String reporterName,
    String? imageUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please log in before submitting a report.');
    }

    if (!categories.contains(category)) {
      throw Exception('Invalid incident category.');
    }

    final document = _db.collection('incidents').doc();

    await document.set({
      'id': document.id,
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'status': 'submitted',
      'reportedBy': user.uid,
      'reporterName': reporterName.trim(),
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> myIncidents() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('You must be logged in.');
    }

    return _db
        .collection('incidents')
        .where('reportedBy', isEqualTo: user.uid)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> allIncidents() {
    return _db.collection('incidents').snapshots();
  }

  static Future<void> updateStatus({
    required String incidentId,
    required String status,
  }) async {
    if (!statuses.contains(status)) {
      throw Exception('Invalid incident status.');
    }

    await _db.collection('incidents').doc(incidentId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
