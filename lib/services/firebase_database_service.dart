import 'package:firebase_database/firebase_database.dart';

class FirebaseDatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Exemple de méthode pour lire des données
  Future<dynamic> getData(String path) async {
    DatabaseEvent event = await _database.child(path).once();
    return event.snapshot.value;
  }

  // Exemple de méthode pour écrire des données
  Future<void> setData(String path, Map<String, dynamic> data) async {
    await _database.child(path).set(data);
  }

  // Exemple de méthode pour mettre à jour des données
  Future<void> updateData(String path, Map<String, dynamic> data) async {
    await _database.child(path).update(data);
  }

  // Exemple de méthode pour supprimer des données
  Future<void> deleteData(String path) async {
    await _database.child(path).remove();
  }

  // Exemple de méthode pour écouter les changements en temps réel
  Stream<DatabaseEvent> streamData(String path) {
    return _database.child(path).onValue;
  }
}
