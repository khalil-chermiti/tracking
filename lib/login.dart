import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tracking/CollectionPoints.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _email, _password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              validator: (input) {
                if (input == null || input.isEmpty) {
                  return 'Please type an email';
                }
                return null;
              },
              onSaved: (input) => _email = input!,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            TextFormField(
              validator: (input) {
                if (input == null || input.length < 6) {
                  return 'Your password needs to be at least 6 characters';
                }
                return null;
              },
              onSaved: (input) => _password = input!,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: signIn,
              child: Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }

  void signIn() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        var response = await _auth.signInWithEmailAndPassword(
            email: _email, password: _password);

        print(response.user?.email);
        // Navigate to success page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MapSample()),
        );
      } catch (e) {
        print(e.toString());
      }
    }
  }
}
