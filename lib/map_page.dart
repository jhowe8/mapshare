import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:auto_size_text/auto_size_text.dart';
import 'auth.dart';

class MapPage extends StatefulWidget {
  final BaseAuth auth;
  final VoidCallback onSignedOut;

  MapPage({this.auth, this.onSignedOut});

  @override
  MapPageState createState() {
    return MapPageState();
  }
}

class MapPageState extends State<MapPage> {
  String id;
  final db = Firestore.instance;
  final _formKey = GlobalKey<FormState>();
  String userID;
  String userEmail;

  @override
  void initState() {
    super.initState();
    // check status of current user when app is turned on
    widget.auth.currentUser().then((_userID) {
      setState(() {
        userID = _userID;
      });
    });
    widget.auth.currentUserEmail().then((_userEmail) {
      setState(() {
        userEmail = _userEmail;
        // add user to database if necessary
        var data = {'user': userEmail};
        CollectionReference ref = db.collection('users');
        ref.document(userID).setData(data);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Map"),
      ),
      body: ListView(
        padding: EdgeInsets.all(8)
      ),
      bottomNavigationBar: BottomAppBar(
          child: Container(
              color: Colors.green[800],
              height: 60,
              child: Column(
                  children: <Widget>[
                    SizedBox(height: 10),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          InkWell(
                            onTap: () {},
                            child: Column(
                                children: <Widget> [
                                  Icon(Icons.library_add),
                                  Text('List new wreath')
                                ]
                            ),
                          ),
                          InkWell(
                              onTap: _signOut,
                              child: Column(
                                  children: <Widget> [
                                    Icon(Icons.exit_to_app),
                                    Text('Sign Out')
                                  ]
                              )
                          )
                        ]
                    )
                  ]
              )
          )
      ),
    );
  }

  void _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
      Navigator.pop(context);
    } catch (e) {
      print(e);
    }
  }
}

class Location {
  String latitude;
  String longitude;
  String name;
  double rating;
  String blog;
  String picture;
  String address;

  Location(this.latitude, this.longitude, this.name, this.rating, this.blog,
      this.picture, this.address);
}