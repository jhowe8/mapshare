import 'package:cloud_firestore/cloud_firestore.dart';
import '../POI.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Future<POI> getPOI(String id) async {
  //   var poi = await _db.collection('users').doc(id).get();
  //
  //   return POI.fromMap(poi.data());
  // }
}