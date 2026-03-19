import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../widgets/theme_toggle.dart';
import '../../providers/theme_provider.dart';
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
  List<Map<String, dynamic>> _scanHistory = [];
  TextEditingController _manualQRController = TextEditingController();
  Map<String, dynamic>? _guardInfo;
  bool _isProfileLoading = true;
  int _currentTab = 0;

  // NOTE: _currentScanResult and _errorMessage were previously present but
  // not used anywhere else in the file. They were removed to clean analyzer
  // warnings.

  // Text controller already declared above

  // Semantic colors
  static const Color successGreen = Color(0xFF22C55E);
  static const Color dangerRed = Color(0xFFEF4444);

  ThemeProvider get _theme => Provider.of<ThemeProvider>(context);

  Color get primaryIndigo => _theme.primaryColor;
  Color get secondaryColor => _theme.secondaryColor;
  Color get accentColor => _theme.accentColor;
  Color get bgLight => _theme.backgroundColor;
  Color get cardWhite => _theme.cardColor;
  Color get textDark => _theme.textColor;
  Color get textLight => _theme.textSecondaryColor;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController();
    _loadScanHistory();
    _loadGuardProfile();
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

  Future<void> _loadGuardProfile() async {
    try {
      final guardId = _auth.currentUser?.uid;
      if (guardId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(guardId)
          .get();

      if (!mounted) return;
      setState(() {
        _guardInfo = snapshot.data();
        _isProfileLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProfileLoading = false;
      });
    }
  }

  Future<void> _handleQRScan(String rawValue) async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
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
        String welcomeName = result['is_visitor'] == true
            ? result['visitor_name'] ?? 'Visitor'
            : result['resident_name'] ?? 'Unknown';
        _showValidationDialog(
          isValid: true,
          title: "Access Granted",
          message: "Welcome, $welcomeName!",
          resident: result,
          entryType: entryType,
        );
      }

      // result is used immediately when showing the dialog; no persistent
      // storage is required here.
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
                        ? successGreen.withAlpha(26)
                        : const Color(0xFFEC4899).withAlpha(26),
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
                    color: dangerRed.withAlpha(26),
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
                backgroundColor:
                    (entryType == "IN" ? successGreen : const Color(0xFFEC4899))
                        .withAlpha(26),
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
                backgroundColor: dangerRed.withAlpha(26),
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
    bool isVisitor = resident['is_visitor'] == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: successGreen.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: successGreen, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isVisitor) ...[
            // Visitor Details
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: primaryIndigo, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "👤 Visitor Details",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryIndigo,
                    ),
                  ),
                ],
              ),
            ),
            _buildInfoRow("Name", resident['visitor_name'] ?? 'Unknown'),
            _buildInfoRow("Email", resident['visitor_email'] ?? 'N/A'),
            _buildInfoRow("Phone", resident['visitor_phone'] ?? 'N/A'),
            _buildInfoRow("Purpose", resident['visitor_purpose'] ?? 'Visit'),
            const Divider(height: 16),
            // Resident/Host Details
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.home, color: primaryIndigo, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "🏠 Resident (Host)",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryIndigo,
                    ),
                  ),
                ],
              ),
            ),
            _buildInfoRow("Name", resident['resident_name'] ?? 'Unknown'),
            _buildInfoRow("Email", resident['resident_email'] ?? 'N/A'),
            _buildInfoRow("Phone", resident['resident_phone'] ?? 'N/A'),
            _buildInfoRow("Flat/Unit", resident['flat_number'] ?? 'N/A'),
          ] else ...[
            _buildInfoRow("Name", resident['resident_name'] ?? 'N/A'),
            _buildInfoRow("Email", resident['resident_email'] ?? 'N/A'),
            _buildInfoRow("Phone", resident['resident_phone'] ?? 'N/A'),
            _buildInfoRow("Flat/Unit", resident['flat_number'] ?? 'N/A'),
          ],
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

      // Check if it's a visitor QR
      if (resident['is_visitor'] == true) {
        await _guardService.grantVisitorAccess(
          residentId: resident['resident_id'],
          visitorQrId: resident['qr_id'],
          guardId: guardId,
          visitorName: resident['visitor_name'] ?? 'Visitor',
        );
        _showSuccessSnackbar(
          "Visitor access granted: ${resident['visitor_name']}",
        );
      } else {
        // Regular resident QR
        await _guardService.grantAccess(
          residentId: resident['resident_id'],
          qrId: resident['qr_id'],
          guardId: guardId,
        );
        _showSuccessSnackbar("Access granted to ${resident['resident_name']}");
      }

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

      // Check if it's a visitor QR
      if (resident['is_visitor'] == true) {
        await _guardService.denyVisitorAccess(
          residentId: resident['resident_id'],
          visitorQrId: resident['qr_id'],
          guardId: guardId,
          reason: reason,
          visitorName: resident['visitor_name'] ?? 'Visitor',
        );
        _showErrorSnackbar(
          "Access denied for visitor: ${resident['visitor_name']}",
        );
      } else {
        // Regular resident QR
        await _guardService.denyAccess(
          residentId: resident['resident_id'],
          qrId: resident['qr_id'],
          guardId: guardId,
          reason: reason,
        );
        _showErrorSnackbar("Access denied for ${resident['resident_name']}");
      }

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
            child: const Text("Logout", style: TextStyle(color: dangerRed)),
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
                  color: const Color(0xFFF59E0B).withAlpha(26),
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
              backgroundColor: primaryIndigo.withAlpha(26),
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
                color: dangerRed.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: dangerRed.withAlpha(77)),
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
              backgroundColor: dangerRed.withAlpha(26),
            ),
            child: const Text(
              "Delete",
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
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
                color: dangerRed.withAlpha(26),
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
              backgroundColor: dangerRed.withAlpha(26),
            ),
            child: const Text(
              "Delete All",
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
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
    final stats = _getTodayStats();
    return Scaffold(
      backgroundColor: bgLight,
      appBar: _buildAppBar(),
      body: _buildBody(stats),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: cardWhite,
      centerTitle: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(Icons.security, size: 26, color: primaryIndigo),
          const SizedBox(width: 12),
          Text(
            "Guard Dashboard",
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
        const ThemeToggleButton(compact: true),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(Map<String, int> stats) {
    switch (_currentTab) {
      case 1:
        return _buildScanContent();
      case 2:
        return _buildProfileContent();
      default:
        return _buildDashboardContent(stats);
    }
  }

  Widget _buildDashboardContent(Map<String, int> stats) {
    final guardName =
        _guardInfo?['name'] ?? _auth.currentUser?.displayName ?? "Security";
    final guardEmail =
        _guardInfo?['email'] ?? _auth.currentUser?.email ?? "on-duty";
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(guardName, guardEmail),
            const SizedBox(height: 16),
            _buildStatsRow(stats),
            const SizedBox(height: 16),
            _buildScannerCard(),
            const SizedBox(height: 16),
            Expanded(child: _buildHistorySection()),
          ],
        ),
      ),
    );
  }

  Widget _buildScanContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            _buildSectionHeader(
              icon: Icons.qr_code_scanner,
              title: "Scan QR Code",
              subtitle: "Verify resident or visitor access",
            ),
            const SizedBox(height: 12),
            _buildScannerCard(),
            const SizedBox(height: 16),
            Expanded(child: _buildHistorySection()),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
            _buildSectionHeader(
              icon: Icons.person,
              title: "Profile",
              subtitle: "Your identity and preferences",
            ),
            const SizedBox(height: 12),
            _buildGuardDetailsCard(),
            const SizedBox(height: 16),
            _buildProfileActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: NavigationBar(
            height: 64,
            backgroundColor: cardWhite,
            elevation: 8,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: _currentTab,
            onDestinationSelected: (index) {
              setState(() => _currentTab = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: "Dashboard",
              ),
              NavigationDestination(
                icon: Icon(Icons.qr_code_scanner),
                selectedIcon: Icon(Icons.qr_code_2),
                label: "Scan",
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, int> _getTodayStats() {
    final now = DateTime.now();
    int total = 0;
    int approved = 0;
    int denied = 0;

    for (final log in _scanHistory) {
      final timestamp = (log['timestamp'] as Timestamp?)?.toDate();
      if (timestamp == null) continue;
      if (!DateUtils.isSameDay(timestamp, now)) continue;

      total += 1;
      final granted = log['access_granted'] == true;
      if (granted) {
        approved += 1;
      } else {
        denied += 1;
      }
    }

    return {'total': total, 'approved': approved, 'denied': denied};
  }

  Widget _buildHeaderCard(String guardName, String guardEmail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primaryIndigo.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_outlined, color: primaryIndigo, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guardName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  guardEmail,
                  style: TextStyle(fontSize: 13, color: textLight),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: successGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "On Duty",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: successGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, int> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: "Scans Today",
            value: "${stats['total']}",
            icon: Icons.qr_code_2,
            color: primaryIndigo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: "Approved",
            value: "${stats['approved']}",
            icon: Icons.verified,
            color: successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: "Denied",
            value: "${stats['denied']}",
            icon: Icons.cancel_outlined,
            color: dangerRed,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            primaryIndigo.withOpacity(0.12),
            accentColor.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: textLight.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardWhite.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryIndigo, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardDetailsCard() {
    if (_isProfileLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final name =
        _guardInfo?['name'] ??
        _auth.currentUser?.displayName ??
        "Security Guard";
    final email = _guardInfo?['email'] ?? _auth.currentUser?.email ?? "";
    final phone = _guardInfo?['phone'] ?? "Not provided";
    final shift = _guardInfo?['shift'] ?? "Day Shift";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryIndigo.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.badge_outlined, color: primaryIndigo),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Guard on Duty",
                      style: TextStyle(fontSize: 12, color: textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProfileInfoRow("Email", email),
          _buildProfileInfoRow("Phone", phone),
          _buildProfileInfoRow("Shift", shift),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileActions() {
    return Column(
      children: [
        _PrimaryActionButton(
          label: "Edit Profile",
          icon: Icons.edit,
          color: primaryIndigo,
          onTap: _showEditProfileDialog,
        ),
        const SizedBox(height: 12),
        _PrimaryActionButton(
          label: "Scan QR Code",
          icon: Icons.qr_code_scanner,
          color: accentColor,
          onTap: () => setState(() => _currentTab = 1),
        ),
        const SizedBox(height: 12),
        _PrimaryActionButton(
          label: "Logout",
          icon: Icons.logout,
          color: dangerRed,
          onTap: _logout,
        ),
      ],
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(
      text: _guardInfo?['name'] ?? _auth.currentUser?.displayName ?? "",
    );
    final emailController = TextEditingController(
      text: _guardInfo?['email'] ?? _auth.currentUser?.email ?? "",
    );
    final phoneController = TextEditingController(
      text: _guardInfo?['phone'] ?? "",
    );
    final shiftController = TextEditingController(
      text: _guardInfo?['shift'] ?? "Day Shift",
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.edit, color: primaryIndigo, size: 22),
            const SizedBox(width: 8),
            Text("Edit Profile", style: TextStyle(color: textDark)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileFormField(
                "Name",
                nameController,
                Icons.person,
                "Full name",
                isRequired: true,
              ),
              const SizedBox(height: 12),
              _buildProfileFormField(
                "Email",
                emailController,
                Icons.email,
                "you@example.com",
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildProfileFormField(
                "Phone",
                phoneController,
                Icons.phone,
                "+1-234-567-8900",
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildProfileFormField(
                "Shift",
                shiftController,
                Icons.schedule,
                "Day Shift",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: textLight)),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                _showErrorSnackbar("Please enter your name");
                return;
              }

              Navigator.pop(context);
              await _updateGuardProfile(
                nameController.text.trim(),
                emailController.text.trim(),
                phoneController.text.trim(),
                shiftController.text.trim(),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: primaryIndigo.withOpacity(0.12),
            ),
            child: Text(
              "Save",
              style: TextStyle(
                color: primaryIndigo,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileFormField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    bool isRequired = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? "$label *" : label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: textDark),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: bgLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: textLight.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: textLight.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryIndigo.withOpacity(0.6)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateGuardProfile(
    String name,
    String email,
    String phone,
    String shift,
  ) async {
    try {
      final guardId = _auth.currentUser?.uid;
      if (guardId == null) {
        _showErrorSnackbar("User not authenticated");
        return;
      }

      final updates = {
        'name': name,
        'email': email,
        'phone': phone,
        'shift': shift,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(guardId)
          .set(updates, SetOptions(merge: true));

      await _auth.currentUser?.updateDisplayName(name);

      setState(() {
        _guardInfo = {...?_guardInfo, ...updates};
      });

      _showSuccessSnackbar("Profile updated successfully!");
    } catch (e) {
      _showErrorSnackbar("Error updating profile: $e");
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 12, color: textLight)),
        ],
      ),
    );
  }

  Widget _buildScannerCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primaryIndigo.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.qr_code_scanner, color: primaryIndigo),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Live Scanner",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Align QR within the frame",
                        style: TextStyle(fontSize: 12, color: textLight),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showManualQRDialog,
                  icon: const Icon(Icons.keyboard_alt_outlined),
                  color: textLight,
                  tooltip: "Manual Entry",
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          AspectRatio(aspectRatio: 16 / 10, child: _buildScannerSection()),
        ],
      ),
    );
  }

  Widget _buildScannerSection() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: Container(
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
                color: Colors.black.withAlpha(77),
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Text(
                    "Position QR code within frame",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 40,
              right: 40,
              top: 70,
              bottom: 70,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF2DD4BF), width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            if (_isScanning)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(153),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: primaryIndigo.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.history,
                        color: primaryIndigo,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
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
    final sortedDates = groupedLogs.keys.toList()
      ..sort((a, b) => b.compareTo(a));

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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryIndigo.withAlpha(26),
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
                            color: dangerRed.withAlpha(26),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                              ? successGreen.withAlpha(51)
                              : dangerRed.withAlpha(51),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isGranted ? Icons.check_circle : Icons.cancel,
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
                                          ? successGreen.withAlpha(51)
                                          : const Color(
                                              0xFFEC4899,
                                            ).withAlpha(51),
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

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
