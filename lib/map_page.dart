import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:mapshare/POI.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import 'credentials.dart';
import 'package:google_place/google_place.dart';
import 'auth.dart';
import 'package:geocoder/geocoder.dart' as gc;
import 'create_poi_page.dart';
import 'colors.dart';

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
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Set<Marker> markers = new Set<Marker>();
  GoogleMapController mapController;
  static LatLng _initialPosition;
  static LatLng _lastMapPosition = _initialPosition;
  String id;
  final _formKey = GlobalKey<FormState>();
  String userID;
  String userEmail;
  BehaviorSubject<double> radius = BehaviorSubject<double>.seeded(100.0);
  Stream<dynamic> query;
  StreamSubscription subscription;
  // StreamBuilder<QuerySnapshot> streamBuilder = new StreamBuilder(
  //   stream: markerStream,
  //   builder: null,
  // );

  @override
  void initState() {
    super.initState();
    _signInAndGetMarkers();
    _getUserLocation();
  }

  void _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final coordinates = new gc.Coordinates(position.latitude, position.longitude);

    // get business address
    var addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);
    String address = addresses.first.addressLine;

    // get business name
    var googlePlace = GooglePlace(PLACES_API_KEY);
    var getTextSearch = await googlePlace.search.getTextSearch(address + "street_address");

    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
    });
  }

  _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_LIGHT_COLOR,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Your Map"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _initialPosition == null ? Container(child: Center(child:Text('loading map..', style: TextStyle(fontFamily: 'Avenir-Medium', color: LIGHT_LIGHT_COLOR),),),) : Container(
              decoration: const BoxDecoration(color: DARK_COLOR),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _initialPosition,
                  zoom: 15
                ),
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                mapType: MapType.hybrid,
                compassEnabled: true,
                markers: markers,
                onCameraMove: _onCameraMove,
              )
            ),
            flex: 3,
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(color: DARK_COLOR),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      FlatButton(
                        child: Icon(Icons.pin_drop, color: HIGHLIGHT_COLOR),
                        color: MEDIUM_LIGHT_COLOR,
                        onPressed: _addMarker
                      )
                    ]
                  ),
                  Row(
                    children: <Widget>[
                      FlatButton(
                        child: Icon(Icons.delete_outline, color: LIGHT_LIGHT_COLOR),
                        color: HIGHLIGHT_COLOR,
                        onPressed: _deleteAllMarkers
                      )
                    ]
                  )
                ]
              )
            ),
            flex: 1,
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
          child: Container(
              color: MEDIUM_LIGHT_COLOR,
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
                                  Icon(Icons.maps_ugc_sharp),
                                  Text('List new spot')
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

  void _updateMarkers(List<DocumentSnapshot> documentList) {
    print(documentList);
    setState(() {
      markers = new Set<Marker>();
    });
    documentList.forEach((DocumentSnapshot document) {
      LatLng latLng = new LatLng(document.data()['latitude'], document.data()['longitude']);
      double distance = document.data()['distance'];
      markers.add(Marker(
        markerId: new MarkerId(new Uuid().toString()),
        position: latLng,
        icon: BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: 'title',
          snippet: 'snippet'
        )
      ));
    });
  }

  _startQuery() async {
    FirebaseStorage storage = FirebaseStorage.instance;
    var ref = _db.collection('POI');

    subscription = radius.switchMap((rad) {
      return Geoflutterfire().collection(collectionRef: ref).within(
        center: new GeoFirePoint(_initialPosition.latitude, _initialPosition.longitude),
        radius: rad,
        field: 'geopoint',
        strictMode: true
      );
    }).listen(_updateMarkers);
  }

  // use this to get the markers from database for user
  _onMapCreated(GoogleMapController controller) async {
    print("Map Created");
  }

  _addMarker() {
    setState(() {
      Navigator.push(context, MaterialPageRoute(
          builder: (context) => CreatePOIPage(_initialPosition, userEmail, userID, widget.auth, widget.onSignedOut)),
      );
    });
  }

  _signInAndGetMarkers() async {
    // check status of current user when app is turned on
    await widget.auth.currentUser().then((_userID) {
      setState(() {
        userID = _userID;
      });
    });
    widget.auth.currentUserEmail().then((_userEmail) {
      setState(() {
        userEmail = _userEmail;
        // add user to database if necessary
        var data = {'user': userEmail};
        CollectionReference ref = _db.collection('users');
        ref.doc(userID).set(data);
      });
    });

    var uuid = Uuid();
    var markerIdVal = uuid.v1();
    final MarkerId markerId = MarkerId(markerIdVal);

    Query query = FirebaseFirestore.instance.collection('users').doc(userID).collection('POI');

    var uuid2 = Uuid();
    print(userID);
    // creating a new MARKER
    /*
    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(position.latitude, position.longitude),
      infoWindow: InfoWindow(title: name, snippet: address),
      onTap: () {
        _onMarkerTapped(name, address, position.latitude, position.longitude);
      },
    );

     */
  }

  void markerStream() {
    _db.collection('user').doc(userID).collection('POI').get().then((docs) {
      if (docs.docs.isNotEmpty) {
        for(int i = 0; i < docs.docs.length; i++) {
          _initMarker(docs.docs[i].data(), docs.docs[i].id);
        }
      }
    });
  }

  void _initMarker(chargePoint, documentId) {
    var markerIdVal = documentId;
    final MarkerId markerId = MarkerId(markerIdVal);
  }

  _deleteAllMarkers() {
    setState(() {
      markers = new Set<Marker>();
    });
  }

  Future<String> _getAddress(double latitude, double longitude) async {
    final coordinates = new gc.Coordinates(latitude, longitude);
    // var addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);
    //var first = addresses.first;
    //return first.addressLine;
    return null;
  }

  Future<String> _getName(String address, double latitude, double longitude) async {
    //var googlePlace = GooglePlace(PLACES_API_KEY);
    //var getTextSearch = await googlePlace.search.getTextSearch(address + "street_address");
    //return getTextSearch.results[0].name;
    return null;
  }

  _onMarkerTapped(String name, String address, double latitude, double longitude) async {
    print("latitude: " + latitude.toString());
    print("longitude: " + longitude.toString());
    print("name: " + name);
    print("address: " + address);
  }
}