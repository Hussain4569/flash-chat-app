import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/model/CustomerProvider.dart';
import 'package:flash_chat/screens/change_password_screen.dart';
import 'package:flash_chat/screens/customer_list.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';

FirebaseAuth _auth = FirebaseAuth.instance;
FirebaseFirestore _firestore = FirebaseFirestore.instance;
User? loggedInUser = null;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String messageText = '';
  TextEditingController messageController = TextEditingController();
  bool isLoading = false;

  Future<void> getCurrentUser() async {
    try {
      loggedInUser = await _auth.currentUser;
      if (loggedInUser != null) {
        print(loggedInUser?.email);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void popPage() {
    Navigator.pop(context);
  }
  // void messageStream() {
  //   _firestore.collection("messages").snapshots().listen((event) {
  //     final messages = [];
  //     for (var doc in event.docs) {
  //       messages.add(doc.data());
  //     }
  //     print(messages);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () async {
                await _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      drawer: ModalProgressHUD(
        inAsyncCall: isLoading,
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  '⚡ Flash chat',
                  style: TextStyle(fontSize: 30.0, color: Colors.white),
                ),
              ),
              ListTile(
                title: const Text(
                  'Change password',
                  style: TextStyle(fontSize: 20.0),
                ),
                onTap: () {
                  Navigator.pushNamed(context, PasswordScreen.id);
                },
              ),
              ListTile(
                title: const Text(
                  'Sign out',
                  style: TextStyle(fontSize: 20.0),
                ),
                onTap: () async {
                  await _auth.signOut();
                  int count = 0;
                  Navigator.of(context).popUntil((_) => count++ >= 2);
                },
              ),
              ListTile(
                title: const Text(
                  'Delete account',
                  style: TextStyle(fontSize: 20.0),
                ),
                onTap: () async {
                  await loggedInUser?.delete();
                  int count = 0;
                  Navigator.of(context).popUntil((_) => count++ >= 2);
                },
              ),
              ListTile(
                title: const Text(
                  'Customer',
                  style: TextStyle(fontSize: 20.0),
                ),
                onTap: () {
                  setState(() {
                    isLoading = true;
                  });
                  print("on tap reached.");
                  Provider.of<CustomerProvider>(context, listen: false)
                      .getNextData();
                  setState(() {
                    isLoading = false;
                  });
                  Navigator.pushNamed(context, CustomerList.id);
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MesssagesStream(),
            Container(
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
                  TextButton(
                    onPressed: () {
                      messageController.clear();
                      _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': loggedInUser!.email,
                        'time': Timestamp.now()
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
          ],
        ),
      ),
    );
  }
}

class MesssagesStream extends StatefulWidget {
  const MesssagesStream({
    super.key,
  });

  @override
  State<MesssagesStream> createState() => _MesssagesStreamState();
}

class _MesssagesStreamState extends State<MesssagesStream> {
  ScrollController scrollController = ScrollController();
  List<MessageBubble> messageBubbles = [];

  void _scrollListener() {
    if (scrollController.position.pixels ==
        scrollController.position.minScrollExtent) {
    } else {}
  }

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection("messages")
          .orderBy("time", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.blueAccent,
            ),
          );
        }
        final messages = snapshot.data!.docs;
        for (var msg in messages) {
          final msgText = msg.data()['text'];
          final msgSender = msg.data()['sender'];
          messageBubbles.add(MessageBubble(
            text: msgText,
            sender: msgSender,
            isMe: loggedInUser!.email == msgSender,
          ));
        }
        return Expanded(
          child: ListView(
            controller: scrollController,
            reverse: true,
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final String sender;
  final bool isMe;
  const MessageBubble(
      {required this.text, required this.sender, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(fontSize: 12.0, color: Colors.black54),
          ),
          Material(
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            elevation: 4.0,
            borderRadius: BorderRadius.only(
                topLeft: isMe ? Radius.circular(30.0) : Radius.zero,
                topRight: !isMe ? Radius.circular(30.0) : Radius.zero,
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0)),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(
                    fontSize: 16.0,
                    color: isMe ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
