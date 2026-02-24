import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection("users")
          .where("status", isEqualTo: "pending")
          .get();
      
      return snapshot.docs
          .map((doc) => <String, dynamic>{
                "id": doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
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
          .map((doc) => <String, dynamic>{
                "id": doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
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
          .map((doc) => <String, dynamic>{
                "id": doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
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
          .map((doc) => <String, dynamic>{
                "id": doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
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
      await _firestore.collection("users").doc(uid).update({
        "status": status,
      });
    } catch (e) {
      throw Exception("Error updating user status: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> getPendingRequestsStream() {
    return _firestore
        .collection("users")
        .where("status", isEqualTo: "pending")
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => <String, dynamic>{
                  "id": doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  Stream<List<Map<String, dynamic>>> getGuardsStream() {
    return _firestore
        .collection("users")
        .where("role", isEqualTo: "guard")
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc['status'] == 'approved')
            .map((doc) => <String, dynamic>{
                  "id": doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  Stream<List<Map<String, dynamic>>> getResidentsStream() {
    return _firestore
        .collection("users")
        .where("role", isEqualTo: "resident")
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc['status'] == 'approved')
            .map((doc) => <String, dynamic>{
                  "id": doc.id,
                  ...doc.data(),
                })
            .toList());
  }
}
