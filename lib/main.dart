import 'package:flutter/material.dart';
import 'package:fratheli_cafe_web/services/auth_gate.dart';
import 'package:fratheli_cafe_web/theme/fratheli_colors.dart';
import 'package:fratheli_cafe_web/views/cadastro_page.dart';
import 'package:fratheli_cafe_web/views/login_page.dart';
import 'package:fratheli_cafe_web/views/minha_conta_page.dart';
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
      child:
          /*
      MaterialApp(
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
  */
      MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Frathéli Café — Microlotes artesanais de montanha',
        theme: base.copyWith(
          useMaterial3: true,
          scaffoldBackgroundColor: FratheliColors.bg,
          colorScheme: base.colorScheme.copyWith(
            brightness: Brightness.light,
            primary: FratheliColors.gold,
            secondary: FratheliColors.gold2,
            surface: FratheliColors.surface,
            background: FratheliColors.bg,
            onBackground: FratheliColors.text,
            onSurface: FratheliColors.text,
          ),
          textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
            headlineMedium: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: FratheliColors.text,
            ),
            bodyMedium: GoogleFonts.inter(
              fontSize: 16,
              color: FratheliColors.text2,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: FratheliColors.surface,
            labelStyle: const TextStyle(color: FratheliColors.text2),
            hintStyle: const TextStyle(color: FratheliColors.text3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: FratheliColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: FratheliColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: FratheliColors.gold.withOpacity(0.8),
                width: 1.6,
              ),
            ),
          ),
          cardTheme: CardTheme(
            color: FratheliColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: FratheliColors.border),
            ),
          ),
          dividerColor: FratheliColors.border,
          chipTheme: ChipThemeData(
            backgroundColor: FratheliColors.surfaceAlt,
            selectedColor: FratheliColors.gold.withOpacity(0.25),
            labelStyle: const TextStyle(color: FratheliColors.text),
            side: const BorderSide(color: FratheliColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: FratheliColors.gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: FratheliColors.gold2,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),

        // ✅ troque aqui
        home: const AuthGate(),

        // ✅ adicione rotas
        routes: {
          '/home': (_) => const HomePage(),
          '/login': (_) => const LoginPage(),
          '/cadastro': (_) => const CadastroPage(),
          '/minha_conta': (_) => const MinhaContaPage(),
        },
      )


    );
  }
}
