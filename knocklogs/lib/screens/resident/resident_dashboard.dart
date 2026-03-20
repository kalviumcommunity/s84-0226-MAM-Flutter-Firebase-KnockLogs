import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../../services/resident_service.dart';
import '../landing/landing_page.dart';


import '../../providers/theme_provider.dart';
import '../../services/resident_service.dart';
import '../auth/login_screen.dart';
import '../../widgets/theme_toggle.dart';


class ResidentDashboard extends StatefulWidget {
  const ResidentDashboard({super.key});

  @override
  State<ResidentDashboard> createState() => _ResidentDashboardState();
}

class _ResidentDashboardState extends State<ResidentDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ResidentService _residentService = ResidentService();

  Map<String, dynamic>? _residentInfo;
  String? _currentQRData;
  Map<String, dynamic> _todaysSummary = {};
  List<Map<String, dynamic>> _accessLogs = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentTab = 0;

  // Semantic colors
  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);

  ThemeProvider get _theme => Provider.of<ThemeProvider>(context);

  Color get primaryColor => _theme.primaryColor;
  Color get secondaryColor => _theme.secondaryColor;
  Color get accentColor => _theme.accentColor;
  Color get backgroundColor => _theme.backgroundColor;
  Color get cardColor => _theme.cardColor;
  Color get textPrimary => _theme.textColor;
  Color get textSecondary => _theme.textSecondaryColor;

  // Backwards-compatible aliases while we refresh the visuals
  Color get primaryIndigo => primaryColor;
  Color get bgLight => backgroundColor;
  Color get cardWhite => cardColor;
  Color get textDark => textPrimary;
  Color get textLight => textSecondary;
  Color get warningorange => warningAmber;

  bool get _isCompact => MediaQuery.sizeOf(context).width < 380;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = _isCompact ? 12.0 : 16.0;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorWidget()
            : _buildTabBody(horizontalPadding),
      ),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton.extended(
              onPressed: _generateNewQR,
              backgroundColor: primaryIndigo,
              icon: const Icon(Icons.restart_alt),
              label: const Text("Refresh QR"),
              elevation: 4,
            )
          : null,
      floatingActionButtonLocation: _currentTab == 0
          ? FloatingActionButtonLocation.endFloat
          : null,
      bottomNavigationBar: SafeArea(
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
              onDestinationSelected: (i) => setState(() => _currentTab = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: "Dashboard",
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_toggle_off),
                  selectedIcon: Icon(Icons.history),
                  label: "History",
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
      ),
    );
  }

  Widget _buildTabBody(double horizontalPadding) {
    switch (_currentTab) {
      case 1:
        return _buildHistoryContent(horizontalPadding);
      case 2:
        return _buildProfileContent(horizontalPadding);
      default:
        return _buildHomeContent(horizontalPadding);
    }
  }

  Widget _buildHomeContent(double horizontalPadding) {
    return _buildContent(horizontalPadding);
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

      if (mounted) Navigator.pop(context);
      setState(() {
        _currentQRData = newQRData;
      });

      _showSuccessSnackbar("New QR code generated successfully!");
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorSnackbar("Failed to generate QR: $e");
    }
  }

  Future<void> _shareEntryPass() async {
    if (_currentQRData == null) {
      _showErrorSnackbar("Generate a QR first to share");
      return;
    }

    final residentName = _residentInfo?['name'] ?? 'Resident';
    final unit = _residentInfo?['flatNo'] ?? '';
    final shareText =
        "KnockLogs Entry Pass\nResident: $residentName $unit\nPresent this secure QR at the gate.\n\n${_currentQRData!}";

    try {
      await Share.share(shareText, subject: 'KnockLogs Entry Pass');
      _showSuccessSnackbar("Entry pass shared securely");
    } catch (e) {
      _showErrorSnackbar("Unable to share entry pass: $e");
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
            onPressed: () async {

              Navigator.pop(context);
              await _auth.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LandingPage()),
                  (Route<dynamic> route) => false,
                );
              }

              await _auth.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );

            },
            child: const Text("Logout", style: TextStyle(color: dangerRed)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(
      text: _residentInfo?['name'] ?? "",
    );
    final emailController = TextEditingController(
      text: _residentInfo?['email'] ?? "",
    );
    final phoneController = TextEditingController(
      text: _residentInfo?['phone'] ?? "",
    );
    final flatController = TextEditingController(
      text: _residentInfo?['flatNo'] ?? "",
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
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
                "Flat/Unit",
                flatController,
                Icons.home,
                "A-1203",
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
              await _updateResidentProfile(
                nameController.text.trim(),
                emailController.text.trim(),
                phoneController.text.trim(),
                flatController.text.trim(),
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
            hintStyle: TextStyle(color: textLight),
            prefixIcon: Icon(icon, size: 18, color: textLight),
            filled: true,
            fillColor: backgroundColor.withOpacity(
              _theme.isDarkMode ? 0.2 : 0.6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: textLight.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: textLight.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryIndigo.withOpacity(0.6)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateResidentProfile(
    String name,
    String email,
    String phone,
    String flatNo,
  ) async {
    try {
      final updates = <String, dynamic>{
        "name": name,
        "email": email,
        "phone": phone,
        "flatNo": flatNo,
      };

      await _residentService.updateResidentProfile(updates);
      setState(() {
        _residentInfo = {...?_residentInfo, ...updates};
      });
      _showSuccessSnackbar("Profile updated successfully!");
    } catch (e) {
      _showErrorSnackbar("Error updating profile: $e");
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      titleSpacing: 0,
      toolbarHeight: 64,
      title: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primaryIndigo, secondaryColor.withOpacity(0.8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryIndigo.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.shield, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Resident Dashboard",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              Text(
                "Security-first • Real-time",
                style: TextStyle(
                  fontSize: 12,
                  color: textLight,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ThemeToggleButton(compact: true),
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

  Widget _buildContent(double horizontalPadding) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundColor, backgroundColor.withOpacity(0.96)],
          ),
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              24,
            ),
            child: Column(
              children: [
                _buildHeroHeader(),
                const SizedBox(height: 16),
                _buildVisitorQRSection(),
                const SizedBox(height: 20),
                _buildQRCodeCard(),
                const SizedBox(height: 20),
                _buildTodaysSummaryCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryContent(double horizontalPadding) {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SectionHeader(
                      icon: Icons.history,
                      title: "Access History",
                      subtitle: "Latest entries and denials",
                      textColor: textDark,
                      subTextColor: textLight,
                    ),
                  ),
                  if (_accessLogs.isNotEmpty)
                    TextButton.icon(
                      onPressed: _confirmClearHistory,
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      label: const Text("Clear All"),
                      style: TextButton.styleFrom(foregroundColor: dangerRed),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildAccessHistorySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(double horizontalPadding) {
    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            24,
          ),
          child: Column(
            children: [
              _SectionHeader(
                icon: Icons.person,
                title: "Profile",
                subtitle: "Your identity and preferences",
                textColor: textDark,
                subTextColor: textLight,
              ),
              const SizedBox(height: 12),
              _buildResidentDetailsCard(),
              const SizedBox(height: 16),
              _buildProfileActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileActions() {
    final compact = _isCompact;
    return Column(
      children: [
        _PrimaryActionButton(
          label: "Edit Profile",
          icon: Icons.edit,
          color: primaryIndigo,
          onTap: _showEditProfileDialog,
          textColor: Colors.white,
          compact: compact,
        ),
        const SizedBox(height: 12),
        _PrimaryActionButton(
          label: "Share Entry Pass",
          icon: Icons.ios_share,
          color: accentColor,
          onTap: _shareEntryPass,
          textColor: Colors.white,
          compact: compact,
        ),
        const SizedBox(height: 12),
        _PrimaryActionButton(
          label: "Logout",
          icon: Icons.logout,
          color: dangerRed,
          onTap: _logout,
          textColor: Colors.white,
          compact: compact,
        ),
      ],
    );
  }

  Widget _buildHeroHeader() {
    final compact = _isCompact;
    final name = _residentInfo?['name'] ?? "Resident";
    final unit = _residentInfo?['flatNo'] ?? "Unit";
    final status = (_residentInfo?['status'] ?? 'pending').toString();
    final statusColor = status.toLowerCase() == 'approved'
        ? successGreen
        : warningAmber;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            primaryIndigo.withOpacity(0.12),
            accentColor.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: textLight.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 10 : 12),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryIndigo.withOpacity(0.18)),
                ),
                child: Icon(
                  Icons.lock_reset,
                  color: primaryIndigo,
                  size: compact ? 22 : 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, $name",
                      style: TextStyle(
                        fontSize: compact ? 17 : 20,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Flat $unit • Always-on security",
                      style: TextStyle(
                        fontSize: compact ? 12 : 13,
                        color: textLight,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 12,
                  vertical: compact ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(compact ? 12 : 14),
                  border: Border.all(color: statusColor.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Icon(
                      status.toLowerCase() == 'approved'
                          ? Icons.verified
                          : Icons.pending,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.shield_moon_outlined, color: textLight, size: 18),
              const SizedBox(width: 8),
              Text(
                "Encrypted passes • Live monitoring • Secure sharing",
                style: TextStyle(fontSize: 12, color: textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeCard() {
    final qrData = _currentQRData;
    final compact = _isCompact;
    final qrSize = compact ? 200.0 : 240.0;
    final blockPadding = compact ? 16.0 : 20.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryIndigo.withOpacity(0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(blockPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: primaryIndigo.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_2, color: primaryIndigo, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Entry Pass",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: successGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_moon, size: 16, color: successGreen),
                      const SizedBox(width: 6),
                      Text(
                        "Rotates on demand",
                        style: TextStyle(
                          fontSize: 11,
                          color: successGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              "Show this secure QR at the gate. Each scan updates in real time.",
              style: TextStyle(color: textLight, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(compact ? 12 : 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryIndigo.withOpacity(0.1), cardColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryIndigo.withOpacity(0.18)),
              ),
              child: qrData != null
                  ? Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryIndigo.withOpacity(0.35),
                              width: 1.4,
                            ),
                          ),
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: qrSize,
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: primaryIndigo,
                            ),
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: primaryIndigo,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMetaChip(
                              icon: Icons.timer,
                              label: "Expires after scan",
                              color: warningAmber,
                            ),
                            _buildMetaChip(
                              icon: Icons.wifi_protected_setup,
                              label: "Single-use session",
                              color: primaryIndigo,
                            ),
                          ],
                        ),
                      ],
                    )
                  : SizedBox(
                      height: qrSize + 40,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
            ),
            const SizedBox(height: 12),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    Icon(Icons.code, color: textLight, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Session payload (for testing)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textLight,
                      ),
                    ),
                  ],
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bgLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: textLight.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            qrData ?? "",
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                              color: textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: qrData ?? ""),
                            );
                            _showSuccessSnackbar(
                              "QR data copied for guard app",
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                          color: primaryIndigo,
                          tooltip: "Copy session payload",
                        ),
                      ],
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

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentDetailsCard() {
    if (_residentInfo == null) {
      return const SizedBox();
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: textLight.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(_isCompact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryIndigo.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.badge, color: primaryIndigo),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Identity",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    Text(
                      "Keep your contact details current",
                      style: TextStyle(fontSize: 12, color: textLight),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: _isCompact ? double.infinity : 240,
                  child: _buildDetailRow(
                    "Name",
                    _residentInfo!['name'] ?? "N/A",
                    Icons.person,
                  ),
                ),
                SizedBox(
                  width: _isCompact ? double.infinity : 240,
                  child: _buildDetailRow(
                    "Email",
                    _residentInfo!['email'] ?? "N/A",
                    Icons.email,
                  ),
                ),
                SizedBox(
                  width: _isCompact ? double.infinity : 240,
                  child: _buildDetailRow(
                    "Phone",
                    _residentInfo!['phone'] ?? "Not provided",
                    Icons.phone,
                  ),
                ),
                SizedBox(
                  width: _isCompact ? double.infinity : 240,
                  child: _buildDetailRow(
                    "Flat/Unit",
                    _residentInfo!['flatNo'] ?? "N/A",
                    Icons.home,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: _residentInfo!['status'] == 'approved'
                    ? successGreen.withOpacity(0.1)
                    : warningorange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _residentInfo!['status'] == 'approved'
                      ? successGreen.withOpacity(0.35)
                      : warningorange.withOpacity(0.35),
                ),
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
                  const SizedBox(width: 10),
                  Text(
                    "Status: ${_residentInfo!['status']?.toUpperCase() ?? 'UNKNOWN'}",
                    style: TextStyle(
                      color: _residentInfo!['status'] == 'approved'
                          ? successGreen
                          : warningorange,
                      fontWeight: FontWeight.w700,
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
    final compact = _isCompact;
    final tileSpacing = compact ? 10.0 : 12.0;
    final tilePadding = compact ? 14.0 : 16.0;

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
                    tilePadding,
                  ),
                ),
                SizedBox(width: tileSpacing),
                Expanded(
                  child: _buildSummaryTile(
                    "Check-Out",
                    checkOutTime != null
                        ? DateFormat("HH:mm").format(checkOutTime)
                        : "Not yet",
                    checkOutTime != null ? successGreen : textLight,
                    Icons.logout,
                    tilePadding,
                  ),
                ),
              ],
            ),
            SizedBox(height: tileSpacing),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryTile(
                    "Entries",
                    "${_todaysSummary['total_entries'] ?? 0}",
                    successGreen,
                    Icons.check_circle,
                    tilePadding,
                  ),
                ),
                SizedBox(width: tileSpacing),
                Expanded(
                  child: _buildSummaryTile(
                    "Denied",
                    "${_todaysSummary['denied_attempts'] ?? 0}",
                    (_todaysSummary['denied_attempts'] ?? 0) > 0
                        ? dangerRed
                        : successGreen,
                    Icons.cancel,
                    tilePadding,
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
    double padding,
  ) {
    return Container(
      padding: EdgeInsets.all(padding),
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

  Widget _buildVisitorQRSection() {
    final compact = _isCompact;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardWhite,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people, color: primaryIndigo, size: 24),
                          SizedBox(width: compact ? 8 : 12),
                          Text(
                            "Visitor Access",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Generate QR codes for guests",
                        style: TextStyle(fontSize: 12, color: textLight),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddVisitorDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add Visitor"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryIndigo,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 16,
                      vertical: compact ? 8 : 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _residentService.getActiveVisitorQRs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dangerRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Error loading visitors",
                      style: TextStyle(color: dangerRed, fontSize: 12),
                    ),
                  );
                }

                final visitors = snapshot.data ?? [];
                if (visitors.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: textLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: textLight.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(
                        "No active visitor QR codes",
                        style: TextStyle(color: textLight, fontSize: 12),
                      ),
                    ),
                  );
                }

                return Column(
                  children: List.generate(visitors.length, (index) {
                    final visitor = visitors[index];
                    final expiresAt = (visitor['expires_at'] as Timestamp)
                        .toDate();
                    final timeRemaining = expiresAt
                        .difference(DateTime.now())
                        .inHours;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: primaryIndigo.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryIndigo.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        visitor['visitor_name'] ?? 'Unknown',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        visitor['visitor_phone'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textLight,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: warningorange.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'Expires: ${DateFormat('hh:mm a').format(expiresAt)} (${timeRemaining}h left)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: warningorange,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: const Row(
                                        children: [
                                          Icon(Icons.qr_code, size: 18),
                                          SizedBox(width: 8),
                                          Text("View QR"),
                                        ],
                                      ),
                                      onTap: () {
                                        _showVisitorQRDialog(visitor);
                                      },
                                    ),
                                    PopupMenuItem(
                                      child: const Row(
                                        children: [
                                          Icon(Icons.delete, size: 18),
                                          SizedBox(width: 8),
                                          Text("Revoke"),
                                        ],
                                      ),
                                      onTap: () {
                                        _revokeVisitorQR(visitor['id']);
                                      },
                                    ),
                                  ],
                                  offset: const Offset(0, 36),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVisitorDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final purposeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_add, color: primaryIndigo, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      "Add Visitor",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildVisitorFormField(
                  "Name",
                  nameController,
                  Icons.person,
                  "Visitor name",
                  isRequired: true,
                ),
                const SizedBox(height: 12),
                _buildVisitorFormField(
                  "Phone",
                  phoneController,
                  Icons.phone,
                  "+1-234-567-8900",
                ),
                const SizedBox(height: 12),
                _buildVisitorFormField(
                  "Email",
                  emailController,
                  Icons.email,
                  "visitor@example.com",
                ),
                const SizedBox(height: 12),
                _buildVisitorFormField(
                  "Purpose (Optional)",
                  purposeController,
                  Icons.info,
                  "e.g., Meeting, Delivery",
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: textLight,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) {
                            _showErrorSnackbar("Please enter visitor name");
                            return;
                          }

                          Navigator.pop(context);
                          await _createVisitorQR(
                            nameController.text.trim(),
                            phoneController.text.trim(),
                            emailController.text.trim(),
                            purposeController.text.trim(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryIndigo,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Create QR"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorFormField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    bool isRequired = false,
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
          style: TextStyle(color: textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textLight),
            prefixIcon: Icon(icon, size: 18, color: textLight),
            filled: true,
            fillColor: backgroundColor.withOpacity(
              _theme.isDarkMode ? 0.2 : 0.6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: textLight.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: textLight.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryIndigo.withOpacity(0.6)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Future<void> _createVisitorQR(
    String name,
    String phone,
    String email,
    String purpose,
  ) async {
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
                  Text("Generating QR code..."),
                ],
              ),
            ),
          ),
        ),
      );

      final qrData = await _residentService.createVisitorQR(
        visitorName: name,
        visitorPhone: phone,
        visitorEmail: email,
        visitorPurpose: purpose.isEmpty ? "Visit" : purpose,
      );

      Navigator.pop(context);
      _showSuccessSnackbar("Visitor QR created successfully!");
      setState(() {}); // Refresh the visitor list
      _showVisitorQRDialog({'visitor_name': name, 'qr_data': qrData});
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackbar("Failed to create visitor QR: $e");
    }
  }

  void _showVisitorQRDialog(Map<String, dynamic> visitor) {
    String qrData = visitor['qr_data'] ?? 'visitor_qr_data';
    String visitorName = visitor['visitor_name'] ?? 'Visitor';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code, color: Color(0xFF6366F1), size: 24),
                    SizedBox(width: 8),
                    Text(
                      "Visitor QR Code",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  visitorName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 280,
                  height: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryIndigo, width: 2),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 250.0,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryIndigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Share this QR code with your visitor",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryIndigo,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: textLight.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text("Close", style: TextStyle(color: textDark)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareVisitorQR(qrData, visitorName),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text("Share"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryIndigo,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareVisitorQR(String qrData, String visitorName) async {
    try {
      final shareText =
          '''🔐 VISITOR QR CODE

Visitor: $visitorName

Please scan this QR code at the entrance:
$qrData

---

Instructions:
1. Show this message to the guard
2. Guard will scan the QR code
3. You'll be granted access

KnockLogs - Secure Entry Management''';

      // For mobile: Generate QR code image and share with file
      if (!kIsWeb) {
        try {
          // Generate QR code image
          final qrPainter = QrPainter(
            data: qrData,
            version: QrVersions.auto,
            gapless: true,
          );

          final pictureRecorder = ui.PictureRecorder();
          final canvas = ui.Canvas(
            pictureRecorder,
            Rect.fromLTWH(0, 0, 300, 300),
          );

          // Draw white background
          canvas.drawRect(
            Rect.fromLTWH(0, 0, 300, 300),
            Paint()..color = Colors.white,
          );

          // Draw QR code
          qrPainter.paint(canvas, const Size(300, 300));

          final picture = pictureRecorder.endRecording();
          final image = await picture.toImage(300, 300);
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );

          if (byteData != null) {
            final directory = await getTemporaryDirectory();
            final imagePath =
                '${directory.path}/visitor_qr_${DateTime.now().millisecondsSinceEpoch}.png';
            final imageFile = File(imagePath);

            // Write PNG file
            await imageFile.writeAsBytes(byteData.buffer.asUint8List());

            // Share the file
            await Share.shareXFiles(
              [XFile(imagePath, mimeType: 'image/png')],
              subject: 'Visitor QR Code - $visitorName',
              text: shareText,
            );

            // Clean up
            if (await imageFile.exists()) {
              await imageFile.delete();
            }

            _showSuccessSnackbar("QR code shared successfully!");
            return;
          }
        } catch (e) {
          print("Image generation/share failed: $e");
          // Fall through to text share
        }
      }

      // Fallback: Text-only share (web and mobile if image fails)
      await Share.share(shareText, subject: 'Visitor QR Code - $visitorName');

      _showSuccessSnackbar("QR code shared successfully!");
    } catch (e) {
      _showErrorSnackbar("Error sharing QR: $e");
    }
  }

  Future<void> _revokeVisitorQR(String visitorQrId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Revoke Access"),
        content: const Text("Are you sure you want to revoke this visitor QR?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _residentService.invalidateVisitorQR(visitorQrId);
                Navigator.pop(context);
                _showSuccessSnackbar("Visitor QR revoked successfully!");
                setState(() {}); // Refresh the visitor list
              } catch (e) {
                Navigator.pop(context);
                _showErrorSnackbar("Failed to revoke QR: $e");
              }
            },
            style: TextButton.styleFrom(foregroundColor: dangerRed),
            child: const Text("Revoke"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteHistory(String logId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Delete History"),
        content: const Text("Remove this access log entry?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccessLog(logId);
            },
            style: TextButton.styleFrom(foregroundColor: dangerRed),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Clear History"),
        content: const Text("Remove all access history entries?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAccessLogs();
            },
            style: TextButton.styleFrom(foregroundColor: dangerRed),
            child: const Text("Clear All"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccessLog(String logId) async {
    try {
      await _residentService.deleteAccessLog(logId);
      setState(() {
        _accessLogs.removeWhere((log) => log['id'] == logId);
      });
      _showSuccessSnackbar("History entry deleted");
    } catch (e) {
      _showErrorSnackbar("Failed to delete history: $e");
    }
  }

  Future<void> _clearAccessLogs() async {
    try {
      await _residentService.clearAccessLogs();
      setState(() {
        _accessLogs.clear();
      });
      _showSuccessSnackbar("History cleared");
    } catch (e) {
      _showErrorSnackbar("Failed to clear history: $e");
    }
  }

  Widget _buildAccessHistorySection() {
    final compact = _isCompact;
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
              final logId = log['id']?.toString();
              final timestamp = (log['timestamp'] as Timestamp).toDate();
              final isGranted = log['access_granted'] == true;

              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: compact ? 8 : 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: cardWhite,
                child: Padding(
                  padding: EdgeInsets.all(compact ? 12 : 16),
                  child: Row(
                    children: [
                      Container(
                        width: compact ? 44 : 50,
                        height: compact ? 44 : 50,
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
                              style: TextStyle(fontSize: 12, color: textLight),
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
                                      : const Color(
                                          0xFFEC4899,
                                        ).withOpacity(0.2),
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
                            if (logId != null) ...[
                              const SizedBox(height: 6),
                              IconButton(
                                onPressed: () => _confirmDeleteHistory(logId),
                                icon: const Icon(Icons.delete_outline),
                                color: dangerRed,
                                tooltip: "Delete history",
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
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

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color textColor;
  final Color subTextColor;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: subTextColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: textColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 13, color: subTextColor)),
          ],
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Color textColor;
  final bool compact;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.textColor = Colors.white,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final vertical = compact ? 12.0 : 14.0;
    final fontSize = compact ? 14.0 : 15.0;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: vertical),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: fontSize),
        ),
      ),
    );
  }
}
