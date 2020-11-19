import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_place/google_place.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mapshare/POI.dart';
import 'package:mapshare/colors.dart';
import 'auth.dart';
import 'package:uuid/uuid.dart';
import 'package:geocoder/geocoder.dart';
import 'credentials.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'widgets/divider_with_text.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';

class CreatePOIPage extends StatefulWidget {
  final String desiredLocationGuess;
  final String userEmail;
  final String userID;
  final BaseAuth auth;
  final VoidCallback onSignedOut;

  CreatePOIPage(this.desiredLocationGuess, this.userEmail, this.userID, this.auth, this.onSignedOut);

  @override
  CreatePOIPageState createState() {
    return CreatePOIPageState();
  }
}

class CreatePOIPageState extends State<CreatePOIPage> {
  TextEditingController _searchController = new TextEditingController();
  final db = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  String _address;
  String _heading;
  var uuid = new Uuid();
  String _sessionToken;
  List<String> _placesList;
  final List<String> _suggestedList = null;
  bool recentlySelected = false;
  var _images = new List(4);
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _heading = "";
    _placesList = _suggestedList;
    _searchController.text = widget.desiredLocationGuess;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  _onSearchChanged() {
    print(recentlySelected);
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }
    if (!recentlySelected) {
      getLocationResults(_searchController.text);
    }
    recentlySelected = false;
  }

  void getLocationResults(String input) async {
    if (input.isEmpty) {
      return;
    }

    String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    String type = 'establishment';
    String request = '$baseURL?input=$input&key=$PLACES_API_KEY&types=$type&sessiontoken=$_sessionToken';
    Response response = await Dio().get(request);

    print(request);
    final predictions = response.data['predictions'];

    List<String> _displayResults = [];

    for (var i=0; i < predictions.length; i++) {
      String name = predictions[i]['description'];
      _displayResults.add(name);
    }

    setState(() {
      _heading = "Results";
      _placesList = _displayResults;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Trip - Location'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.place),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
              child: _heading == null ? Container() : new DividerWithText(
                dividerText: _heading,
              ),
            ),
            Expanded(
              child: (_placesList == null || _placesList.length < 1) ? buildRatingPage(context) : ListView.builder(
                itemCount: _placesList.length,
                itemBuilder: (BuildContext context, int index) =>
                    buildPlaceCard(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPlaceCard(BuildContext context, int index) {
    return Hero(
      tag: "SelectedTrip-${_placesList[index]}",
      transitionOnUserGestures: true,
      child: Container(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Card(
            child: InkWell(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Flexible(
                                child: AutoSizeText(_placesList[index],
                                    maxLines: 3,
                                    style: TextStyle(fontSize: 14.0)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () {
                clearPlaceSearchOnTap(index);
                setState(() {
                  _sessionToken = null;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRatingPage(BuildContext context) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text("Overall Rating"),
              SizedBox(height: 20),
              SmoothStarRating(
                color: BURNT_SIENNA,
                borderColor: BURNT_SIENNA,
                rating: 5.0,
                isReadOnly: false,
                size: 30,
                filledIconData: Icons.star,
                halfFilledIconData: Icons.star_half,
                defaultIconData: Icons.star_border,
                starCount: 5,
                allowHalfRating: true,
                spacing: 2.0,
                onRated: (value) {
                  print("rating value -> $value");
                  }
              )
            ],
          )
        ),
        Container(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text("_____________________________", style: TextStyle(color: BURNT_SIENNA)),
              SizedBox(height: 20),
              Text("Upload Images"),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  getImageContainer(0),
                  SizedBox(width: 20),
                  getImageContainer(1)
                ]
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  getImageContainer(2),
                  SizedBox(width: 20),
                  getImageContainer(3)
                ]
              )
            ]
          )
        ),
        SizedBox(height: 10),
        Container(
          child: Column(
            children: [
              Text("_____________________________", style: TextStyle(color: BURNT_SIENNA)),
              SizedBox(height: 20),
              Text("Comments"),
              TextField(
                keyboardType: TextInputType.multiline,
                minLines: 3,//Normal textInputField will be displayed
                maxLines: 8,// when user presses enter it will adapt to it
              )
            ]
          )
        )
      ],
    );
  }

  void clearPlaceSearchOnTap(int index) async {
    recentlySelected = true;
    _searchController.text = _placesList[index];
    _placesList = null;
    _heading = null;
  }

  Widget getImageContainer(int index) {
    return Container(
      width: MediaQuery. of(context).size.width * 0.25,
      height: MediaQuery. of(context).size.width * 0.25,
      child: _images[index] == null
          ? Text('No image selected.')
          : Image.file(_images[index]),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(
            color: BURNT_SIENNA
        ),
      ),
    );
  }

  Future getImage(index) async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _images[index] = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }
}