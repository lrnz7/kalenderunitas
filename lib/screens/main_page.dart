import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'home_page.dart';
import 'admin_page.dart';
import 'login_page.dart';

class MainPage extends StatefulWidget {
  final bool isAdmin;
  final bool disableRealtimeIndicator;

  const MainPage(
      {super.key,
      required this.isAdmin,
      this.disableRealtimeIndicator = false});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  void _logout() async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Navigate to login page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066CC),
              foregroundColor: Colors.white,
            ),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // PAGES BERDASARKAN ROLE
    final List<Widget> pages = [
      CalendarPage(
          isAdmin: widget.isAdmin,
          disableRealtimeIndicator:
              widget.disableRealtimeIndicator), // PASS isAdmin ke CalendarPage
      HomePage(isAdmin: widget.isAdmin), // PASS isAdmin ke HomePage
      if (widget.isAdmin) const AdminPage() else const SizedBox(),
    ];

    return Scaffold(
      appBar: AppBar(
        // Use a full-width title with Stack+Align to create strict 3 zones
        // (left: role badge, center: title, right: logout) so the center
        // title remains absolutely centered regardless of left/right widths.
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              // LEFT: Role badge (anchored)
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Container(
                      key: const Key('topbar_user_info'),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            widget.isAdmin ? Colors.amber[700] : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.isAdmin ? 'ADMIN' : 'USER',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // CENTER: existing title (absolutely centered)
              Align(
                alignment: Alignment.center,
                child: Text(
                  _getAppBarTitle(),
                  key: const Key('topbar_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),

              // RIGHT: Logout button (anchored)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  key: const Key('topbar_logout'),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: _logout,
                  tooltip: 'Logout',
                ),
              ),
            ],
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFF0066CC),
        elevation: 3,
        // Use square corners for all sides to avoid thin white gaps on edges
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        actions: [],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          // Jika user non-admin mencoba akses admin tab, kembalikan ke index 0
          if (!widget.isAdmin && index == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hanya admin yang bisa mengakses fitur ini'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }

          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0066CC),
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Kalender',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Event',
          ),
          BottomNavigationBarItem(
            icon: Icon(
                widget.isAdmin ? Icons.add_circle_outline : Icons.lock_outline),
            label: widget.isAdmin ? 'Tambah Event' : 'Admin Only',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Kalender Unitas';
      case 1:
        return 'Daftar Event';
      case 2:
        return widget.isAdmin ? 'Tambah Event' : 'Access Denied';
      default:
        return 'Kalender Unitas';
    }
  }
}
