import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/admin_service.dart';

import 'user_detail_view.dart';
import '../landing/landing_page.dart';

import '../../widgets/theme_toggle.dart';
import '../auth/login_screen.dart';
import 'admin_palette.dart';
import 'user_detail_view.dart';


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedTab = 0;
  final GlobalKey<_GuardsTabState> _guardsTabKey = GlobalKey();
  final GlobalKey<_ResidentsTabState> _residentsTabKey = GlobalKey();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: _buildAppBar(palette),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          const PendingRequestsTab(),
          GuardsTab(key: _guardsTabKey),
          ResidentsTab(key: _residentsTabKey),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(palette),
    );
  }

  PreferredSizeWidget _buildAppBar(AdminPalette palette) {
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: palette.surface,
      foregroundColor: palette.text,
      elevation: 0,
      toolbarHeight: 72,
      titleSpacing: 20,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.shield_moon, color: palette.primary),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'KnockLogs Admin',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Community operations dashboard',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        const ThemeToggleButton(compact: true),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Refresh overview',
          onPressed: () => setState(() {}),
          icon: Icon(Icons.refresh, color: palette.textSecondary),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: _showProfilePanel,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            foregroundColor: palette.text,
            backgroundColor: palette.muted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          icon: const Icon(Icons.person_outline),
          label: const Text('Profile'),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBottomNav(AdminPalette palette) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        indicatorColor: palette.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w600, color: palette.text),
        ),
      ),
      child: NavigationBar(
        backgroundColor: palette.surface,
        elevation: 10,
        height: 74,
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() => _selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.security_outlined),
            selectedIcon: Icon(Icons.security),
            label: 'Guards',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Residents',
          ),
        ],
      ),
    );
  }

  void _showProfilePanel() {
    final user = _auth.currentUser;
    showGeneralDialog(
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
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: Color(0xFFEF4444)),

      barrierDismissible: true,
      barrierLabel: 'Profile panel',
      barrierColor: Colors.black54,
      pageBuilder: (overlayContext, animation, secondaryAnimation) {
        final palette = AdminPalette.of(overlayContext);
        final width = MediaQuery.of(overlayContext).size.width;
        final panelWidth = width > 520 ? 380.0 : width * 0.9;

        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: panelWidth,
              height: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: user == null
                    ? _buildProfileEmpty(palette, overlayContext)
                    : FutureBuilder<Map<String, dynamic>?>(
                        future: _adminService.getUserProfile(user.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildProfileLoading(palette);
                          }
                          if (snapshot.hasError) {
                            return _buildProfileError(
                              palette,
                              snapshot.error.toString(),
                              overlayContext,
                            );
                          }

                          final data = snapshot.data ?? {};
                          final name =
                              (data['name'] ?? user.displayName ?? 'Admin')
                                  .toString();
                          final email =
                              (data['email'] ?? user.email ?? 'No email')
                                  .toString();
                          final phone = (data['phone'] ?? '').toString();
                          final role = (data['role'] ?? 'admin').toString();
                          final status = (data['status'] ?? 'active')
                              .toString();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: palette.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    child: Text(
                                      _initials(name),
                                      style: TextStyle(
                                        color: palette.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            color: palette.text,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          email,
                                          style: TextStyle(
                                            color: palette.textSecondary,
                                          ),
                                        ),
                                        if (phone.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            phone,
                                            style: TextStyle(
                                              color: palette.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _buildChip(
                                    palette,
                                    label: role.toUpperCase(),
                                    color: palette.primary,
                                  ),
                                  _buildChip(
                                    palette,
                                    label: status.toUpperCase(),
                                    color: status == 'approved'
                                        ? palette.success
                                        : palette.warning,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => _showEditProfileDialog(
                                  palette,
                                  name: name,
                                  phone: phone,
                                ),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit profile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: palette.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          Navigator.pop(overlayContext),
                                      icon: const Icon(Icons.close),
                                      label: const Text('Close'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: palette.textSecondary,
                                        side: BorderSide(color: palette.border),
                                        minimumSize: const Size.fromHeight(46),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(overlayContext);
                                        _confirmLogout();
                                      },
                                      icon: const Icon(Icons.logout),
                                      label: const Text('Logout'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: palette.danger,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(46),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
              ),

            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    );
  }

  Future<void> _showEditProfileDialog(
    AdminPalette palette, {
    required String name,
    required String phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final nameController = TextEditingController(text: name);
    final phoneController = TextEditingController(text: phone);
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Edit profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          try {
                            await _adminService.updateUserProfile(user.uid, {
                              'name': nameController.text.trim(),
                              'phone': phoneController.text.trim(),
                            });
                            if (!mounted) return;
                            Navigator.pop(dialogContext);
                            setState(() {});
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: const Text('Profile updated'),
                                backgroundColor: palette.success,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating profile: $e'),
                                backgroundColor: palette.danger,
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
  }

  Widget _buildProfileEmpty(AdminPalette palette, BuildContext overlayContext) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person_off, size: 48, color: palette.textSecondary),
        const SizedBox(height: 12),
        Text('No active admin session', style: TextStyle(color: palette.text)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => Navigator.pop(overlayContext),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildProfileLoading(AdminPalette palette) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircularProgressIndicator(color: palette.primary),
          const SizedBox(width: 12),
          Text(
            'Loading profile...',
            style: TextStyle(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileError(
    AdminPalette palette,
    String message,
    BuildContext overlayContext,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 42, color: palette.danger),
        const SizedBox(height: 12),
        Text(
          'Failed to load profile',
          style: TextStyle(color: palette.text, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(overlayContext),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildChip(
    AdminPalette palette, {
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final palette = AdminPalette.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _auth.signOut();
                if (!mounted) return;
                Navigator.pop(dialogContext);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: Text('Logout', style: TextStyle(color: palette.danger)),
            ),
          ],
        );
      },
    );
  }
}

class PendingRequestsTab extends StatefulWidget {
  const PendingRequestsTab({super.key});

  @override
  State<PendingRequestsTab> createState() => _PendingRequestsTabState();
}

class _PendingRequestsTabState extends State<PendingRequestsTab> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;
  String? _loadError;
  int? _approvedResidents;
  int? _approvedGuards;
  int? _pendingCount;
  int? _visitorsToday;
  List<int>? _visitorWeek;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final pendingRequests = await _adminService.getPendingRequests();
      final approvedResidents = await _adminService.getApprovedResidentsCount();
      final approvedGuards = await _adminService.getApprovedGuardsCount();
      final pendingCount = await _adminService.getPendingRequestsCount();
      final visitorsToday = await _adminService.getVisitorsTodayCount();
      final visitorWeek = await _adminService.getVisitorEntriesLast7Days();

      setState(() {
        _pendingRequests = pendingRequests;
        _approvedResidents = approvedResidents;
        _approvedGuards = approvedGuards;
        _pendingCount = pendingCount;
        _visitorsToday = visitorsToday;
        _visitorWeek = visitorWeek;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  void _approveUser(String userId, String name) {
    showDialog(
      context: context,
      builder: (context) {
        final palette = AdminPalette.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("Approve Request"),
          content: Text("Approve $name?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _adminService.approveUser(userId);
                  Navigator.pop(context);
                  await _refreshAll();
                  _showSuccess("User approved successfully", palette);
                } catch (e) {
                  Navigator.pop(context);
                  _showError("Error approving user: $e", palette);
                }
              },
              child: Text("Approve", style: TextStyle(color: palette.success)),
            ),
          ],
        );
      },
    );
  }

  void _rejectUser(String userId, String name) {
    showDialog(
      context: context,
      builder: (context) {
        final palette = AdminPalette.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("Reject Request"),
          content: Text("Reject $name?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _adminService.rejectUser(userId);
                  Navigator.pop(context);
                  await _refreshAll();
                  _showSuccess("User rejected successfully", palette);
                } catch (e) {
                  Navigator.pop(context);
                  _showError("Error rejecting user: $e", palette);
                }
              },
              child: Text("Reject", style: TextStyle(color: palette.danger)),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message, AdminPalette palette) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: palette.danger),
    );
  }

  void _showSuccess(String message, AdminPalette palette) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: palette.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: palette.primary));
    }

    if (_loadError != null) {
      return _buildErrorState(
        palette,
        title: "Couldn't load admin dashboard",
        message: _loadError!,
        onRetry: _refreshAll,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(
            palette,
            title: "Pending approvals",
            subtitle: "Review and approve new account requests.",
            badgeText: "${_pendingRequests.length} requests",
          ),
          const SizedBox(height: 12),
          if (_pendingRequests.isEmpty)
            _buildEmptyState(
              palette,
              "No pending requests",
              "You're all caught up. New requests will appear here.",
              Icons.inbox,
            )
          else
            ..._pendingRequests.map(_buildRequestCard),
          const SizedBox(height: 20),
          _buildKpiGrid(palette),
          const SizedBox(height: 16),
          _buildAnalyticsCard(palette),
          const SizedBox(height: 16),
          _buildActivityFeed(palette),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    AdminPalette palette, {
    required String title,
    required String subtitle,
    String? badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(Icons.pending_actions, color: palette.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: palette.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (badgeText != null)
            Container(
              decoration: BoxDecoration(
                color: palette.muted,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final palette = AdminPalette.of(context);
    final role = request['role'] ?? 'unknown';
    final isGuard = role == 'guard';
    final roleColor = isGuard ? palette.primary : palette.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: palette.warning.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    isGuard ? Icons.security : Icons.home,
                    color: roleColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['name'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request['email'] ?? 'No email',
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.textSecondary,
                        ),
                      ),
                      if (!isGuard)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Flat: ${request['flatNo'] ?? 'N/A'}",
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: palette.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: palette.warning,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _rejectUser(request['id'], request['name']),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("Reject"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _approveUser(request['id'], request['name']),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
    );
  }

  Widget _buildKpiGrid(AdminPalette palette) {
    final kpis = [
      _KpiData(
        label: "Approved residents",
        value: _approvedResidents?.toString() ?? "—",
        icon: Icons.home,
        color: palette.accent,
      ),
      _KpiData(
        label: "Active guards",
        value: _approvedGuards?.toString() ?? "—",
        icon: Icons.security,
        color: palette.primary,
      ),
      _KpiData(
        label: "Pending requests",
        value: _pendingCount?.toString() ?? "—",
        icon: Icons.pending_actions,
        color: palette.warning,
      ),
      _KpiData(
        label: "Visitors today",
        value: _visitorsToday?.toString() ?? "—",
        icon: Icons.directions_walk,
        color: palette.success,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: kpis
          .map((kpi) => _buildKpiCard(palette, kpi))
          .toList(growable: false),
    );
  }

  Widget _buildKpiCard(AdminPalette palette, _KpiData kpi) {
    return Container(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  kpi.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: kpi.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(kpi.icon, color: kpi.color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            kpi.value,
            style: TextStyle(
              color: palette.text,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(AdminPalette palette) {
    final week = _visitorWeek;
    final maxValue = (week == null || week.isEmpty)
        ? 1
        : week.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Visitor analytics",
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Last 7 days entry volume",
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: palette.muted,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  "Weekly",
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final value = week == null ? 0 : week[index];
              final ratio = value / maxValue;
              final height = 20 + (ratio * 80);
              final labels = const ["M", "T", "W", "T", "F", "S", "S"];
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            palette.primary,
                            palette.primary.withValues(alpha: 0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels[index],
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    if (week != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${week[index]}',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed(AdminPalette palette) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.getRecentActivityStream(limit: 8),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                CircularProgressIndicator(color: palette.primary),
                const SizedBox(width: 12),
                Text(
                  "Loading recent activity...",
                  style: TextStyle(color: palette.textSecondary),
                ),
              ],
            ),
          );
        }

        final activities = snapshot.data ?? [];
        if (activities.isEmpty) {
          return _buildEmptyState(
            palette,
            "No recent activity",
            "Guard scan events will appear here.",
            Icons.history,
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Live activity feed",
                style: TextStyle(
                  color: palette.text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Latest guard scans and access decisions",
                style: TextStyle(color: palette.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ...activities.map(
                (activity) => _buildActivityRow(palette, activity),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityRow(
    AdminPalette palette,
    Map<String, dynamic> activity,
  ) {
    final entryType = (activity['entry_type'] ?? 'scan').toString();
    final accessGranted = activity['access_granted'] == true;
    final residentName = activity['resident_name']?.toString() ?? 'Resident';
    final visitorName = activity['visitor_name']?.toString();
    final reason =
        activity['reason']?.toString() ?? activity['denial_reason']?.toString();
    final title = _activityTitle(entryType, accessGranted, visitorName);
    final subtitle = _activitySubtitle(residentName, visitorName, reason);
    final timestamp = activity['timestamp'];
    final timeText = _formatTimestamp(timestamp);
    final color = accessGranted ? palette.success : palette.danger;
    final icon = accessGranted ? Icons.check_circle : Icons.cancel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: palette.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            timeText,
            style: TextStyle(color: palette.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _activityTitle(
    String entryType,
    bool accessGranted,
    String? visitorName,
  ) {
    if (entryType.toUpperCase().contains('VISITOR')) {
      return accessGranted ? "Visitor entry approved" : "Visitor entry denied";
    }
    return accessGranted
        ? "Resident access approved"
        : "Resident access denied";
  }

  String _activitySubtitle(
    String residentName,
    String? visitorName,
    String? reason,
  ) {
    final subject = visitorName == null
        ? residentName
        : "$visitorName visiting $residentName";
    if (reason != null && reason.isNotEmpty) {
      return "$subject • $reason";
    }
    return subject;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    }
    return "--:--";
  }

  Widget _buildErrorState(
    AdminPalette palette, {
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 42, color: palette.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.text,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    AdminPalette palette,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: palette.textSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: palette.text,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _KpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class GuardsTab extends StatefulWidget {
  const GuardsTab({super.key});

  @override
  State<GuardsTab> createState() => _GuardsTabState();
}

class _GuardsTabState extends State<GuardsTab> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _guards = [];
  List<Map<String, dynamic>> _filteredGuards = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGuards();
    _searchController.addListener(_filterGuards);
  }

  void _loadGuards() async {
    try {
      final guards = await _adminService.getAllGuards();
      setState(() {
        _guards = guards;
        _filteredGuards = guards;
      });
    } catch (e) {
      _showError("Error loading guards: $e");
    }
  }

  void _filterGuards() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGuards = _guards.where((guard) {
        final name = guard['name'].toString().toLowerCase();
        final email = guard['email'].toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  void _deleteGuard(String guardId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Delete Guard"),
        content: Text("Are you sure you want to delete $name?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _adminService.deleteUser(guardId);
                Navigator.pop(context);
                _loadGuards();
                _showSuccess("Guard deleted successfully");
              } catch (e) {
                Navigator.pop(context);
                _showError("Error deleting guard: $e");
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    final palette = AdminPalette.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: palette.danger),
    );
  }

  void _showSuccess(String message) {
    final palette = AdminPalette.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: palette.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    return Column(
      children: [
        _buildSearchBar(palette),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _loadGuards();
            },
            child: _filteredGuards.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height - 200,
                        child: _buildEmptyState(
                          palette,
                          "No guards found",
                          Icons.person_off,
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredGuards.length,
                    itemBuilder: (context, index) {
                      final guard = _filteredGuards[index];
                      return _buildUserCard(palette, guard);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(AdminPalette palette) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border, width: 1.5),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: palette.text),
        decoration: InputDecoration(
          hintText: "Search guards...",
          hintStyle: TextStyle(color: palette.textSecondary),
          prefixIcon: Icon(Icons.search, color: palette.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildUserCard(AdminPalette palette, Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: palette.primary.withValues(alpha: 0.1),
          child: Icon(Icons.security, color: palette.primary),
        ),
        title: Text(
          user['name'] ?? 'Unknown',
          style: TextStyle(
            color: palette.text,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          user['email'] ?? 'No email',
          style: TextStyle(color: palette.textSecondary, fontSize: 13),
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text("View Details"),
              onTap: () {
                Future.delayed(
                  const Duration(milliseconds: 300),
                  () => _showUserDetails(user),
                );
              },
            ),
            PopupMenuItem(
              child: Text("Delete", style: TextStyle(color: palette.danger)),
              onTap: () {
                Future.delayed(
                  const Duration(milliseconds: 300),
                  () => _deleteGuard(user['id'], user['name']),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserDetailView(user: user)),
    );
  }

  Widget _buildEmptyState(AdminPalette palette, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: palette.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class ResidentsTab extends StatefulWidget {
  const ResidentsTab({super.key});

  @override
  State<ResidentsTab> createState() => _ResidentsTabState();
}

class _ResidentsTabState extends State<ResidentsTab> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _residents = [];
  List<Map<String, dynamic>> _filteredResidents = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadResidents();
    _searchController.addListener(_filterResidents);
  }

  void _loadResidents() async {
    try {
      final residents = await _adminService.getAllResidents();
      setState(() {
        _residents = residents;
        _filteredResidents = residents;
      });
    } catch (e) {
      _showError("Error loading residents: $e");
    }
  }

  void _filterResidents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredResidents = _residents.where((resident) {
        final name = resident['name'].toString().toLowerCase();
        final email = resident['email'].toString().toLowerCase();
        final flatNo = resident['flatNo'].toString().toLowerCase();
        return name.contains(query) ||
            email.contains(query) ||
            flatNo.contains(query);
      }).toList();
    });
  }

  void _deleteResident(String residentId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Delete Resident"),
        content: Text("Are you sure you want to delete $name?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _adminService.deleteUser(residentId);
                Navigator.pop(context);
                _loadResidents();
                _showSuccess("Resident deleted successfully");
              } catch (e) {
                Navigator.pop(context);
                _showError("Error deleting resident: $e");
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    final palette = AdminPalette.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: palette.danger),
    );
  }

  void _showSuccess(String message) {
    final palette = AdminPalette.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: palette.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    return Column(
      children: [
        _buildSearchBar(palette),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _loadResidents();
            },
            child: _filteredResidents.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height - 200,
                        child: _buildEmptyState(
                          palette,
                          "No residents found",
                          Icons.person_off,
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredResidents.length,
                    itemBuilder: (context, index) {
                      final resident = _filteredResidents[index];
                      return _buildUserCard(palette, resident);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(AdminPalette palette) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border, width: 1.5),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: palette.text),
        decoration: InputDecoration(
          hintText: "Search residents...",
          hintStyle: TextStyle(color: palette.textSecondary),
          prefixIcon: Icon(Icons.search, color: palette.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildUserCard(AdminPalette palette, Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: palette.accent.withValues(alpha: 0.1),
          child: Icon(Icons.home, color: palette.accent),
        ),
        title: Text(
          user['name'] ?? 'Unknown',
          style: TextStyle(
            color: palette.text,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              user['email'] ?? 'No email',
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              "Phone: ${user['phone'] ?? 'N/A'}",
              style: TextStyle(color: palette.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              "Flat: ${user['flatNo'] ?? 'N/A'}",
              style: TextStyle(color: palette.textSecondary, fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text("View Details"),
              onTap: () {
                Future.delayed(
                  const Duration(milliseconds: 300),
                  () => _showUserDetails(user),
                );
              },
            ),
            PopupMenuItem(
              child: Text("Delete", style: TextStyle(color: palette.danger)),
              onTap: () {
                Future.delayed(
                  const Duration(milliseconds: 300),
                  () => _deleteResident(user['id'], user['name']),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserDetailView(user: user)),
    );
  }

  Widget _buildEmptyState(AdminPalette palette, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: palette.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
