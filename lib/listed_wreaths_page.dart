import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:auto_size_text/auto_size_text.dart';
import 'auth.dart';

class ListedWreathsPage extends StatefulWidget {
  final BaseAuth auth;
  final VoidCallback onSignedOut;

  ListedWreathsPage({this.auth, this.onSignedOut});

  @override
  ListedWreathsPageState createState() {
    return ListedWreathsPageState();
  }
}

class ListedWreathsPageState extends State<ListedWreathsPage> {
  String id;
  final db = Firestore.instance;
  final _formKey = GlobalKey<FormState>();
  var wreaths = new List<Wreath>();
  String userID;
  String userEmail;

  @override
  void initState() {
    super.initState();

    wreaths.add(new Wreath('https://i.ebayimg.com/images/g/i3sAAOSwozpe8UoA/s-l500.jpg', 'Summer Wreath', '25', '2 days', 22, true, true));
    wreaths.add(new Wreath('https://i.ebayimg.com/images/g/X0gAAOSwkhxesOT6/s-l1600.jpg', 'Fall Wreath', '25', '3 days', 22, true, true));
    wreaths.add(new Wreath('https://i.ebayimg.com/images/g/-cEAAOSwp49e5~Ep/s-l1600.jpg', 'Winter Wreath', '25', '4 days', 22, true, false));
    wreaths.add(new Wreath('https://i.ebayimg.com/images/g/HYsAAOSwnv9e6jQq/s-l1600.jpg', 'Spring Wreath', '25', '1 day', 22, false, false));
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
        title: Text("Listed Wreaths"),
      ),
      body: ListView(
        padding: EdgeInsets.all(8),
        children: wreaths.map((i) => buildWreathCard(i)).toList()
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

  Card buildWreathCard(Wreath wreath) {
    return Card(
      elevation: 8,
      margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(color: Color.fromRGBO(129, 195, 199, .25)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              leading: Container(
                width: 80,
                padding: EdgeInsets.only(right: 12.0),
                decoration: new BoxDecoration(
                  border: new Border(
                    right: new BorderSide(width: 1.0, color: Colors.white24)
                  )
                ),
                child: Image.network(wreath.picUrl)
              ),
              title: Text(wreath.title, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Views: ${wreath.views}', style: TextStyle(color: Colors.greenAccent)),
                  Text('Price: ${wreath.price}', style: TextStyle(color: Colors.greenAccent)),
                  wreath.getTimeLeft()
                ]
              ),
            ),
            wreath.getButton()
          ]
        )
      )
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

class Wreath {
  String _picUrl;
  String _title;
  String _price;
  String _timeLeft;
  int _views;
  int _watchers;
  bool _sold;
  bool _shippingLabelCreated;

  Wreath(String picUrl, String title, String price, String timeLeft, int views, bool sold, bool shippingLabelCreated) {
    this.picUrl = picUrl;
    this.title = title;
    this.price = price;
    this.timeLeft = timeLeft;
    this.views = views;
    this.sold = sold;
    this.shippingLabelCreated = shippingLabelCreated;
  }

  String get picUrl => _picUrl;

  set picUrl(String value) {
    _picUrl = value;
  }

  String get title => _title;

  set title(String value) {
    _title = value;
  }

  bool get shippingLabelCreated => _shippingLabelCreated;

  set shippingLabelCreated(bool value) {
    _shippingLabelCreated = value;
  }

  bool get sold => _sold;

  set sold(bool value) {
    _sold = value;
  }

  int get watchers => _watchers;

  set watchers(int value) {
    _watchers = value;
  }

  int get views => _views;

  set views(int value) {
    _views = value;
  }

  String get price => _price;

  set price(String value) {
    _price = value;
  }

  String get timeLeft => _timeLeft;

  set timeLeft(String value) {
    _timeLeft = value;
  }

  Widget getTimeLeft() {
    if (!this.sold) {
      return Text(this.timeLeft + ' left', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent));
    } else {
      return Visibility(child: Text('no text'), visible: false);
    }
  }

  Widget getButton() {
    TextStyle textStyle = TextStyle(fontSize: 14, decoration: TextDecoration.none, color: Colors.white);

    if (this.sold && !this.shippingLabelCreated) {
      return RaisedButton(
        child: Text('Create shipping label', style: textStyle),
        onPressed: () {}
      );
    } else if (this.sold) {
      return RaisedButton(
        child: Text('Print shipping label', style: textStyle),
        onPressed: () {}
      );
    } else {
      return Visibility(
        child: Text('no button'),
        visible: false
      );
    }
  }
}