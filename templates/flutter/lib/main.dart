import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html; // Per aprire i link su web

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDxX17vw2ZRTFaaumfp16_FndG0X9HovH0",
      authDomain: "filt-ae054.firebaseapp.com",
      projectId: "filt-ae054",
      storageBucket: "filt-ae054.firebasestorage.app",
      messagingSenderId: "345664437296",
      appId: "1:345664437296:web:bf0531b4d99494b83681f5",
    ),
  );
  runApp(FiltApp());
}

class FiltApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red, useMaterial3: true),
      home: WelcomePage(),
    );
  }
}

// --- SCHERMATA INIZIALE ---
class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.train, size: 80, color: Colors.red),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage())),
              child: Text("LOGIN"),
              style: ElevatedButton.styleFrom(minimumSize: Size(200, 50)),
            ),
            SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrationPage())),
              child: Text("REGISTRAZIONE"),
              style: OutlinedButton.styleFrom(minimumSize: Size(200, 50)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PAGINA REGISTRAZIONE COMPLETA ---
class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nome = TextEditingController();
  final TextEditingController _cognome = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  final TextEditingController _matricola = TextEditingController();
  final TextEditingController _impianto = TextEditingController();
  
  String _azienda = 'RFI';
  String _regione = 'Lazio';
  String _ruolo = 'Personale Viaggiante';

  void _registra() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 1. Creazione utente su Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _pass.text,
        );

        // 2. Invio email di verifica
        await userCredential.user!.sendEmailVerification();

        // 3. Salvataggio dati extra su Firestore
        await FirebaseFirestore.instance.collection('Utenti').doc(userCredential.user!.uid).set({
          'nome': _nome.text,
          'cognome': _cognome.text,
          'email': _email.text,
          'matricola': _matricola.text,
          'azienda': _azienda,
          'regione': _regione,
          'ruolo': _ruolo,
          'impianto': _impianto.text,
          'approvato': false,
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Verifica la tua email per attivare l'account!")));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nuovo Account FILT")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nome, decoration: InputDecoration(labelText: "Nome")),
              TextFormField(controller: _cognome, decoration: InputDecoration(labelText: "Cognome")),
              TextFormField(controller: _matricola, decoration: InputDecoration(labelText: "Matricola")),
              DropdownButtonFormField<String>(
                value: _azienda,
                items: ['RFI', 'Trenitalia', 'FSI', 'Italo'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _azienda = v!),
                decoration: InputDecoration(labelText: "Azienda"),
              ),
              TextFormField(controller: _impianto, decoration: InputDecoration(labelText: "Impianto")),
              TextFormField(controller: _email, decoration: InputDecoration(labelText: "Email Aziendale")),
              TextFormField(controller: _pass, decoration: InputDecoration(labelText: "Password"), obscureText: true),
              SizedBox(height: 30),
              ElevatedButton(onPressed: _registra, child: Text("REGISTRATI"), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50))),
            ],
          ),
        ),
      ),
    );
  }
}

// --- PAGINA LOGIN ---
class LoginPage extends StatelessWidget {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Accedi")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _email, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: _pass, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text, password: _pass.text);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DrivePage()));
                } catch (e) {
                  print(e);
                }
              }, 
              child: Text("ENTRA")
            ),
          ],
        ),
      ),
    );
  }
}

// --- PAGINA DRIVE CON FILE CLICCABILI ---
class DrivePage extends StatefulWidget {
  @override
  _DrivePageState createState() => _DrivePageState();
}

class _DrivePageState extends State<DrivePage> {
  final String apiKey = "AIzaSyAISFL6BXeg0ZoWrZokAIwJnYlvKew_OEE";
  final String folderId = "132T5InVI5X12UR1cs_4oNs29ZBuYo9Iy";
  List files = [];

  @override
  void initState() { super.initState(); _caricaFile(); }

  Future<void> _caricaFile() async {
    final url = 'https://www.googleapis.com/drive/v3/files?q="$folderId"+in+parents&key=$apiKey&fields=files(id,name,webViewLink)';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      setState(() { files = json.decode(response.body)['files']; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Archivio Documenti"), backgroundColor: Colors.red),
      body: files.isEmpty 
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return ListTile(
                leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(file['name']),
                onTap: () {
                  // Apre il file direttamente nel browser
                  html.window.open(file['webViewLink'], '_blank');
                },
              );
            },
          ),
    );
  }
}
