import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
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

  // Light theme colors
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
  static const Color borderGray = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          const PendingRequestsTab(),
          GuardsTab(key: _guardsTabKey),
          ResidentsTab(key: _residentsTabKey),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
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
          Icon(Icons.admin_panel_settings, size: 28, color: primaryIndigo),
          const SizedBox(width: 12),
          Text(
            "ADMIN PANEL",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textDark,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: borderGray,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        border: Border(
          top: BorderSide(color: borderGray, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: cardWhite,
        selectedItemColor: primaryIndigo,
        unselectedItemColor: textLight,
        currentIndex: _selectedTab,
        onTap: (index) {
          setState(() => _selectedTab = index);
          // Refresh the lists when switching tabs
          if (index == 1) {
            _guardsTabKey.currentState?._loadGuards();
          } else if (index == 2) {
            _residentsTabKey.currentState?._loadResidents();
          }
        },
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions),
            label: "Pending",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: "Guards",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Residents",
          ),
        ],
      ),
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

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  void _loadPendingRequests() async {
    try {
      final requests = await _adminService.getPendingRequests();
      setState(() {
        _pendingRequests = requests;
      });
    } catch (e) {
      _showError("Error loading pending requests: $e");
    }
  }

  void _approveUser(String userId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                _loadPendingRequests();
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

  void _rejectUser(String userId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                _loadPendingRequests();
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
    return _pendingRequests.isEmpty
        ? _buildEmptyState("No pending requests", Icons.inbox)
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _pendingRequests.length,
            itemBuilder: (context, index) {
              final request = _pendingRequests[index];
              return _buildRequestCard(request);
            },
          );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final role = request['role'] ?? 'unknown';
    final isGuard = role == 'guard';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                    color: isGuard
                        ? const Color(0xFF6366F1).withOpacity(0.1)
                        : const Color(0xFF06B6D4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    isGuard ? Icons.security : Icons.home,
                    color: isGuard
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF06B6D4),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request['email'] ?? 'No email',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      if (!isGuard)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Flat: ${request['flatNo'] ?? 'N/A'}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB8860B),
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
                    onPressed: () => _rejectUser(request['id'], request['name']),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("Reject"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
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
                    onPressed: () => _approveUser(request['id'], request['name']),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
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

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: const Color(0xFF6B7280).withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
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
    return Column(
      children: [
        _buildSearchBar(),
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
                        child: _buildEmptyState("No guards found", Icons.person_off),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredGuards.length,
                    itemBuilder: (context, index) {
                      final guard = _filteredGuards[index];
                      return _buildUserCard(guard);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Color(0xFF1F2937)),
        decoration: InputDecoration(
          hintText: "Search guards...",
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
          child: const Icon(
            Icons.security,
            color: Color(0xFF6366F1),
          ),
        ),
        title: Text(
          user['name'] ?? 'Unknown',
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          user['email'] ?? 'No email',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
          ),
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
              child: const Text("Delete", style: TextStyle(color: Color(0xFFEF4444))),
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
      MaterialPageRoute(
        builder: (context) => UserDetailView(user: user),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: const Color(0xFF6B7280).withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF6B7280),
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
    return Column(
      children: [
        _buildSearchBar(),
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
                        child: _buildEmptyState("No residents found", Icons.person_off),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredResidents.length,
                    itemBuilder: (context, index) {
                      final resident = _filteredResidents[index];
                      return _buildUserCard(resident);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Color(0xFF1F2937)),
        decoration: InputDecoration(
          hintText: "Search residents...",
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF06B6D4).withOpacity(0.1),
          child: const Icon(
            Icons.home,
            color: Color(0xFF06B6D4),
          ),
        ),
        title: Text(
          user['name'] ?? 'Unknown',
          style: const TextStyle(
            color: Color(0xFF1F2937),
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
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Phone: ${user['phone'] ?? 'N/A'}",
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Flat: ${user['flatNo'] ?? 'N/A'}",
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
              ),
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
              child: const Text("Delete", style: TextStyle(color: Color(0xFFEF4444))),
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
      MaterialPageRoute(
        builder: (context) => UserDetailView(user: user),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: const Color(0xFF6B7280).withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF6B7280),
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
