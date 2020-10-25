import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:http/http.dart' as http;
import 'package:auto_size_text/auto_size_text.dart';
import 'auth.dart';
import 'package:uuid/uuid.dart';
import 'package:geocoder/geocoder.dart';
import 'credentials.dart';
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
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  GoogleMapController mapController;
  final Geolocator _geolocator = Geolocator();
  static LatLng _initialPosition;
  static LatLng _lastMapPosition = _initialPosition;
  String id;
  final db = FirebaseFirestore.instance;
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
        ref.doc(userID).set(data);
      });
    });
    _getUserLocation();
  }

  void _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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
      appBar: AppBar(
        title: Text("Your Map"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _initialPosition == null ? Container(child: Center(child:Text('loading map..', style: TextStyle(fontFamily: 'Avenir-Medium', color: LIGHT_CYAN),),),) : Container(
              decoration: const BoxDecoration(color: BURNT_SIENNA),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _initialPosition,
                  zoom: 15
                ),
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                mapType: MapType.hybrid,
                compassEnabled: true,
                markers: Set<Marker>.of(markers.values),
                onCameraMove: _onCameraMove,
              )
            ),
            flex: 3,
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(color: GUNMETAL),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      FlatButton(
                      child: Icon(Icons.pin_drop, color: Colors.white),
                      color: PALE_CERULEAN,
                      onPressed: _addMarker
                      )
                    ]
                  ),
                  Row(
                    children: <Widget>[
                      FlatButton(
                      child: Icon(Icons.delete_outline, color: Colors.white),
                      color: BURNT_SIENNA,
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
              color: BDAZZLED_BLUE,
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

  // use this to get the markers from database for user
  _onMapCreated(GoogleMapController controller) async {

  }

  _addMarker() async {
    var uuid = Uuid();
    var markerIdVal = uuid.v1();
    final MarkerId markerId = MarkerId(markerIdVal);
    String address;
    String name;

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    await _getAddress(position.latitude, position.longitude).then((String title) {
      setState(() {
        address = title;
      });
    });

    await _getName(address, position.latitude, position.longitude).then((String placename) {
      setState(() {
        name = placename;
      });
    });

    // creating a new MARKER
    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(position.latitude, position.longitude),
      infoWindow: InfoWindow(title: name, snippet: address),
      onTap: () {
        _onMarkerTapped(name, address, position.latitude, position.longitude);
      },
    );

    setState(() {
      // adding a new marker to map
      markers[markerId] = marker;
    });
  }

  _deleteAllMarkers() {
    setState(() {
      markers = <MarkerId, Marker>{};
    });
  }

  Future<String> _getAddress(double latitude, double longitude) async {
    final coordinates = new Coordinates(latitude, longitude);
    var addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);
    var first = addresses.first;
    return first.addressLine;
  }

  Future<String> _getName(String address, double latitude, double longitude) async {
    var googlePlace = GooglePlace(PLACES_API_KEY);
    var getTextSearch = await googlePlace.search.getTextSearch(address + "street_address");
    return getTextSearch.results[0].name;
  }

  _onMarkerTapped(String name, String address, double latitude, double longitude) async {
    print("latitude: " + latitude.toString());
    print("longitude: " + longitude.toString());
    print("name: " + name);
    print("name: " + address);
  }
}