import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class POI {
  String address;
  double latitude;
  double longitude;
  double rating;
  String category;

  List<File> images = new List<File>(4);
  String comments;

  POI() {
    this.address = null;
    this.latitude = null;
    this.longitude = null;
    this.rating = 5.0;
    this.category = "Food";

    for (int i = 0; i < 4; i++) {
      this.images[i] = null;
    }

    this.comments = null;
  }

  // POI({this.address, this.latitude, this.longitude, this.rating, this.category, this.images, this.comments});

  // return whether the POI is valid and the reason it is invalid
  static List validatePOI(POI poi) {
    bool valid = true;
    String reasonInvalid = "";
    if (poi.address == null || poi.address.isEmpty) {
      reasonInvalid += "Please enter an address in the search bar above.\n";
      valid = false;
    } else {
      poi.address = poi.address.replaceAll('/', '');
      print("+ address found: ${poi.address}");
    }

    if ((poi.latitude == null || poi.longitude == null) && poi.address != null && poi.address.isNotEmpty) {
      reasonInvalid += "Error geocoding address to latitude and longitude.\n";
      valid = false;
    } else {
      print("+ location found: ${poi.longitude}, ${poi.latitude}");
    }

    if (poi.rating == null) {
      reasonInvalid += "Error establishing rating.\n";
      valid = false;
    } else {
      print("+ rating found: ${poi.rating}");
    }

    if (poi.category == null || poi.category.isEmpty) {
      reasonInvalid += "Error setting category.\n";
      valid = false;
    } else {
      print("+ category found: ${poi.category}");
    }

    if (poi.comments != null) {
      print("+ comments found: ${poi.comments}");
    }

    String filesFoundAtIndex = "";
    for (int imageIndex = 0; imageIndex < 4; imageIndex++) {
      if (poi.images[imageIndex] != null) {
        filesFoundAtIndex += imageIndex.toString() + " ";
      }
    }

    if (filesFoundAtIndex.isNotEmpty) {
      print("+ files found at indices: ${filesFoundAtIndex}");
    }

    return new List.unmodifiable([valid, reasonInvalid]);
  }

  factory POI.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data as Map;

    /*
    return POI(
      address: data['address'] ?? '',
    );

     */
  }
}