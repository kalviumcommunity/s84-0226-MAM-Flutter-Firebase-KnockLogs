import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> getApprovedResidentsCount() async {
    try {
      final snapshot = await _firestore
          .collection("users")
          .where("role", isEqualTo: "resident")
          .where("status", isEqualTo: "approved")
          .get();
      return snapshot.size;
    } catch (e) {
      throw Exception("Error counting residents: $e");
    }
  }

  Future<int> getApprovedGuardsCount() async {
    try {
      final snapshot = await _firestore
          .collection("users")
          .where("role", isEqualTo: "guard")
          .where("status", isEqualTo: "approved")
          .get();
      return snapshot.size;
    } catch (e) {
      throw Exception("Error counting guards: $e");
    }
  }

  Future<int> getPendingRequestsCount() async {
    try {
      final snapshot = await _firestore
          .collection("users")
          .where("status", isEqualTo: "pending")
          .get();
      return snapshot.size;
    } catch (e) {
      throw Exception("Error counting pending requests: $e");
    }
  }

  Future<int> getVisitorsTodayCount() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collectionGroup("access_logs")
          .where("timestamp", isGreaterThanOrEqualTo: startOfDay)
          .where("timestamp", isLessThan: endOfDay)
          .where("access_granted", isEqualTo: true)
          .where("type", isEqualTo: "visitor_entry")
          .get();

      return snapshot.size;
    } catch (e) {
      throw Exception("Error counting visitors today: $e");
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection("users").doc(uid).get();
      if (!doc.exists) return null;
      return <String, dynamic>{
        "id": doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
    } catch (e) {
      throw Exception("Error fetching user profile: $e");
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection("users").doc(uid).update(data);
    } catch (e) {
      throw Exception("Error updating user profile: $e");
    }
  }

  Future<List<int>> getVisitorEntriesLast7Days() async {
    try {
      final now = DateTime.now();
      final start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6));
      final end = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 1));

      final snapshot = await _firestore
          .collectionGroup("access_logs")
          .where("timestamp", isGreaterThanOrEqualTo: start)
          .where("timestamp", isLessThan: end)
          .where("access_granted", isEqualTo: true)
          .where("type", isEqualTo: "visitor_entry")
          .get();

      final counts = List<int>.filled(7, 0);
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final ts = data["timestamp"];
        if (ts is! Timestamp) continue;

        final dayStart = DateTime(
          ts.toDate().year,
          ts.toDate().month,
          ts.toDate().day,
        );
        final index = dayStart.difference(start).inDays;
        if (index >= 0 && index < 7) counts[index] += 1;
      }

      return counts;
    } catch (e) {
      throw Exception("Error fetching visitor analytics: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> getRecentActivityStream({int limit = 10}) {
    return _firestore
        .collectionGroup("scan_logs")
        .orderBy("timestamp", descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{"id": doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection("users")
          .where("status", isEqualTo: "pending")
          .get();

      return snapshot.docs
          .map(
            (doc) => <String, dynamic>{
              "id": doc.id,
              ...doc.data() as Map<String, dynamic>,
            },
          )
          .toList();
    } catch (e) {
      throw Exception("Error fetching pending requests: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getAllGuards() async {
    try {
      // Get all guards first, then filter in code
      QuerySnapshot snapshot = await _firestore
          .collection("users")
          .where("role", isEqualTo: "guard")
          .get();

      final allGuards = snapshot.docs
          .map(
            (doc) => <String, dynamic>{
              "id": doc.id,
              ...doc.data() as Map<String, dynamic>,
            },
          )
          .toList();

      // Filter to only approved guards
      return allGuards.where((g) => g['status'] == 'approved').toList();
    } catch (e) {
      throw Exception("Error fetching guards: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getAllResidents() async {
    try {
      // Get all residents first, then filter in code
      QuerySnapshot snapshot = await _firestore
          .collection("users")
          .where("role", isEqualTo: "resident")
          .get();

      final allResidents = snapshot.docs
          .map(
            (doc) => <String, dynamic>{
              "id": doc.id,
              ...doc.data() as Map<String, dynamic>,
            },
          )
          .toList();

      // Filter to approved only
      return allResidents.where((r) => r['status'] == 'approved').toList();
    } catch (e) {
      throw Exception("Error fetching residents: $e");
    }
  }

  // DEBUG: Get ALL residents regardless of status
  Future<List<Map<String, dynamic>>> debugGetAllResidents() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection("users")
          .where("role", isEqualTo: "resident")
          .get();

      return snapshot.docs
          .map(
            (doc) => <String, dynamic>{
              "id": doc.id,
              ...doc.data() as Map<String, dynamic>,
            },
          )
          .toList();
    } catch (e) {
      throw Exception("Error fetching all residents: $e");
    }
  }

  Future<void> approveUser(String uid) async {
    try {
      await _firestore.collection("users").doc(uid).update({
        "status": "approved",
      });
    } catch (e) {
      throw Exception("Error approving user: $e");
    }
  }

  Future<void> rejectUser(String uid) async {
    try {
      await _firestore.collection("users").doc(uid).update({
        "status": "rejected",
      });
    } catch (e) {
      throw Exception("Error rejecting user: $e");
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection("users").doc(uid).delete();
    } catch (e) {
      throw Exception("Error deleting user: $e");
    }
  }

  Future<void> updateUserStatus(String uid, String status) async {
    try {
      await _firestore.collection("users").doc(uid).update({"status": status});
    } catch (e) {
      throw Exception("Error updating user status: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> getPendingRequestsStream() {
    return _firestore
        .collection("users")
        .where("status", isEqualTo: "pending")
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{"id": doc.id, ...doc.data()})
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> getGuardsStream() {
    return _firestore
        .collection("users")
        .where("role", isEqualTo: "guard")
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc['status'] == 'approved')
              .map((doc) => <String, dynamic>{"id": doc.id, ...doc.data()})
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> getResidentsStream() {
    return _firestore
        .collection("users")
        .where("role", isEqualTo: "resident")
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc['status'] == 'approved')
              .map((doc) => <String, dynamic>{"id": doc.id, ...doc.data()})
              .toList(),
        );
  }
}
