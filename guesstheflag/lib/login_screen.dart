import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
export 'login_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  String email = '';
  String password = '';

  // Logout Funktion
  Future<void> _logout() async {
    await auth.signOut();
  }

  // Register Funktion
  Future<void> _register() async {
    try {
      await auth.createUserWithEmailAndPassword(
          email: email, password: password);
      Navigator.pushReplacementNamed(
          context, '/'); // Zurück zum Hauptbildschirm
    } catch (e) {
      print("Registrierungsfehler: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        actions: [
          // Logout Button in der App-Leiste
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                email = value;
              },
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            TextField(
              onChanged: (value) {
                password = value;
              },
              decoration: InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await auth.signInWithEmailAndPassword(
                      email: email, password: password);
                  Navigator.pushReplacementNamed(
                      context, '/'); // Zurück zum Hauptbildschirm
                } catch (e) {
                  print("Anmeldefehler: $e");
                }
              },
              child: Text('Login'),
            ),
            ElevatedButton(
              onPressed: _register, // Aufruf der Register-Funktion
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
