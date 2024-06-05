import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class CollectionPointImageUploader {
  final String agentId;
  final String collectionPointId;
  final String collectionPointName;
  final double lat;
  final double lng;
  final String tourneeId ;

  CollectionPointImageUploader({
    required this.agentId,
    required this.collectionPointId,
    required this.collectionPointName,
    required this.lat,
    required this.lng,
    required this.tourneeId
  });

  Future<void> uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String fileName = DateTime.now().toString() + '.jpg';

      try {
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('collection_point_images/$fileName');
        UploadTask uploadTask = ref.putFile(imageFile);
        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        // Save image metadata to Firestore
        await saveImageMetadata(downloadUrl);
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  Future<void> saveImageMetadata(String downloadUrl) async {
    // Save image metadata to Firestore
    try {
      await FirebaseFirestore.instance.collection('images').add({
        'tourneeId' : tourneeId,
        'agentId': agentId,
        'collectionPointId': collectionPointId,
        'collectionPointName': collectionPointName,
        'lat': lat,
        'lng': lng,
        'date': DateTime.now().toString(),
        'imageUrl': downloadUrl,
      });
    } catch (e) {
      print('Error saving image metadata: $e');
    }
  }
}
