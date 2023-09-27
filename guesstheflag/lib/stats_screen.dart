import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
export 'stats_screen.dart';

class StatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot<Map<String, dynamic>>> statsStream;

  @override
  void initState() {
    super.initState();
    User? currentUser = auth.currentUser;
    if (currentUser != null) {
      statsStream = firestore
          .collection('userStats')
          .doc(currentUser.uid)
          .collection('sets')
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: statsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text('Loading...');
          }

          List<DocumentSnapshot<Map<String, dynamic>>> docs =
              snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data = docs[index].data()!;
              double correct = data['correct'].toDouble();
              double wrong = data['wrong'].toDouble();
              double total = correct + wrong;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(docs[index].id),
                      subtitle: Text(
                          'Correct: ${data['correct']}, Wrong: ${data['wrong']}'),
                    ),
                    Container(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              title: 'Correct',
                              value: 100 * (correct / total),
                              color: Colors.green,
                            ),
                            PieChartSectionData(
                              title: 'Wrong',
                              value: 100 * (wrong / total),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
