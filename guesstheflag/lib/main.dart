import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/settings': (context) => SettingsScreen(),
        '/stats': (context) => StatsScreen(),

        '/login': (context) => LoginScreen(), // Hinzugefügt
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  String? collectionName;
  HomeScreen({this.collectionName});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> questions = [
    {'flag': 'https://flagcdn.com/256x192/ua.png', 'country': 'Ukraine'},
    {'flag': 'https://flagcdn.com/256x192/de.png', 'country': 'Germany'},
    // Füge weitere Flaggen und Länder hinzu
  ];
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final FirebaseAuth auth = FirebaseAuth.instance; // Für die Authentifizierung
  String selectedType = 'continents'; // Default-Typ
  String selectedEntity = 'asia'; // Default-Entität
  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        // Nutzer ist angemeldet, Daten laden
        fetchData(selectedType, selectedEntity);
      }
    });
  }

  fetchData(String type, String name) async {
    String parentCollection = 'flaggensets'; // Parent collection
    String collectionToFetch =
        widget.collectionName ?? name; // The specific sub-collection you want
    widget.collectionName = collectionToFetch;

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Zugriff auf ein bestimmtes Dokument in einer Collection
    DocumentReference docRef =
        _firestore.collection(parentCollection).doc(type);

    // Zugriff auf eine Subcollection innerhalb dieses Dokuments
    CollectionReference subCollectionRef = docRef.collection(name);

    // Dokumente aus der Subcollection abrufen
    QuerySnapshot querySnapshot = await subCollectionRef.get();

    // Durch die Dokumente iterieren und Daten anzeigen

    // Navigate to the specific sub-collection under 'flaggensets'
    List<Map<String, dynamic>> fetchedQuestions = [];

    for (var documentSnapshot in querySnapshot.docs) {
      Map<String, dynamic> docData =
          documentSnapshot.data() as Map<String, dynamic>;

      fetchedQuestions.add({
        'flag': docData['flaglink'] ?? '',
        'country': docData['flagname'] ?? '',
        'options': docData['multipleanswers'] ?? [],
      });
    }
    print(fetchedQuestions);
    setState(() {
      questions = fetchedQuestions;
      currentQuestion = questions.length - 1;
    });
  }

  int currentQuestion = 0;
  int wrongAttempts = 0;
  bool showCorrectAnswer = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: IconButton(
          icon: Icon(Icons.show_chart),
          onPressed: () {
            Navigator.pushNamed(context, '/stats');
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              final selectedCollection = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
              if (selectedCollection != null) {
                Map<String, String> selectedMap =
                    selectedCollection as Map<String, String>;
                String newType = selectedMap['type']!;
                String newName = selectedMap['name']!;
                fetchData(newType,
                    newName); // Daten mit den neuen Einstellungen erneut laden
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.network(questions[currentQuestion]['flag']!),
            SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 columns
                childAspectRatio: 3 / 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: questions.isNotEmpty &&
                      questions[currentQuestion]['options'] != null
                  ? questions[currentQuestion]['options'].length
                  : 0,
              itemBuilder: (context, index) {
                return buildOptionBox(
                    questions[currentQuestion]['options'][index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  void goToNextQuestion() {
    int correct = 0;
    int wrong = 0;

    if (wrongAttempts >= 2) {
      wrong = 1;
    } else {
      correct = 1;
    }

    updateStats(widget.collectionName!, correct, wrong);

    setState(() {
      currentQuestion = (currentQuestion + 1) % questions.length;
      wrongAttempts = 0;
      showCorrectAnswer = false;
    });

    if (currentQuestion >= questions.length - 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Set abgeschlossen!"),
          content: Text("Du hast diesen Satz von Flaggen abgeschlossen."),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"))
          ],
        ),
      );
    }
  }

  void updateStats(String setId, int correct, int wrong) async {
    User? currentUser = auth.currentUser;
    if (currentUser == null) return; // Falls nicht angemeldet, beenden

    var userStats = firestore.collection('userStats').doc(currentUser.uid);
    var setStats = userStats.collection('sets').doc(setId);

    DocumentSnapshot currentStats = await setStats.get();

    if (currentStats.exists) {
      int newCorrect = currentStats.get('correct') + correct;
      int newWrong = currentStats.get('wrong') + wrong;

      await setStats.set({
        'correct': newCorrect,
        'wrong': newWrong,
      }, SetOptions(merge: true));
    } else {
      await setStats.set({
        'correct': correct,
        'wrong': wrong,
      });
    }
  }

  Widget buildOptionBox(String countryName) {
    return GestureDetector(
      onTap: () {
        int correct = 0;
        int wrong = 0;
        if (countryName == questions[currentQuestion]['country']) {
          int correct = 1; // Setze die Variable "correct" auf 1
          int wrong = 0; // Setze die Variable "wrong" auf 0
          updateStats(widget.collectionName!, correct,
              wrong); // Aktualisiere die Statistik
          goToNextQuestion(); // Gehe zur nächsten Frage, wenn die Antwort korrekt ist
        } else {
          wrongAttempts++; // Inkrementiere die Anzahl der falschen Versuche
          if (wrongAttempts >= 2) {
            setState(() {
              showCorrectAnswer = true; // Zeige die korrekte Antwort an
            });
            Timer(Duration(seconds: 2), () {
              int correct = 0; // Setze die Variable "correct" auf 0
              int wrong = 1; // Setze die Variable "wrong" auf 1
              updateStats(widget.collectionName!, correct,
                  wrong); // Aktualisiere die Statistik
              goToNextQuestion(); // Zeige die korrekte Antwort für 2 Sekunden an, dann gehe zur nächsten Frage
            });
          }
        }
      },
      child: Container(
        padding: EdgeInsets.all(8), // Reduziertes Padding
        decoration: BoxDecoration(
          border: Border.all(
              color: showCorrectAnswer &&
                      countryName == questions[currentQuestion]['country']
                  ? Colors.green
                  : Colors.blueAccent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          // Text im Container zentrieren
          child: Text(
            countryName,
            softWrap: true,
            textAlign: TextAlign.center, // Text zentrieren
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }
}
