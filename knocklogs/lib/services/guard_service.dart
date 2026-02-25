import 'package:cloud_firestore/cloud_firestore.dart';

class GuardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Validate QR and get resident info
  Future<Map<String, dynamic>?> validateQRAndGetResidentInfo(String qrData) async {
    try {
      // QR format: uid|qrId|timestamp
      List<String> parts = qrData.split("|");
      if (parts.length < 3) return null;

      String residentId = parts[0];
      String qrId = parts[1];

      // Get resident info
      DocumentSnapshot residentDoc = await _firestore.collection("users").doc(residentId).get();

      if (!residentDoc.exists) {
        return null; // Resident not found
      }

      Map<String, dynamic> residentData = residentDoc.data() as Map<String, dynamic>;

      // Check if resident is approved
      if (residentData['status'] != 'approved') {
        return {
          "valid": false,
          "reason": "Resident not approved",
          "resident_id": residentId,
        };
      }

      // Check QR session validity
      DocumentSnapshot qrDoc = await _firestore
          .collection("residents")
          .doc(residentId)
          .collection("qr_sessions")
          .doc(qrId)
          .get();

      bool qrValid = false;
      if (qrDoc.exists) {
        Map<String, dynamic> qrData = qrDoc.data() as Map<String, dynamic>;
        qrValid = qrData['is_valid'] == true && qrData['scanned_at'] == null;
      }

      if (!qrValid) {
        return {
          "valid": false,
          "reason": "Invalid or already used QR code",
          "resident_id": residentId,
          "resident_name": residentData['name'] ?? "Unknown",
        };
      }

      // QR is valid - determine entry type
      String entryType = await _determineEntryType(residentId);

      // QR is valid - return resident info
      return {
        "valid": true,
        "resident_id": residentId,
        "resident_name": residentData['name'] ?? "Unknown",
        "resident_email": residentData['email'] ?? "Unknown",
        "resident_phone": residentData['phone'] ?? "Unknown",
        "flat_number": residentData['flat_number'] ?? "Unknown",
        "qr_id": qrId,
        "qr_created_at": parts[2],
        "entry_type": entryType,
      };
    } catch (e) {
      return {
        "valid": false,
        "reason": "Error validating QR: $e",
      };
    }
  }

  // Determine if resident is entering (IN) or exiting (OUT)
  Future<String> _determineEntryType(String residentId) async {
    try {
      // Get last access log
      QuerySnapshot lastLog = await _firestore
          .collection("residents")
          .doc(residentId)
          .collection("access_logs")
          .orderBy("timestamp", descending: true)
          .limit(1)
          .get();

      if (lastLog.docs.isEmpty) {
        return "IN"; // First entry today
      }

      String lastType = lastLog.docs.first['type'] ?? "OUT";
      // If last was IN, next should be OUT. If last was OUT, next should be IN
      return lastType == "IN" ? "OUT" : "IN";
    } catch (e) {
      return "IN"; // Default to IN if error
    }
  }

  // Grant access - update resident access log
  Future<void> grantAccess({
    required String residentId,
    required String qrId,
    required String guardId,
  }) async {
    try {
      DateTime now = DateTime.now();
      String entryType = await _determineEntryType(residentId);

      // Update QR session
      await _firestore
          .collection("residents")
          .doc(residentId)
          .collection("qr_sessions")
          .doc(qrId)
          .update({
            "scanned_at": now,
            "scanned_by_guard": guardId,
            "access_granted": true,
            "entry_type": entryType,
          });

      // Log access event
      await _firestore
          .collection("residents")
          .doc(residentId)
          .collection("access_logs")
          .add({
            "qr_id": qrId,
            "timestamp": now,
            "access_granted": true,
            "scanned_by_guard": guardId,
            "type": entryType,
          });

      // Update guard's scan log
      await _firestore
          .collection("guards")
          .doc(guardId)
          .collection("scan_logs")
          .add({
            "resident_id": residentId,
            "qr_id": qrId,
            "timestamp": now,
            "access_granted": true,
            "entry_type": entryType,
            "resident_name": await _getResidentName(residentId),
          });

      // Update user's last access
      await _firestore.collection("users").doc(residentId).update({
        "last_access": now,
        "last_access_status": "success",
        "current_status": entryType,
      });
    } catch (e) {
      throw Exception("Error granting access: $e");
    }
  }

  // Deny access
  Future<void> denyAccess({
    required String residentId,
    required String qrId,
    required String guardId,
    required String reason,
  }) async {
    try {
      DateTime now = DateTime.now();

      // Update QR session
      await _firestore
          .collection("residents")
          .doc(residentId)
          .collection("qr_sessions")
          .doc(qrId)
          .update({
            "scanned_at": now,
            "scanned_by_guard": guardId,
            "access_granted": false,
          });

      // Log access event
      await _firestore
          .collection("residents")
          .doc(residentId)
          .collection("access_logs")
          .add({
            "qr_id": qrId,
            "timestamp": now,
            "access_granted": false,
            "scanned_by_guard": guardId,
            "reason": reason,
            "type": "denied",
          });

      // Update guard's scan log
      await _firestore
          .collection("guards")
          .doc(guardId)
          .collection("scan_logs")
          .add({
            "resident_id": residentId,
            "qr_id": qrId,
            "timestamp": now,
            "access_granted": false,
            "reason": reason,
            "entry_type": "denied",
            "resident_name": await _getResidentName(residentId),
          });

      // Update user's last access
      await _firestore.collection("users").doc(residentId).update({
        "last_access": now,
        "last_access_status": "denied",
        "denial_reason": reason,
      });
    } catch (e) {
      throw Exception("Error denying access: $e");
    }
  }

  // Helper to get resident name
  Future<String> _getResidentName(String residentId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection("users").doc(residentId).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['name'] ?? "Unknown";
      }
      return "Unknown";
    } catch (e) {
      return "Unknown";
    }
  }

  // Get guard's scan history
  Future<List<Map<String, dynamic>>> getGuardScanHistory(String guardId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection("guards")
          .doc(guardId)
          .collection("scan_logs")
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
      throw Exception("Error fetching scan history: $e");
    }
  }
}
