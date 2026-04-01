import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../Pages/HomePage.dart';


class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _showImage = false;
  bool _showLogin = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/whirl_bg.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();

        // After 4 seconds show login form
        Timer(Duration(seconds: 3), () {
          setState(() {
            _showLogin = true;
          });
        });

        // After 5 seconds show static image
        Timer(Duration(seconds: 3), () {
          _controller.pause();
          setState(() {
            _showImage = true;
          });
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget _buildLoginForm() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius:  BorderRadius.vertical(top: Radius.circular(45)),
        image: DecorationImage(image: AssetImage("assets/Images/login.png",),
          fit: BoxFit.cover,
          opacity: 0.8,
        ),
      ),

      // BoxDecoration(
      //   color: Colors.white.withOpacity(0.60),
      //   borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      // ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("User Login", style: TextStyle(fontSize: 35, color: Colors.black, fontWeight: FontWeight.w600),),
          SizedBox(height: 30),
          TextField(
            controller: usernameController,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
              hintText: 'Username',
              prefixIcon: Icon(Icons.person),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 25),
          TextField(
            obscureText: _obscure,
            controller: passwordController,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
              hintText: 'Password',
              prefixIcon: Icon(Icons.keyboard),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),

                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 70, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),
            onPressed: () {
              String userName = usernameController.text.trim();
              String password = passwordController.text;
              if (password == "12345"){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Homepage(userName: userName,)));};},

            child: Text('Login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Smooth transition between video and image
          AnimatedSwitcher(
            duration: Duration(milliseconds: 150),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: _showImage
                ? Image.asset(
              'assets/Images/whirl_bg_img.png',
              key: ValueKey('image'),
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            )
                : _controller.value.isInitialized
                ? SizedBox.expand(
              key: ValueKey('video'),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
                : Container(decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage("assets/Images/logo_wcm.png"))
                // image: DecorationImage(image: AssetImage("assets/Images/Splash_logo.png"))
            ) ,), // Prevent white screen
          ),

          // Animated login form
          AnimatedPositioned(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeOut,
            bottom: _showLogin ? 0 : -height * 0.5,
            left: 0,
            right: 0,
            child: _buildLoginForm(),
          ),
        ],
      ),
    );
  }

}
