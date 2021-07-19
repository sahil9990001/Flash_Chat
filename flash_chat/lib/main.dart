import 'package:firebase_core/firebase_core.dart';
import 'package:flash_chat/Utils/shared_pref.dart';
import 'package:flash_chat/screens/chat.dart';
import 'package:flash_chat/screens/welcome.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SharedPref.prefs = await SharedPreferences.getInstance();
  runApp(FlashChat());
}

class FlashChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: TextTheme(
          body1: TextStyle(color: Colors.black54),
        ),
      ),
      home: SharedPref.prefs.getBool('LoggedIn') == true
          ? ChatScreen()
          : WelcomeScreen(),
    );
  }
}
