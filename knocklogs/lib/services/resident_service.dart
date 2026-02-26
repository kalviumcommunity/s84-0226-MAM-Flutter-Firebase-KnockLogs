import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ResidentService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current resident info
  Future<Map<String, dynamic>?> getCurrentResidentInfo() async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      DocumentSnapshot doc = await _firestore.collection("users").doc(uid).get();

      if (doc.exists) {
        return {
          "id": uid,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      throw Exception("Error fetching resident info: $e");
    }
  }

  // Generate QR code data (resident ID + timestamp)
  String generateQRData() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not authenticated");
    
    String timestamp = DateTime.now().toIso8601String();
    String qrId = const Uuid().v4();
    
    // Format: uid|qrId|timestamp
    return "$uid|$qrId|$timestamp";
  }

  // Save QR session to Firestore
  Future<String> createQRSession() async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception("User not authenticated");

      String qrId = const Uuid().v4();
      DateTime now = DateTime.now();

      await _firestore
          .collection("residents")
          .doc(uid)
          .collection("qr_sessions")
          .doc(qrId)
          .set({
            "qr_id": qrId,
            "resident_id": uid,
            "created_at": now,
            "scanned_at": null,
            "scanned_by_guard": null,
            "is_valid": true,
            "access_granted": null,
          });

      return "$uid|$qrId|${now.toIso8601String()}";
    } catch (e) {
      throw Exception("Error creating QR session: $e");
    }
  }

  // Get all check-in/out records
  Future<List<Map<String, dynamic>>> getCheckInOutRecords() async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection("residents")
          .doc(uid)
          .collection("access_logs")
          .orderBy("timestamp", descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => {
                "id": doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception("Error fetching access logs: $e");
    }
  }

  // Update resident phone number
  Future<void> updatePhone(String phone) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception("User not authenticated");

      await _firestore.collection("users").doc(uid).update({
        "phone": phone.trim(),
      });
    } catch (e) {
      throw Exception("Error updating phone: $e");
    }
  }

  // Ensure phone field exists and is not empty
  Future<void> ensurePhoneFieldExists() async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception("User not authenticated");

      DocumentSnapshot doc = await _firestore.collection("users").doc(uid).get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // If phone field is missing or empty, add a placeholder
        if (!data.containsKey("phone") || data["phone"] == null || data["phone"].toString().isEmpty) {
          await _firestore.collection("users").doc(uid).update({
            "phone": "Not provided",
          });
        }
      }
    } catch (e) {
      print("Error ensuring phone field: $e");
    }
  }

  // Log access (called when guard validates QR)
  Future<void> logAccess({
    required String qrId,
    required bool accessGranted,
    String? guardId,
    String? remarks,
  }) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception("User not authenticated");

      DateTime now = DateTime.now();

      // Update QR session
      await _firestore
          .collection("residents")
          .doc(uid)
          .collection("qr_sessions")
          .doc(qrId)
          .update({
            "scanned_at": now,
            "scanned_by_guard": guardId,
            "access_granted": accessGranted,
          });

      // Log access event
      await _firestore
          .collection("residents")
          .doc(uid)
          .collection("access_logs")
          .add({
            "qr_id": qrId,
            "timestamp": now,
            "access_granted": accessGranted,
            "scanned_by_guard": guardId,
            "remarks": remarks,
            "type": accessGranted ? "entry" : "denied",
          });

      // Update last access time in main user doc
      await _firestore.collection("users").doc(uid).update({
        "last_access": now,
        "last_access_status": accessGranted ? "success" : "denied",
      });
    } catch (e) {
      throw Exception("Error logging access: $e");
    }
  }

  // Get today's check-in/out summary
  Future<Map<String, dynamic>> getTodaysSummary() async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return {};

      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      DateTime endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      QuerySnapshot snapshot = await _firestore
          .collection("residents")
          .doc(uid)
          .collection("access_logs")
          .where("timestamp", isGreaterThanOrEqualTo: startOfDay)
          .where("timestamp", isLessThanOrEqualTo: endOfDay)
          .orderBy("timestamp")
          .get();

      List<Map<String, dynamic>> todaysLogs = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Find first successful entry and last exit
      DateTime? checkInTime;
      DateTime? checkOutTime;

      for (var log in todaysLogs) {
        if (log['access_granted'] == true && checkInTime == null) {
          checkInTime = (log['timestamp'] as Timestamp).toDate();
        }
        if (log['access_granted'] == true) {
          checkOutTime = (log['timestamp'] as Timestamp).toDate();
        }
      }

      return {
        "check_in_time": checkInTime,
        "check_out_time": checkOutTime,
        "total_entries": todaysLogs.where((l) => l['access_granted'] == true).length,
        "denied_attempts": todaysLogs.where((l) => l['access_granted'] == false).length,
      };
    } catch (e) {
      throw Exception("Error fetching today's summary: $e");
    }
  }
}
