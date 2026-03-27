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

      DocumentSnapshot doc = await _firestore
          .collection("users")
          .doc(uid)
          .get();

      if (doc.exists) {
        return {"id": uid, ...doc.data() as Map<String, dynamic>};
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
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception("Error fetching access logs: $e");
    }
  }

  Future<void> deleteAccessLog(String logId) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception("User not authenticated");

      await _firestore
          .collection("residents")
          .doc(uid)
          .collection("access_logs")
          .doc(logId)
          .delete();
    } catch (e) {
      throw Exception("Error deleting access log: $e");
    }
  }

  Future<void> clearAccessLogs() async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception("User not authenticated");

      final snapshot = await _firestore
          .collection("residents")
          .doc(uid)
          .collection("access_logs")
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception("Error clearing access logs: $e");
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

  Future<void> updateResidentProfile(Map<String, dynamic> updates) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception("User not authenticated");

      final payload = <String, dynamic>{
        for (final entry in updates.entries)
          if (entry.value != null) entry.key: entry.value,
      };

      await _firestore.collection("users").doc(uid).update(payload);
    } catch (e) {
      throw Exception("Error updating profile: $e");
    }
  }

  // Ensure phone field exists and is not empty
  Future<void> ensurePhoneFieldExists() async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception("User not authenticated");

      DocumentSnapshot doc = await _firestore
          .collection("users")
          .doc(uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // If phone field is missing or empty, add a placeholder
        if (!data.containsKey("phone") ||
            data["phone"] == null ||
            data["phone"].toString().isEmpty) {
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
      DateTime endOfDay = DateTime(
        today.year,
        today.month,
        today.day,
        23,
        59,
        59,
      );

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
        "total_entries": todaysLogs
            .where((l) => l['access_granted'] == true)
            .length,
        "denied_attempts": todaysLogs
            .where((l) => l['access_granted'] == false)
            .length,
      };
    } catch (e) {
      throw Exception("Error fetching today's summary: $e");
    }
  }

  // Create visitor QR - for guests/temporary visitors
  Future<String> createVisitorQR({
    required String visitorName,
    required String visitorPhone,
    required String visitorEmail,
    String? visitorPurpose,
  }) async {
    try {
      String? residentId = _auth.currentUser?.uid;
      if (residentId == null) throw Exception("User not authenticated");

      // Get current resident's details
      DocumentSnapshot residentDoc = await _firestore
          .collection("users")
          .doc(residentId)
          .get();
      if (!residentDoc.exists) {
        throw Exception("Resident profile not found");
      }

      Map<String, dynamic> residentData =
          residentDoc.data() as Map<String, dynamic>;
      String residentName = residentData['name'] ?? 'Unknown';
      String residentEmail = residentData['email'] ?? '';
      String residentPhone = residentData['phone'] ?? '';
      String flatNumber = residentData['flatNo'] ?? 'Unknown';

      String visitorQrId = const Uuid().v4();
      DateTime now = DateTime.now();
      // Visitor QR expires after 8 hours
      DateTime expiresAt = now.add(const Duration(hours: 8));

      await _firestore
          .collection("residents")
          .doc(residentId)
          .collection("visitor_qr_sessions")
          .doc(visitorQrId)
          .set({
            "qr_id": visitorQrId,
            "resident_id": residentId,
            "resident_name": residentName,
            "resident_email": residentEmail,
            "resident_phone": residentPhone,
            "flat_number": flatNumber,
            "visitor_name": visitorName,
            "visitor_phone": visitorPhone,
            "visitor_email": visitorEmail,
            "visitor_purpose": visitorPurpose ?? "Visit",
            "created_at": now,
            "expires_at": expiresAt,
            "scanned_at": null,
            "scanned_by_guard": null,
            "is_valid": true,
            "access_granted": null,
            "type": "visitor",
          });

      // Format: visitor|residentId|visitorQrId|timestamp
      return "visitor|$residentId|$visitorQrId|${now.toIso8601String()}";
    } catch (e) {
      throw Exception("Error creating visitor QR: $e");
    }
  }

  // Get all active visitor QRs for this resident
  Future<List<Map<String, dynamic>>> getActiveVisitorQRs() async {
    try {
      String? residentId = _auth.currentUser?.uid;
      if (residentId == null) return [];

      DateTime now = DateTime.now();

      QuerySnapshot snapshot = await _firestore
          .collection("residents")
          .doc(residentId)
          .collection("visitor_qr_sessions")
          .where("is_valid", isEqualTo: true)
          .where("expires_at", isGreaterThan: now)
          .orderBy("expires_at", descending: false)
          .get();

      // Filter for unscanned QRs (scanned_at is null)
      return snapshot.docs
          .where(
            (doc) => (doc.data() as Map<String, dynamic>)["scanned_at"] == null,
          )
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print("Error fetching visitor QRs: $e");
      throw Exception("Error fetching visitor QRs: $e");
    }
  }

  // Get all visitor QRs (including expired and used)
  Future<List<Map<String, dynamic>>> getAllVisitorQRs() async {
    try {
      String? residentId = _auth.currentUser?.uid;
      if (residentId == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection("residents")
          .doc(residentId)
          .collection("visitor_qr_sessions")
          .orderBy("created_at", descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception("Error fetching visitor QRs: $e");
    }
  }

  // Invalidate a visitor QR
  Future<void> invalidateVisitorQR(String visitorQrId) async {
    try {
      String? residentId = _auth.currentUser?.uid;
      if (residentId == null) throw Exception("User not authenticated");

      await _firestore
          .collection("residents")
          .doc(residentId)
          .collection("visitor_qr_sessions")
          .doc(visitorQrId)
          .update({"is_valid": false});
    } catch (e) {
      throw Exception("Error invalidating visitor QR: $e");
    }
  }
}
