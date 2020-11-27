import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mapshare/POI.dart';
import 'package:mapshare/colors.dart';
import 'auth.dart';
import 'package:uuid/uuid.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'credentials.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'widgets/divider_with_text.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';

class CreatePOIPage extends StatefulWidget {
  final LatLng currentUserPosition;
  final String userEmail;
  final String userID;
  final BaseAuth auth;
  final VoidCallback onSignedOut;

  CreatePOIPage(this.currentUserPosition, this.userEmail, this.userID, this.auth, this.onSignedOut);

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
  final picker = ImagePicker();
  String selectedEntry;
  double _mapHeight = 250;
  double _buttonSpace = 60;
  int _mapVisionSpeed = 500;
  String toggleMapButtonText = "Hide Map";
  LatLng _mapPosition;
  Completer<GoogleMapController> _controller = Completer();
  String comments;
  final _commentsController = TextEditingController();

  Map<num, File> indexToImage = <num, File>{
    0: null,
    1: null,
    2: null,
    3: null
  };

  @override
  void initState() {
    super.initState();
    _heading = "";
    _placesList = null;
    _searchController.addListener(_onSearchChanged);
    _commentsController.addListener(_updateComment);
    _mapPosition = widget.currentUserPosition;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  _onSearchChanged() {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }
    getLocationResults(_searchController.text);
  }

  void getLocationResults(String input) async {
    if (input.isEmpty || input == selectedEntry) {
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
        // map and show/hide button stack
        Stack(
          children: [
            // this positioned container must take up the exact size of the
            // button's height plus the map's height
            Positioned(
              child: Container(
                height: _mapHeight + _buttonSpace
              )
            ),
            Positioned(
              child: getHideableMap(),
            ),
            Positioned(
              bottom: 0,
              child: toggleMapVisibility()
            )
          ]
        ),
        SizedBox(height: 20),
        // star rating container
        Container(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text("Rating", style: TextStyle(color: LIGHT_CYAN)),
              SizedBox(height: 25),
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
              Text("Upload Images", style: TextStyle(color: LIGHT_CYAN)),
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
              Text("Comments", style: TextStyle(color: LIGHT_CYAN)),
              SizedBox(height: 20),
              Container(
                margin: EdgeInsets.all(8.0),
                padding: EdgeInsets.only(bottom: 40.0),
                child: TextFormField(
                  controller: _commentsController,
                  maxLength: 280,
                  minLines: 2,
                  maxLines: 6,
                  textInputAction: TextInputAction.go,
                  decoration: InputDecoration(
                    hintText: "Comment here (maximum of 280 characters)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ]
          )
        ),
        SizedBox(height: 30)
      ],
    );
  }

  _updateComment() {
    comments = _commentsController.text;
  }

  Future<void> clearPlaceSearchOnTap(int index) async {
    List<geocoding.Location> locations = await geocoding.locationFromAddress(_placesList[index]);
    setState(() {
      _mapPosition = null;
      selectedEntry = _placesList[index];
      _searchController.text = _placesList[index];
      _heading = null;
      _mapPosition = new LatLng(locations[0].latitude, locations[0].longitude);
      _placesList = null;
    });

    FocusScope.of(context).requestFocus(new FocusNode());
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(new CameraPosition(target: _mapPosition)));
  }

  Widget getHideableMap() {
    return AnimatedContainer(
      height: _mapHeight,
      decoration: BoxDecoration(
        color: LIGHT_CYAN,
      ),
      duration: Duration(milliseconds: _mapVisionSpeed),
      curve: Curves.fastOutSlowIn,
      child:
        _mapPosition == null ? Container(child: Center(child:Text('loading map..', style: TextStyle(fontFamily: 'Avenir-Medium', color: LIGHT_CYAN),),),) : Container(
          decoration: const BoxDecoration(color: GUNMETAL),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
                target: _mapPosition,
                zoom: 15
            ),
            myLocationEnabled: true,
            mapType: MapType.hybrid,
            compassEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          )
        )
    );
  }

  Widget toggleMapVisibility() {
    return Container(
      decoration: BoxDecoration(
          color: BDAZZLED_BLUE,
          border: Border.all(color: Colors.blueAccent)
      ),
      height: 60,
      width: MediaQuery. of(context).size.width,
      child: TextButton(
        child: Text(toggleMapButtonText, style: TextStyle(color: LIGHT_CYAN),),
        onPressed: () {
          if (toggleMapButtonText == "Hide Map") {
            setState(() {
              _mapHeight = 60.0;
              _buttonSpace = 0;
              _mapVisionSpeed = 500;
              toggleMapButtonText = "Show Map";
            });
          } else {
            setState(() {
              _mapHeight = 250.0;
              _buttonSpace = 60;
              _mapVisionSpeed = 0;
              toggleMapButtonText = "Hide Map";
            });
          }
        }
      )
    );
  }

  Widget getImageContainer(int index) {
    return Container(
      width: MediaQuery. of(context).size.width * 0.40,
      height: 115,
      child: Container(
        child: ConstrainedBox(
          constraints: BoxConstraints.expand(),
          child: Container(
            padding: EdgeInsets.all(0.0),
            child: indexToImage[index] == null ? noImageSelected(index)
                      : Stack(
                          children: [
                            Positioned.fill(
                              child: Image.file(indexToImage[index]),
                            ),
                            Positioned(
                              right: 0,
                              child: Material(
                                color: Color.fromRGBO(1, 1, 1, 0),
                                child: Center(
                                  child: Ink(
                                    decoration: const ShapeDecoration(
                                      color: LIGHT_CYAN,
                                      shape: CircleBorder(),
                                    ),
                                    child: SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: IconButton(
                                        padding: new EdgeInsets.all(0.0),
                                        icon: Icon(Icons.cancel),
                                        color: BURNT_SIENNA,
                                        onPressed: () {
                                          setState(() {
                                            indexToImage[index] = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            )
                          ]
                        )
          )
        )
      ),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(
            color: LIGHT_CYAN
        ),
      ),
    );
  }

  Widget noImageSelected(int index) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("No image selected.", style: TextStyle(color: LIGHT_CYAN),),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Material(
              color: Color.fromRGBO(1, 1, 1, 0),
                child: Center(
                  child: Ink(
                    decoration: const ShapeDecoration(
                      color: BDAZZLED_BLUE,
                      shape: CircleBorder(),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.camera_alt_outlined),
                      color: LIGHT_CYAN,
                      onPressed: () => getImage(index, ImageSource.camera)
                    ),
                  ),
                ),
              ),
              Material(
                color: Color.fromRGBO(1, 1, 1, 0),
                child: Center(
                  child: Ink(
                    decoration: const ShapeDecoration(
                      color: BDAZZLED_BLUE,
                      shape: CircleBorder(),
                    ),
                    child: IconButton(
                        icon: Icon(Icons.folder),
                        color: LIGHT_CYAN,
                        onPressed: () => getImage(index, ImageSource.gallery)
                    ),
                  ),
                ),
              )
            ]
          )
        ],
      )
    );
  }

  Future getImage(index, ImageSource imageSource) async {
    final pickedFile = await picker.getImage(source: imageSource);

    setState(() {
      if (pickedFile != null) {
        indexToImage[index] = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }
}
