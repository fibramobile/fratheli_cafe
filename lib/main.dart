import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'controllers/cart_controller.dart';
import 'views/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FratheliApp());
}

class FratheliApp extends StatelessWidget {
  const FratheliApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Frathéli Café — Microlotes artesanais de montanha',
        theme: base.copyWith(
          colorScheme: base.colorScheme.copyWith(
            primary: const Color(0xFFD4AF37),
            secondary: const Color(0xFFB58A2D),
          ),
          textTheme: GoogleFonts.interTextTheme(base.textTheme),
          scaffoldBackgroundColor: const Color(0xFF0B0B0C),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}
