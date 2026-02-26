import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/guard_service.dart';

class GuardDashboard extends StatefulWidget {
  const GuardDashboard({super.key});

  @override
  State<GuardDashboard> createState() => _GuardDashboardState();
}

class _GuardDashboardState extends State<GuardDashboard> {
  final GuardService _guardService = GuardService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late MobileScannerController _cameraController;
  bool _isScanning = false;
  Map<String, dynamic>? _currentScanResult;
  List<Map<String, dynamic>> _scanHistory = [];
  String? _errorMessage;
  TextEditingController _manualQRController = TextEditingController();

  // Colors
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController();
    _loadScanHistory();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _manualQRController.dispose();
    super.dispose();
  }

  Future<void> _loadScanHistory() async {
    try {
      String? guardId = _auth.currentUser?.uid;
      if (guardId == null) return;

      final history = await _guardService.getGuardScanHistory(guardId);
      setState(() {
        _scanHistory = history;
      });
    } catch (e) {
      print("Error loading scan history: $e");
    }
  }

  Future<void> _handleQRScan(String rawValue) async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _currentScanResult = null;
      _errorMessage = null;
    });

    try {
      final result = await _guardService.validateQRAndGetResidentInfo(rawValue);

      if (result == null || !result['valid']) {
        _showValidationDialog(
          isValid: false,
          title: "Access Denied",
          message: result?['reason'] ?? "Invalid QR Code",
          resident: result,
          entryType: "IN",
        );
      } else {
        String entryType = result['entry_type'] ?? "IN";
        String buttonText = entryType == "IN" ? "ENTRY" : "EXIT";
        _showValidationDialog(
          isValid: true,
          title: "Access Granted",
          message: "Welcome, ${result['resident_name']}!",
          resident: result,
          entryType: entryType,
        );
      }

      setState(() {
        _currentScanResult = result;
      });
    } catch (e) {
      _showErrorDialog("Error", "Failed to process QR: $e");
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _showValidationDialog({
    required bool isValid,
    required String title,
    required String message,
    Map<String, dynamic>? resident,
    required String entryType,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isValid ? Icons.check_circle : Icons.error,
              color: isValid ? successGreen : dangerRed,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isValid ? successGreen : dangerRed,
                ),
              ),
              if (resident != null && isValid) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: entryType == "IN"
                        ? successGreen.withOpacity(0.1)
                        : const Color(0xFFEC4899).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: entryType == "IN"
                          ? successGreen
                          : const Color(0xFFEC4899),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    entryType == "IN" ? "🔓 ENTRY REQUEST" : "🔒 EXIT REQUEST",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: entryType == "IN"
                          ? successGreen
                          : const Color(0xFFEC4899),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildResidentInfoWidget(resident),
              ],
              if (resident != null && !isValid) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dangerRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dangerRed, width: 1),
                  ),
                  child: Text(
                    resident['resident_name'] ?? 'Unknown Resident',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (isValid)
            TextButton(
              onPressed: () {
                _processAccess(resident!);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: (entryType == "IN"
                        ? successGreen
                        : const Color(0xFFEC4899))
                    .withOpacity(0.1),
              ),
              child: Text(
                entryType == "IN" ? "ALLOW ENTRY" : "ALLOW EXIT",
                style: TextStyle(
                  color: entryType == "IN"
                      ? successGreen
                      : const Color(0xFFEC4899),
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () {
                _processDenial(resident!);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: dangerRed.withOpacity(0.1),
              ),
              child: Text(
                "CONFIRM DENIAL",
                style: TextStyle(color: dangerRed, fontWeight: FontWeight.bold),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentInfoWidget(Map<String, dynamic> resident) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: successGreen, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow("Name", resident['resident_name'] ?? 'N/A'),
          _buildInfoRow("Email", resident['resident_email'] ?? 'N/A'),
          _buildInfoRow("Phone", resident['resident_phone'] ?? 'N/A'),
          _buildInfoRow("Flat/Unit", resident['flat_number'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 12,
              color: textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: textDark,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processAccess(Map<String, dynamic> resident) async {
    try {
      String? guardId = _auth.currentUser?.uid;
      if (guardId == null) return;

      await _guardService.grantAccess(
        residentId: resident['resident_id'],
        qrId: resident['qr_id'],
        guardId: guardId,
      );

      _showSuccessSnackbar("Access granted to ${resident['resident_name']}");
      _loadScanHistory();
    } catch (e) {
      _showErrorSnackbar("Error granting access: $e");
    }
  }

  Future<void> _processDenial(Map<String, dynamic> resident) async {
    try {
      String? guardId = _auth.currentUser?.uid;
      if (guardId == null) return;

      String reason = "Invalid or not approved";
      if (resident['reason'] != null) {
        reason = resident['reason'];
      }

      await _guardService.denyAccess(
        residentId: resident['resident_id'],
        qrId: resident['qr_id'],
        guardId: guardId,
        reason: reason,
      );

      _showErrorSnackbar("Access denied for ${resident['resident_name']}");
      _loadScanHistory();
    } catch (e) {
      _showErrorSnackbar("Error denying access: $e");
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: dangerRed, size: 24),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: dangerRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _auth.signOut();
              Navigator.pop(context);
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: dangerRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualQRDialog() {
    _manualQRController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Manual QR Test"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Paste QR code data here for testing",
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _manualQRController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "uid|qrId|timestamp",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "📋 Tip: Copy the QR data from Resident's QR code or use the format shown in the hint",
                  style: TextStyle(fontSize: 11, color: Color(0xFFF59E0B)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (_manualQRController.text.isNotEmpty) {
                Navigator.pop(context);
                _handleQRScan(_manualQRController.text.trim());
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: primaryIndigo.withOpacity(0.1),
            ),
            child: const Text(
              "PROCESS QR",
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDayLogsDialog(DateTime date) {
    final formattedDate = DateFormat("EEEE, MMMM d, yyyy").format(date);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Text("Delete Logs"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to delete all scan logs for:",
              style: TextStyle(color: textDark, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: dangerRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: dangerRed.withOpacity(0.3)),
              ),
              child: Text(
                formattedDate,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textDark,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "This action cannot be undone.",
              style: TextStyle(
                color: dangerRed,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteDayLogs(date);
            },
            style: TextButton.styleFrom(
              backgroundColor: dangerRed.withOpacity(0.1),
            ),
            child: const Text(
              "Delete",
              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Text("Delete All Logs"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to delete all scan logs permanently?",
              style: TextStyle(color: textDark, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: dangerRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: dangerRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "This will delete ALL logs and cannot be undone!",
                      style: TextStyle(
                        color: dangerRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAllLogs();
            },
            style: TextButton.styleFrom(
              backgroundColor: dangerRed.withOpacity(0.1),
            ),
            child: const Text(
              "Delete All",
              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDayLogs(DateTime date) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: SizedBox(
            height: 100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Deleting logs..."),
                ],
              ),
            ),
          ),
        ),
      );

      String? guardId = _auth.currentUser?.uid;
      if (guardId == null) {
        Navigator.pop(context);
        _showErrorSnackbar("User not authenticated");
        return;
      }

      final deletedCount = await _guardService.deleteLogsForDay(guardId, date);

      Navigator.pop(context);

      setState(() {
        _loadScanHistory();
      });

      _showSuccessSnackbar("$deletedCount logs deleted successfully");
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackbar("Error deleting logs: $e");
    }
  }

  Future<void> _deleteAllLogs() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: SizedBox(
            height: 100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Deleting all logs..."),
                ],
              ),
            ),
          ),
        ),
      );

      String? guardId = _auth.currentUser?.uid;
      if (guardId == null) {
        Navigator.pop(context);
        _showErrorSnackbar("User not authenticated");
        return;
      }

      final deletedCount = await _guardService.deleteAllLogs(guardId);

      Navigator.pop(context);

      setState(() {
        _loadScanHistory();
      });

      _showSuccessSnackbar("$deletedCount logs deleted successfully");
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackbar("Error deleting logs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 2,
      backgroundColor: cardWhite,
      centerTitle: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security, size: 26, color: primaryIndigo),
          const SizedBox(width: 12),
          Text(
            "GUARD DASHBOARD",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_2),
          onPressed: _showManualQRDialog,
          color: primaryIndigo,
          tooltip: "Manual QR Test",
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
          color: textLight,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: _buildScannerSection(),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 2,
          child: _buildHistorySection(),
        ),
      ],
    );
  }

  Widget _buildScannerSection() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleQRScan(barcode.rawValue!);
                  return;
                }
              }
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.3),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  "Position QR code within frame",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 50,
            right: 50,
            top: 100,
            bottom: 100,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.greenAccent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_isScanning)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      color: cardWhite,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: primaryIndigo, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      "Recent Scans",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                if (_scanHistory.isNotEmpty)
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text("Delete All Logs"),
                        onTap: () {
                          Future.delayed(
                            const Duration(milliseconds: 300),
                            () => _showDeleteAllLogsDialog(),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _scanHistory.isEmpty
                ? Center(
                    child: Text(
                      "No scans yet",
                      style: TextStyle(color: textLight, fontSize: 14),
                    ),
                  )
                : _buildGroupedLogsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedLogsList() {
    // Group logs by date
    Map<String, List<Map<String, dynamic>>> groupedLogs = {};

    for (var log in _scanHistory) {
      final timestamp = (log['timestamp'] as Timestamp).toDate();
      final dateKey = DateFormat("yyyy-MM-dd").format(timestamp);
      
      if (!groupedLogs.containsKey(dateKey)) {
        groupedLogs[dateKey] = [];
      }
      groupedLogs[dateKey]!.add(log);
    }

    // Sort dates in descending order
    final sortedDates = groupedLogs.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final logs = groupedLogs[dateKey]!;
        final dateObj = DateTime.parse(dateKey);
        final formattedDate = DateFormat("EEEE, MMMM d, yyyy").format(dateObj);

        return Column(
          children: [
            // Date Header with Delete Button
            Container(
              color: bgLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryIndigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${logs.length} scans",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryIndigo,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showDeleteDayLogsDialog(dateObj),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: dangerRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: dangerRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Logs for this day
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              itemBuilder: (context, logIndex) {
                final log = logs[logIndex];
                final timestamp = (log['timestamp'] as Timestamp).toDate();
                final isGranted = log['access_granted'] == true;
                final entryType = log['entry_type'] ?? 'IN';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: bgLight, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isGranted
                              ? successGreen.withOpacity(0.2)
                              : dangerRed.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isGranted
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: isGranted ? successGreen : dangerRed,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log['resident_name'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  DateFormat("HH:mm:ss").format(timestamp),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textLight,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isGranted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: entryType == 'IN'
                                          ? successGreen.withOpacity(0.2)
                                          : const Color(0xFFEC4899).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      entryType,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: entryType == 'IN'
                                            ? successGreen
                                            : const Color(0xFFEC4899),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        isGranted ? "✓ ALLOWED" : "✗ DENIED",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isGranted ? successGreen : dangerRed,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}