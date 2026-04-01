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


class Item {
  final String name;
  final IconData icon;
  Item({required this.name, required this.icon});
}

class Homepage extends StatelessWidget {
  Homepage({required this.userName});
  String userName;
  final List<Item> items = [
    Item(name: 'Mechanical', icon: Icons.engineering),
    Item(name: 'Software', icon: Icons.code),
    Item(name: 'NVH', icon: Icons.precision_manufacturing_outlined),
    Item(name: 'Reliability', icon: Icons.verified_user_rounded),
    Item(name: 'Packing', icon: Icons.inventory_2),
    Item(name: 'Wash Performance', icon: Icons.local_laundry_service),
  ];


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Departments',
      home: HomePage(items: items, userName: userName,),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  final List<Item> items;
  final String userName;

  HomePage({required this.items, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState(userName: userName);
}

class _HomePageState extends State<HomePage> {
  _HomePageState({required this.userName});
  String userName ;
  int _selectedIndex = 0;

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      _onSearchIconTapped(); // You must define this function
    }
  }
  void _onSearchIconTapped() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text("Search UI here"),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth * 0.05;
    return SafeArea(
      child: Scaffold(
        // drawer: Drawer(
        //   backgroundColor: Colors.white,
        //   child:  ListView(
        //     padding: EdgeInsets.zero,
        //     children: <Widget>[
        //       UserAccountsDrawerHeader(accountName: Text("$userName"), accountEmail: Text(''),
        //         decoration: BoxDecoration(
        //             gradient: LinearGradient(colors: [c1,c2],                begin: Alignment.topCenter,
        //               end: Alignment.bottomCenter,)
        //         ),
        //         currentAccountPicture: CircleAvatar(
        //           backgroundColor: Colors.blueGrey,
        //           child: Text(
        //             'A',
        //             style: TextStyle(fontSize: 40.0, color: Colors.white),
        //
        //           ),
        //         ),),
        //       ListTile(
        //         leading: Icon(Icons.logout, color: Colors.red),
        //         title: Text('Logout', style: TextStyle(color: Colors.black)),
        //         onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context)=> LoginPage()));},
        //       ),
        //     ],
        //   ),
        // ),

        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: AppBar(
            leading: IconButton(onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=> LoginPage()));
            }, icon: Icon(Icons.logout, color: Colors.red),),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c1,c2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),),
            iconTheme: IconThemeData(color: Colors.white),
            backgroundColor: Colors.black,
            elevation: 0,
            centerTitle: true,
            title: Text("Departments",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,)
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationPage()),
                  );
                },
              ),
            ],

          ),
        ),
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [c1, c2])),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Carousel Slider
                  // CarouselScreen(),

                  const SizedBox(height: 10),

                  // 🔹 GridView
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(), // Prevent scroll conflict
                    itemCount: widget.items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                                Icon(widget.items[index].icon, size: 65, color: Colors.white),
                                SizedBox(height: 8),
                                Text(
                                  widget.items[index].name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: fontSize, color: Colors.white),
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

class DepartmentLoginPage extends StatefulWidget {
  final IconData icon;
  final int departmentIndex;

  DepartmentLoginPage({required this.icon, required this.departmentIndex});

  @override
  State<DepartmentLoginPage> createState() => _DepartmentLoginPageState();
}

class _DepartmentLoginPageState extends State<DepartmentLoginPage> {
  bool _obscure = true;
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  void navigateToDepartment(BuildContext context, int index, String email, String password, bool isAdmin) {
    // Here you can store email and password for further use if needed
    print("Email: $email, Password: $password");

    Widget destination;
    switch (index) {
      case 0:
        destination = MechanicalDpt(isAdmin: isAdmin,);
        break;
      case 1:
        destination = SoftwareSheet(isAdmin: isAdmin);
        break;
      case 2:
        destination = NVH_Sheet(isAdmin: isAdmin,);
        break;
      case 3:
        destination = ReliabilitySheetPage(isAdmin: isAdmin,);
        break;
      case 4:
        destination = PackingSheetPage(isAdmin: isAdmin,);
        break;
      case 5:
        destination = WashSheetPage(isAdmin: isAdmin,);
        break;
      default:
        destination = Scaffold(
          appBar: AppBar(title: Text("Unknown Department")),
          body: Center(child: Text("No page found for this department.")),
        );
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Allow keyboard to push UI up
      // (You can also remove this line entirely)
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
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), // optional
            child: Center(
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                  Icon(widget.icon, size: 150, color: Colors.white),
                  SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Log-In",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 30),
                        TextField(
                          controller: emailController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            hintText: 'Email',
                            hintStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.email, color: Colors.white),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: passwordController,
                          obscureText: _obscure,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            hintText: 'Password',
                            hintStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.lock, color: Colors.white),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscure = !_obscure),color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                            // ✅ Get values and call function
                            String email = emailController.text.trim();
                            String password = passwordController.text;
                            bool isAdmin = email == "Admin" && password == "12345";
                            bool isNotAdmin = email == "User" && password == "12345";
                            if (isAdmin) {
                              navigateToDepartment(context, widget.departmentIndex, email, password, isAdmin);
                            }
                            else if(isNotAdmin){
                              navigateToDepartment(context, widget.departmentIndex, email, password, isAdmin);
                            }

                            // navigateToDepartment(context, departmentIndex, email, password, isAdmin);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueAccent,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text("Login", style: TextStyle(fontSize: 22)),
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

// notification code

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
      'image': null
    }
  ];

  bool isAdmin = true; // Replace with real user role check
  File? selectedImage;

  void _showAddNotificationDialog() async {
    String title = '';
    String subtitle = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Notification'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: (value) => title = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Subtitle'),
                onChanged: (value) => subtitle = value,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() => selectedImage = File(picked.path));
                  }
                },
                icon: const Icon(Icons.image),
                label: const Text("Pick Image"),
              ),
              if (selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.file(selectedImage!, height: 100),
                )
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              selectedImage = null;
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
              Navigator.pop(context);
            },
            child: const Text("Post"),
          ),
        ],
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
        title: const Text('Notifications',
            style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: _showAddNotificationDialog,
      )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [c1, c2]),
        ),
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
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const Icon(Icons.notifications, color: Colors.white),
                title: Text(item['title'] ?? '',
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(item['subtitle'] ?? '',
                    style: const TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                onTap: () {},
                // Optional image display
                isThreeLine: item['image'] != null,
                subtitleTextStyle: const TextStyle(color: Colors.white70),
              ),
            );
          },
        ),
      ),
    );
  }
}



