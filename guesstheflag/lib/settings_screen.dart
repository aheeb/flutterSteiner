import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
export 'settings_screen.dart';
import 'main.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  String? selectedContinent;
  String? selectedAlliance;
  String? selectedType;

  Future<void> _logout() async {
    await auth.signOut();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Text('Kontinent:'),
            DropdownButton<String>(
              value: selectedContinent,
              hint: Text('Select continent'),
              items: [
                DropdownMenuItem(child: Text('Asia'), value: 'Asia'),
                DropdownMenuItem(child: Text('Africa'), value: 'Africa'),
                // Andere Kontinente hier einfügen
              ],
              onChanged: (String? newValue) {
                setState(() {
                  selectedContinent = newValue;
                });
              },
            ),
            Text('Bünde:'),
            DropdownButton<String>(
              value: selectedAlliance,
              hint: Text('Select alliance'),
              items: [
                DropdownMenuItem(child: Text('UNO'), value: 'UNO'),
                DropdownMenuItem(child: Text('NATO'), value: 'NATO'),
                // Andere Bünde hier einfügen
              ],
              onChanged: (String? newValue) {
                setState(() {
                  print(newValue);
                  selectedAlliance = newValue;
                });
              },
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context, {
                  'type': selectedType, // 'Continent' oder 'Alliance'
                  'continent': selectedContinent, // z.B. 'Asia'
                  'alliance': selectedAlliance, // z.B. 'NATO'
                });
              },
              child: Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}
