import 'package:firebase_core/firebase_core.dart';

/// Configuração pública do aplicativo Web "Frathéli Cafés Especiais".
///
/// Estes identificadores conectam o cliente ao projeto Firebase. A segurança
/// dos dados continua sendo controlada pela autenticação e pelas regras do
/// Firestore, nunca pelo sigilo desta configuração.
abstract final class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD08x2zGuRLm6jn9etxpI2ekQLUcPjbwWc',
    appId: '1:181804336876:web:1e9dc2ff249769c64e07c9',
    messagingSenderId: '181804336876',
    projectId: 'fratheli-cafes-especiais',
    authDomain: 'fratheli-cafes-especiais.firebaseapp.com',
    storageBucket: 'fratheli-cafes-especiais.firebasestorage.app',
    measurementId: 'G-4QGZHGWYPF',
  );
}
