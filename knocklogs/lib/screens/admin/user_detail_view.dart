import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';

class UserDetailView extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserDetailView({super.key, required this.user});

  @override
  State<UserDetailView> createState() => _UserDetailViewState();
}

class _UserDetailViewState extends State<UserDetailView> {
  final AdminService _adminService = AdminService();
  late Map<String, dynamic> user;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  void _approveUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Approve User"),
        content: Text("Approve ${user['name']}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _adminService.approveUser(user['id']);
                Navigator.pop(context);
                setState(() {
                  user['status'] = 'approved';
                });
                _showSuccess("User approved successfully");
              } catch (e) {
                Navigator.pop(context);
                _showError("Error approving user: $e");
              }
            },
            child: const Text("Approve", style: TextStyle(color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  void _rejectUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Reject User"),
        content: Text("Reject ${user['name']}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _adminService.rejectUser(user['id']);
                Navigator.pop(context);
                setState(() {
                  user['status'] = 'rejected';
                });
                _showSuccess("User rejected successfully");
              } catch (e) {
                Navigator.pop(context);
                _showError("Error rejecting user: $e");
              }
            },
            child: const Text("Reject", style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _deleteUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Delete User"),
        content: Text("Permanently delete ${user['name']}? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _adminService.deleteUser(user['id']);
                Navigator.pop(context);
                Navigator.pop(context);
                _showSuccess("User deleted successfully");
              } catch (e) {
                Navigator.pop(context);
                _showError("Error deleting user: $e");
              }
            },
            child: const Text("Delete", style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: const Color(0xFFFFFFFF),
        centerTitle: true,
        title: Text(
          user['name'] ?? 'User Details',
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE5E7EB),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserProfileCard(),
            const SizedBox(height: 20),
            _buildInfoSection(),
            const SizedBox(height: 20),
            _buildMetadataSection(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = user['status']?.toString().toLowerCase() ?? 'unknown';
    final isPending = status == 'pending';

    return Column(
      children: [
        if (isPending)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _rejectUser,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text("Reject"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _approveUser,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text("Approve"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        if (!isPending)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _deleteUser,
              icon: const Icon(Icons.delete, size: 18),
              label: const Text("Delete User"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserProfileCard() {
    final role = user['role'] ?? 'unknown';
    final isGuard = role == 'guard';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: isGuard
                ? const Color(0xFF6366F1).withOpacity(0.1)
                : const Color(0xFF06B6D4).withOpacity(0.1),
            child: Icon(
              isGuard ? Icons.security : Icons.home,
              size: 50,
              color: isGuard
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF06B6D4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user['name'] ?? 'Unknown',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isGuard
                  ? const Color(0xFF6366F1).withOpacity(0.1)
                  : const Color(0xFF06B6D4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              role.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isGuard
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF06B6D4),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = user['status'] ?? 'unknown';
    final isApproved = status.toLowerCase() == 'approved';

    return Container(
      decoration: BoxDecoration(
        color: isApproved
            ? const Color(0xFF10B981).withOpacity(0.1)
            : status.toLowerCase() == 'pending'
                ? const Color(0xFFFFD700).withOpacity(0.1)
                : const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isApproved
              ? const Color(0xFF10B981)
              : status.toLowerCase() == 'pending'
                  ? const Color(0xFFB8860B)
                  : const Color(0xFFEF4444),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isApproved
                ? Icons.check_circle
                : status.toLowerCase() == 'pending'
                    ? Icons.schedule
                    : Icons.cancel,
            color: isApproved
                ? const Color(0xFF10B981)
                : status.toLowerCase() == 'pending'
                    ? const Color(0xFFB8860B)
                    : const Color(0xFFEF4444),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isApproved
                  ? const Color(0xFF10B981)
                  : status.toLowerCase() == 'pending'
                      ? const Color(0xFFB8860B)
                      : const Color(0xFFEF4444),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PERSONAL INFORMATION",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B7280),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.email,
          label: "Email",
          value: user['email'] ?? 'N/A',
        ),
        const SizedBox(height: 10),
        _buildInfoCard(
          icon: Icons.phone,
          label: "Phone",
          value: user['phone'] ?? 'N/A',
        ),
        const SizedBox(height: 10),
        if (user['role'] == 'resident')
          _buildInfoCard(
            icon: Icons.home,
            label: "Flat Number",
            value: user['flatNo'] ?? 'N/A',
          ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection() {
    final createdAt = user['createdAt'];
    String formattedDate = 'N/A';

    if (createdAt != null) {
      try {
        final dateTime = createdAt.toDate();
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
      } catch (e) {
        formattedDate = createdAt.toString();
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ACCOUNT INFORMATION",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "User ID",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      user['id']?.substring(0, 8) ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6366F1),
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Registered",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
