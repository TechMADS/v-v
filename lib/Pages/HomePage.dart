import 'package:flutter/material.dart';
import 'package:v_v/Colors/Colors.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:v_v/Sheets/Mechanical_Sheet.dart';
import 'package:v_v/Sheets/NVHSheet.dart';
import 'package:v_v/Sheets/PackingSheet.dart';
import 'package:v_v/Sheets/ReliabilitySheet.dart';
import 'package:v_v/Sheets/SoftwareSheet.dart';
import 'package:v_v/Sheets/Wash_Performance_Sheet.dart';
import '../Login/LoginPage.dart';

// ─────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────

class Item {
  final String name;
  final IconData icon;
  Item({required this.name, required this.icon});
}

// ─────────────────────────────────────────────
// HOMEPAGE  (was wrongly wrapping MaterialApp)
// ─────────────────────────────────────────────

class Homepage extends StatelessWidget {
  final String userName;
  const Homepage({super.key, required this.userName});

  static final List<Item> items = [
    Item(name: 'Mechanical', icon: Icons.engineering),
    Item(name: 'Software', icon: Icons.code),
    Item(name: 'NVH', icon: Icons.precision_manufacturing_outlined),
    Item(name: 'Reliability', icon: Icons.verified_user_rounded),
    Item(name: 'Packing', icon: Icons.inventory_2),
    Item(name: 'Wash Performance', icon: Icons.local_laundry_service),
  ];

  @override
  Widget build(BuildContext context) {
    // ✅ No MaterialApp here — we're already inside one from main.dart
    return HomePage(items: items, userName: userName);
  }
}

// ─────────────────────────────────────────────
// HOME PAGE (stateful)
// ─────────────────────────────────────────────

class HomePage extends StatefulWidget {
  final List<Item> items;
  final String userName;

  const HomePage({super.key, required this.items, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ✅ Access userName via widget.userName — never pass it into State constructor

  void _onSearchIconTapped() {
    showModalBottomSheet(
      context: context,
      builder: (_) => const Padding(
        padding: EdgeInsets.all(16),
        child: Text("Search UI here"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth * 0.05;

    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: AppBar(
            leading: IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.red),
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c1, c2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: Colors.black,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              "Departments",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationPage()),
                  );
                },
              ),
            ],
          ),
        ),
        body: Container(
          height: double.infinity,
          decoration:
          BoxDecoration(gradient: LinearGradient(colors: [c1, c2])),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.items.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 25,
                      mainAxisSpacing: 25,
                    ),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DepartmentLoginPage(
                                icon: widget.items[index].icon,
                                departmentIndex: index,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [c2, c1]),
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(widget.items[index].icon,
                                    size: 65, color: Colors.white),
                                const SizedBox(height: 8),
                                Text(
                                  widget.items[index].name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: fontSize,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DEPARTMENT LOGIN PAGE
// ─────────────────────────────────────────────

class DepartmentLoginPage extends StatefulWidget {
  final IconData icon;
  final int departmentIndex;

  const DepartmentLoginPage(
      {super.key, required this.icon, required this.departmentIndex});

  @override
  State<DepartmentLoginPage> createState() => _DepartmentLoginPageState();
}

class _DepartmentLoginPageState extends State<DepartmentLoginPage> {
  bool _obscure = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // ✅ Always dispose controllers
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _navigateToDepartment(
      BuildContext context, int index, bool isAdmin) {
    Widget destination;
    switch (index) {
      case 0:
        destination = MechanicalDpt(isAdmin: isAdmin);
        break;
      case 1:
        destination = SoftwareSheet(isAdmin: isAdmin);
        break;
      case 2:
        destination = NVH_Sheet(isAdmin: isAdmin);
        break;
      case 3:
        destination = ReliabilitySheetPage(isAdmin: isAdmin);
        break;
      case 4:
        destination = PackingSheetPage(isAdmin: isAdmin);
        break;
      case 5:
        destination = WashSheetPage(isAdmin: isAdmin);
        break;
      default:
        destination = Scaffold(
          appBar: AppBar(title: const Text("Unknown Department")),
          body: const Center(
              child: Text("No page found for this department.")),
        );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        height: double.maxFinite,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Center(
              child: Column(
                children: [
                  SizedBox(
                      height:
                      MediaQuery.of(context).size.height * 0.15),
                  Icon(widget.icon, size: 150, color: Colors.white),
                  const SizedBox(height: 30),
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Log-In",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 35,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 30),
                        TextField(
                          controller: emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            hintText: 'Email',
                            hintStyle:
                            const TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.email,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: passwordController,
                          obscureText: _obscure,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            hintText: 'Password',
                            hintStyle:
                            const TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.lock,
                                color: Colors.white),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              color: Colors.white,
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                            final email = emailController.text.trim();
                            final password = passwordController.text;
                            final isAdmin =
                                email == "Admin" && password == "12345";
                            final isUser =
                                email == "User" && password == "12345";

                            if (isAdmin || isUser) {
                              _navigateToDepartment(context,
                                  widget.departmentIndex, isAdmin);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                    Text('Invalid credentials')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Login",
                              style: TextStyle(fontSize: 22)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NOTIFICATION PAGE
// ─────────────────────────────────────────────

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'Sample Notification',
      'subtitle': 'Sub-informations..........',
      'image': null,
    }
  ];

  bool isAdmin = true;
  File? selectedImage;

  void _showAddNotificationDialog() async {
    String title = '';
    String subtitle = '';
    // Reset before dialog opens
    selectedImage = null;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        // ✅ Use StatefulBuilder so image preview updates inside dialog
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add Notification'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration:
                  const InputDecoration(labelText: 'Title'),
                  onChanged: (v) => title = v,
                ),
                TextField(
                  decoration:
                  const InputDecoration(labelText: 'Subtitle'),
                  onChanged: (v) => subtitle = v,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                        source: ImageSource.gallery);
                    if (picked != null) {
                      setDialogState(() =>
                      selectedImage = File(picked.path));
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text("Pick Image"),
                ),
                if (selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Image.file(selectedImage!, height: 100),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                selectedImage = null;
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (title.isNotEmpty) {
                  setState(() {
                    notifications.insert(0, {
                      'title': title,
                      'subtitle': subtitle,
                      'image': selectedImage,
                    });
                  });
                }
                selectedImage = null;
                Navigator.pop(dialogContext);
              },
              child: const Text("Post"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [c1, c2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _showAddNotificationDialog,
        child: const Icon(Icons.add),
      )
          : null,
      body: Container(
        decoration:
        const BoxDecoration(gradient: LinearGradient(colors: [c1, c2])),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final item = notifications[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white10,
                border: Border.all(color: Colors.white, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: const Icon(Icons.notifications,
                        color: Colors.white),
                    title: Text(item['title'] ?? '',
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(item['subtitle'] ?? '',
                        style:
                        const TextStyle(color: Colors.white70)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.white),
                  ),
                  // ✅ Show image below the tile if it exists
                  if (item['image'] != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(item['image'] as File,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}