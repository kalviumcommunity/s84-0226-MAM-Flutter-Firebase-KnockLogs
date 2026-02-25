import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/resident_service.dart';

class ResidentDashboard extends StatefulWidget {
  const ResidentDashboard({super.key});

  @override
  State<ResidentDashboard> createState() => _ResidentDashboardState();
}

class _ResidentDashboardState extends State<ResidentDashboard> {
  final ResidentService _residentService = ResidentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _residentInfo;
  String? _currentQRData;
  Map<String, dynamic> _todaysSummary = {};
  List<Map<String, dynamic>> _accessLogs = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Colors
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningorange = Color(0xFFF59E0B);
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final residentInfo = await _residentService.getCurrentResidentInfo();
      final todaysSummary = await _residentService.getTodaysSummary();
      final accessLogs = await _residentService.getCheckInOutRecords();
      final qrData = _residentService.generateQRData();

      setState(() {
        _residentInfo = residentInfo;
        _todaysSummary = todaysSummary;
        _accessLogs = accessLogs;
        _currentQRData = qrData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading dashboard: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _generateNewQR() async {
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
                  Text("Generating QR Code..."),
                ],
              ),
            ),
          ),
        ),
      );

      final newQRData = await _residentService.createQRSession();

      Navigator.pop(context);
      setState(() {
        _currentQRData = newQRData;
      });

      _showSuccessSnackbar("New QR code generated successfully!");
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackbar("Failed to generate QR: $e");
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _generateNewQR,
        backgroundColor: primaryIndigo,
        child: const Icon(Icons.qr_code),
      ),
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
          Icon(Icons.person, size: 26, color: primaryIndigo),
          const SizedBox(width: 12),
          Text(
            "RESIDENT DASHBOARD",
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
          icon: const Icon(Icons.logout),
          onPressed: _logout,
          color: textLight,
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: dangerRed),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? "Unknown error",
            textAlign: TextAlign.center,
            style: TextStyle(color: textDark, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadDashboardData,
            style: ElevatedButton.styleFrom(backgroundColor: primaryIndigo),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // QR Code Card
              _buildQRCodeCard(),
              const SizedBox(height: 24),

              // Resident Details Card
              _buildResidentDetailsCard(),
              const SizedBox(height: 24),

              // Today's Summary Card
              _buildTodaysSummaryCard(),
              const SizedBox(height: 24),

              // Access History Section
              _buildAccessHistorySection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRCodeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardWhite,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              "Show this QR to Guard for Entry",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textLight,
              ),
            ),
            const SizedBox(height: 20),
            if (_currentQRData != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: primaryIndigo, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: _currentQRData!,
                  version: QrVersions.auto,
                  size: 250,
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF6366F1),
                  ),
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF6366F1),
                  ),
                ),
              )
            else
              const SizedBox(
                height: 250,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            const SizedBox(height: 20),
            // QR Data Display Section for Manual Testing
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgLight,
                border: Border.all(color: textLight, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "QR Data (for manual testing):",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SelectableText(
                            _currentQRData ?? "",
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                              color: textDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _currentQRData ?? ""));
                          _showSuccessSnackbar("QR data copied! Paste it in Guard Dashboard");
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryIndigo,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.content_copy,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "QR expires after scan",
              style: TextStyle(
                fontSize: 12,
                color: warningorange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResidentDetailsCard() {
    if (_residentInfo == null) {
      return const SizedBox();
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardWhite,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              "Name",
              _residentInfo!['name'] ?? "N/A",
              Icons.person,
            ),
            _buildDetailRow(
              "Email",
              _residentInfo!['email'] ?? "N/A",
              Icons.email,
            ),
            _buildDetailRow(
              "Phone",
              _residentInfo!['phone'] ?? "N/A",
              Icons.phone,
            ),
            _buildDetailRow(
              "Flat/Unit",
              _residentInfo!['flat_number'] ?? "N/A",
              Icons.home,
            ),
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: _residentInfo!['status'] == 'approved'
                    ? successGreen.withOpacity(0.1)
                    : warningorange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _residentInfo!['status'] == 'approved'
                        ? Icons.verified
                        : Icons.pending,
                    color: _residentInfo!['status'] == 'approved'
                        ? successGreen
                        : warningorange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Status: ${_residentInfo!['status']?.toUpperCase() ?? 'UNKNOWN'}",
                    style: TextStyle(
                      color: _residentInfo!['status'] == 'approved'
                          ? successGreen
                          : warningorange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryIndigo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysSummaryCard() {
    DateTime? checkInTime = _todaysSummary['check_in_time'];
    DateTime? checkOutTime = _todaysSummary['check_out_time'];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardWhite,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Access Summary",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryTile(
                    "Check-In",
                    checkInTime != null
                        ? DateFormat("HH:mm").format(checkInTime)
                        : "Not yet",
                    checkInTime != null ? successGreen : textLight,
                    Icons.login,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryTile(
                    "Check-Out",
                    checkOutTime != null
                        ? DateFormat("HH:mm").format(checkOutTime)
                        : "Not yet",
                    checkOutTime != null ? successGreen : textLight,
                    Icons.logout,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryTile(
                    "Entries",
                    "${_todaysSummary['total_entries'] ?? 0}",
                    successGreen,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryTile(
                    "Denied",
                    "${_todaysSummary['denied_attempts'] ?? 0}",
                    (_todaysSummary['denied_attempts'] ?? 0) > 0
                        ? dangerRed
                        : successGreen,
                    Icons.cancel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTile(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Access History",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        const SizedBox(height: 12),
        if (_accessLogs.isEmpty)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: cardWhite,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  "No access history yet",
                  style: TextStyle(color: textLight, fontSize: 14),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _accessLogs.length,
            itemBuilder: (context, index) {
              final log = _accessLogs[index];
              final timestamp = (log['timestamp'] as Timestamp).toDate();
              final isGranted = log['access_granted'] == true;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: cardWhite,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isGranted
                              ? successGreen.withOpacity(0.2)
                              : dangerRed.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isGranted ? Icons.check_circle : Icons.cancel,
                          color: isGranted ? successGreen : dangerRed,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isGranted ? "Access Granted" : "Access Denied",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isGranted ? successGreen : dangerRed,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat("MMM dd, HH:mm").format(timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (log['type'] != null && log['type'] != 'denied')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: log['type'] == 'IN'
                                      ? successGreen.withOpacity(0.2)
                                      : const Color(0xFFEC4899).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  log['type'].toString().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: log['type'] == 'IN'
                                        ? successGreen
                                        : const Color(0xFFEC4899),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}