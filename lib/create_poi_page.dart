import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mapshare/POI.dart';
import 'package:mapshare/colors.dart';
import 'package:mapshare/database/DatabaseService.dart';
import 'auth.dart';
import 'package:uuid/uuid.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'credentials.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'map_page.dart';
import 'widgets/divider_with_text.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // the point of this page - populate this object
  POI pointOfInterest = new POI();

  String _heading = "";
  var uuid = new Uuid();
  String _sessionToken;
  List<String> _placesList = new List<String>();
  final picker = ImagePicker();
  // pick location from map
  LatLng _mapPosition;
  Completer<GoogleMapController> _controller = Completer();
  // Location selected from search
  TextEditingController _searchController = new TextEditingController();
  final FocusNode searchFocus = FocusNode();
  Set<Marker> markers = new Set<Marker>();
  // for hiding map and opening map back up
  double _mapHeight = 250;
  double _buttonSpace = 60;
  // controls the animation speed for map hiding
  int _mapVisionSpeed = 500;
  String toggleMapButtonText = "Hide Map";
  // category selection
  int initialCategoryIndex= 1;
  var indexToCategory = { 0: 'Sightseeing', 1: 'Food', 2: 'Nightlife', 3: 'Shopping' };
  // comments
  final _commentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchFocus.addListener(() {
      print("has focus: ${searchFocus.hasFocus}");
    });
    _searchController.addListener(_onSearchChanged);
    _commentsController.addListener(_updateComment);
    _mapPosition = widget.currentUserPosition;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _commentsController.removeListener(_updateComment);
    _commentsController.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  // create session tokens to limit cost
  _onSearchChanged() {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }
    getLocationResults();
  }

  void getLocationResults() async {
    if (!searchFocus.hasFocus || _searchController.text.isEmpty) {
      return;
    }
    String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    String type = 'establishment';
    String request = '$baseURL?input=${_searchController.text}&key=$PLACES_API_KEY&types=$type&sessiontoken=$_sessionToken';

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
    return Listener(
      onPointerDown: (_) {
        FocusScopeNode currentFocus = FocusScope.of(context);

        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          // leading: IconButton(
          //   icon: Icon(Icons.arrow_back),
          //   onPressed: () => setState(() {
          //     Navigator.push(context, MaterialPageRoute(
          //         builder: (context) => new MapPage(auth: widget.auth, onSignedOut: widget.onSignedOut)),
          //     );
          //   })
          // ),
          title: Text('Create Point of Interest'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: buildSearchTextField()
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
      ),
    );
  }

  Widget buildSearchTextField() {
    return ListTile(
      title: TextField(
        focusNode: searchFocus,
        maxLines: 1,
        controller: _searchController,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.place, color: HIGHLIGHT_COLOR),
          suffixIcon: _searchController.text.isEmpty ? null : IconButton(
            icon: Icon(Icons.cancel, color: HIGHLIGHT_COLOR),
            onPressed: () {
              setState(() {
                _heading = '';
              });
              _searchController.clear();
              _placesList.clear();
              markers.clear();
            },
          )
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
              onTap: () async {
                List<geocoding.Location> locations = await geocoding.locationFromAddress(_placesList[index]);
                setState(() {
                  _mapPosition = new LatLng(locations[0].latitude, locations[0].longitude);
                  _sessionToken = null;
                  _searchController.text = _placesList[index];
                  _placesList = new List<String>();
                  _heading = '';
                });

                final GoogleMapController controller = await _controller.future;
                controller.animateCamera(CameraUpdate.newCameraPosition(new CameraPosition(target: _mapPosition)));

                // add marker to map
                setState(() {
                  markers.clear();
                  markers.add(Marker(
                    markerId: MarkerId('selected location'),
                    position: _mapPosition,
                  ));
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
        // choose location category
        Container(
          padding: const EdgeInsets.all(11.0),
          child: Column(
            children: [
              Text("Choose Category", style: TextStyle(color: LIGHT_LIGHT_COLOR)),
              SizedBox(height: 25),
              Center(
                child: ToggleSwitch(
                  minWidth: MediaQuery.of(context).size.width * 0.9,
                  fontSize: 12.0,
                  initialLabelIndex: initialCategoryIndex,
                  cornerRadius: 25.0,
                  activeFgColor: LIGHT_LIGHT_COLOR,
                  inactiveBgColor: MEDIUM_LIGHT_COLOR,
                  inactiveFgColor: LIGHT_LIGHT_COLOR,
                  labels: ['Sightseeing', 'Food', 'Nightlife', 'Shopping'],
                  icons: [FontAwesomeIcons.hiking, FontAwesomeIcons.utensils, FontAwesomeIcons.glassCheers, FontAwesomeIcons.shoppingBag],
                  activeBgColors: [HIGHLIGHT_COLOR, HIGHLIGHT_COLOR, HIGHLIGHT_COLOR, HIGHLIGHT_COLOR],
                  onToggle: (index) {
                    print('switched to: $index');
                    setState(() {
                      initialCategoryIndex = index;
                      pointOfInterest.category = indexToCategory[index];
                    });
                  },
                ),
              ),
            ],
          )
        ),
        // star rating container
        Container(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text("_____________________________", style: TextStyle(color: HIGHLIGHT_COLOR)),
              SizedBox(height: 20),
              Text("Rating", style: TextStyle(color: LIGHT_LIGHT_COLOR)),
              SizedBox(height: 25),
              SmoothStarRating(
                color: HIGHLIGHT_COLOR,
                borderColor: HIGHLIGHT_COLOR,
                rating: 5.0,
                isReadOnly: false,
                size: MediaQuery. of(context).size.width * 0.15,
                filledIconData: Icons.star,
                halfFilledIconData: Icons.star_half,
                defaultIconData: Icons.star_border,
                starCount: 5,
                allowHalfRating: false,
                spacing: 2.0,
                onRated: (value) {
                  print("rating value -> $value");
                  setState(() {
                    pointOfInterest.rating = value;
                  });
                  }
              )
            ],
          )
        ),
        Container(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text("_____________________________", style: TextStyle(color: HIGHLIGHT_COLOR)),
              SizedBox(height: 20),
              Text("Upload Images", style: TextStyle(color: LIGHT_LIGHT_COLOR)),
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
              Text("_____________________________", style: TextStyle(color: HIGHLIGHT_COLOR)),
              SizedBox(height: 20),
              Text("Comments", style: TextStyle(color: LIGHT_LIGHT_COLOR)),
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
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              savePOI();
            },
            icon: Icon(Icons.pin_drop, color: DARK_LIGHT_COLOR),
            style: ElevatedButton.styleFrom(
              primary: MEDIUM_LIGHT_COLOR,
              shadowColor: DARK_COLOR,
              elevation: 3
            ),
            label: Text('Add Point', style: TextStyle(fontSize: 20, color: LIGHT_LIGHT_COLOR)),
          ),
        ),
        SizedBox(height: 30)
      ],
    );
  }

  _updateComment() {
    pointOfInterest.comments = _commentsController.text;
  }

  Widget getHideableMap() {
    return AnimatedContainer(
      height: _mapHeight,
      decoration: BoxDecoration(
        color: LIGHT_LIGHT_COLOR,
      ),
      duration: Duration(milliseconds: _mapVisionSpeed),
      curve: Curves.fastOutSlowIn,
      child:
        _mapPosition == null ? Container(child: Center(child:Text('loading map..', style: TextStyle(fontFamily: 'Avenir-Medium', color: LIGHT_LIGHT_COLOR),),),) : Container(
          decoration: const BoxDecoration(color: DARK_COLOR),
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
            markers: markers
          )
        )
    );
  }

  Widget toggleMapVisibility() {
    return Container(
      decoration: BoxDecoration(
          color: MEDIUM_LIGHT_COLOR,
          border: Border.all(color: DARK_LIGHT_COLOR)
      ),
      height: 60,
      width: MediaQuery. of(context).size.width,
      child: TextButton(
        child: Text(toggleMapButtonText, style: TextStyle(color: LIGHT_LIGHT_COLOR),),
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
            child: pointOfInterest.images[index] == null ? noImageSelected(index)
                      : Stack(
                          children: [
                            Positioned.fill(
                              child: Image.file(pointOfInterest.images[index]),
                            ),
                            Positioned(
                              right: 0,
                              child: Material(
                                color: Color.fromRGBO(1, 1, 1, 0),
                                child: Center(
                                  child: Ink(
                                    decoration: const ShapeDecoration(
                                      color: LIGHT_LIGHT_COLOR,
                                      shape: CircleBorder(),
                                    ),
                                    child: SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: IconButton(
                                        padding: new EdgeInsets.all(0.0),
                                        icon: Icon(Icons.cancel),
                                        color: HIGHLIGHT_COLOR,
                                        onPressed: () {
                                          setState(() {
                                            pointOfInterest.images[index] = null;
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
            color: LIGHT_LIGHT_COLOR
        ),
      ),
    );
  }

  Widget noImageSelected(int index) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("No image selected.", style: TextStyle(color: LIGHT_LIGHT_COLOR),),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Material(
              color: Color.fromRGBO(1, 1, 1, 0),
                child: Center(
                  child: Ink(
                    decoration: const ShapeDecoration(
                      color: MEDIUM_LIGHT_COLOR,
                      shape: CircleBorder(),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.camera_alt_outlined),
                      color: LIGHT_LIGHT_COLOR,
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
                      color: MEDIUM_LIGHT_COLOR,
                      shape: CircleBorder(),
                    ),
                    child: IconButton(
                        icon: Icon(Icons.folder),
                        color: LIGHT_LIGHT_COLOR,
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
    print(pickedFile.path);
    setState(() {
      if (pickedFile != null) {
        pointOfInterest.images[index] = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  // validate the POI and save to firebase
  // For NoSql Firebase: username - category - ( address, LatLng, rating, images, comments )
  void savePOI() async {
    pointOfInterest.address = _searchController.text;
    pointOfInterest.latitude = _mapPosition.latitude;
    pointOfInterest.longitude = _mapPosition.longitude;

    var poiValidated = POI.validatePOI(pointOfInterest);

    if (poiValidated[0]) {
      print("success! POI valid");
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => popupError(context, poiValidated[1])
      );
      print(poiValidated[1]);
    }

    List<String> imageUrls = new List<String>();
    int imageInd = 0;
    for (int i = 0; i < pointOfInterest.images.length; i++) {
      if (pointOfInterest.images[i] != null) {
        imageUrls.add(_getImagePath(imageInd));
        imageInd += 1;
      }
    }

    await _db
        .collection('users')
        .doc(widget.userID)
        .collection('POI')
        .doc(pointOfInterest.address)
        .set(
        {
          'address': pointOfInterest.address,
          'latitude': pointOfInterest.latitude,
          'longitude': pointOfInterest.longitude,
          'rating': pointOfInterest.rating,
          'images': imageUrls,
          'comments': pointOfInterest.comments
        });

    String imagePath = 'users/${widget.userID}/POI/';
    await saveImages(pointOfInterest.images, imagePath);
    // assume POI loaded - add it to markers in the map page
    //Navigator.pop(context, pointOfInterest);

    // Stream<POI> _pois = (() async* {
    //   await Future<void>.delayed(Duration(seconds: 1));
    //   yield 1;
    //   await Future<void>.delayed(Duration(seconds: 1));
    // })();
  }

  Future<void> saveImages(List<File> _images, String imagePath) async {
    int imageInd = 0;
    _images.forEach((image) async {
      if (image != null) {
        await uploadFile(image, imageInd++);
      }
    });
  }

  Future<void> uploadFile(File _image, int imageInd) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage
        .ref()
        .child(_getImagePath(imageInd));
    UploadTask uploadTask = ref.putFile(_image);
    uploadTask.then((res) async {
      await res.ref.getDownloadURL();
    });
  }

  String _getImagePath(int imageInd) {
    String imagePath = '';
    imagePath += widget.userID;
    imagePath += '/POI/';
    imagePath += pointOfInterest.address;
    imagePath += '/';
    imagePath += 'image';
    imagePath += imageInd.toString();
    return imagePath;
  }

  Widget popupError(BuildContext context, String error) {
    return new AlertDialog(
      title: const Text('Error', style: TextStyle(color: HIGHLIGHT_COLOR)),
      content: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(error, style: TextStyle(color: LIGHT_LIGHT_COLOR)),
        ],
      ),
      actions: <Widget>[
        new FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          textColor: DARK_LIGHT_COLOR,
          color: MEDIUM_LIGHT_COLOR,
          child: const Text('Close'),
        ),
      ],
    );
  }
}
