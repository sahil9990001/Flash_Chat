import 'dart:ui';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/Utils/shared_pref.dart';
import 'package:flash_chat/screens/welcome.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constant.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController messageController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  String messageText;
  String userInformation;
  final _auth = FirebaseAuth.instance;
  User loggedInUser;
  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }

  void getUserInfo() async {
    DocumentSnapshot userInfo =
        await _firestore.collection('Users').doc(loggedInUser.uid).get();
    String info = userInfo['Email'];
    setStateIfMounted(() {
      userInformation = info;
    });
  }

  Future<bool> _onBackPressed() {
    return showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: new Text('Are you sure?'),
            content: new Text('Do you want to exit an App'),
            actions: <Widget>[
              new GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                child: Text("NO", style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 16),
              new GestureDetector(
                onTap: () => Navigator.of(context).pop(true),
                child: Text("YES", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _onSignOutPressed() {
    return showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: new Text('Are you sure?'),
            content: new Text('Do you want to Sign-Out an App'),
            actions: <Widget>[
              new GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                child: Text("NO", style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 16),
              new GestureDetector(
                onTap: () {
                  SharedPref.prefs.setBool('LoggedIn', false);
                  _auth.signOut();
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => WelcomeScreen()));
                },
                child: Text("YES", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void initState() {
    super.initState();
    getUserInfo();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          leading: null,
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.login_outlined),
                onPressed: () {
                  _onSignOutPressed();
                  // _auth.signOut();
                }),
          ],
          title: Text('⚡️Chat $userInformation'),
          backgroundColor: Colors.lightBlueAccent,
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              StreamBuilder(
                  stream: _firestore
                      .collection('messages')
                      .orderBy('dateTime', descending: true)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.lightBlueAccent,
                        ),
                      );
                    }
                    // final List<DocumentSnapshot> documents = snapshot.data.docs;
                    return Expanded(
                      child: ListView(
                          reverse: true,
                          children: snapshot.data.docs
                              .map((doc) => TextBubble(
                                  text: doc['text'],
                                  sender: doc['sender'],
                                  time: doc['dateTime'],
                                  isme: loggedInUser.email == doc['sender']))
                              .toList()),
                    );
                  }),
              Padding(
                padding: EdgeInsets.only(
                    left: 8.0, right: 8.0, bottom: 3.0, top: 8.0),
                child: Container(
                  decoration: kMessageContainerDecoration,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          onChanged: (value) {
                            messageText = value;
                          },
                          decoration: kMessageTextFieldDecoration,
                        ),
                      ),
                      FlatButton(
                        onPressed: () {
                          messageController.clear();
                          _firestore
                              .collection('messages')
                              .doc(loggedInUser.uid)
                              .set({
                            'sender': loggedInUser.email,
                            'text': messageText,
                            'dateTime': DateFormat('kk:mm:ss \n EEE d MMM')
                                .format(DateTime.now()),
                          });
                        },
                        child: Text(
                          'Send',
                          style: kSendButtonTextStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TextBubble extends StatelessWidget {
  String sender;
  String text;
  String time;
  bool isme;
  TextBubble({Key key, this.sender, this.text, this.isme, this.time})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment:
          isme ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 15.0, left: 5.0),
          child: Text(sender, style: TextStyle(color: Colors.white)),
        ),
        Padding(
          padding: EdgeInsets.only(left: 4.0),
          child: Card(
            shape: isme
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ))
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  )),
            elevation: 10.0,
            color: isme ? Colors.pink : Colors.blue,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(text, style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
        Text(
          time.toString().substring(0, 8),
          style: TextStyle(color: Colors.white),
        )
        // Text(DateTime.now().toString())
      ],
    );
  }
}
