import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncidentReport {
  static Future<void> reportIncident(BuildContext context) async {
    final TextEditingController _incidentController = TextEditingController();
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user is signed in')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Report Incident'),
          content: TextField(
            controller: _incidentController,
            decoration: InputDecoration(hintText: 'Describe the incident'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                final incidentMessage = _incidentController.text.trim();
                if (incidentMessage.isNotEmpty) {
                  final FirebaseFirestore _firestore =
                      FirebaseFirestore.instance;
                  await _firestore.collection('incidents').add({
                    'agentId': user.uid,
                    'incident': incidentMessage,
                    'timestamp': DateTime.now(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Incident reported successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Incident message cannot be empty')),
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text('Submit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
