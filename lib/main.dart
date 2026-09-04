import 'package:flutter/material.dart';
import 'package:fratheli_cafe_web/services/auth_gate.dart';
import 'package:fratheli_cafe_web/theme/fratheli_colors.dart';
import 'package:fratheli_cafe_web/views/cadastro_page.dart';
import 'package:fratheli_cafe_web/views/login_page.dart';
import 'package:fratheli_cafe_web/views/meus_pedidos_page.dart';
import 'package:fratheli_cafe_web/views/minha_conta_page.dart';
import 'package:fratheli_cafe_web/views/order_details_page.dart';
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
    final base = ThemeData.light(useMaterial3: true);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Frathéli Cafés — Café com origem e identidade',
        theme: base.copyWith(
          useMaterial3: true,
          scaffoldBackgroundColor: FratheliColors.paper,
          colorScheme: base.colorScheme.copyWith(
            brightness: Brightness.light,
            primary: FratheliColors.gold,
            secondary: FratheliColors.gold2,
            surface: FratheliColors.surface,
            onSurface: FratheliColors.ink,
          ),
          textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
            headlineMedium: GoogleFonts.libreCaslonDisplay(
              fontSize: 34,
              fontWeight: FontWeight.w400,
              color: FratheliColors.ink,
            ),
            bodyMedium: GoogleFonts.dmSans(
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
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(color: FratheliColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(color: FratheliColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: BorderSide(
                color: FratheliColors.cherry.withOpacity(0.8),
                width: 1.6,
              ),
            ),
          ),
          cardTheme: CardThemeData(
            color: FratheliColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
              side: const BorderSide(color: FratheliColors.border),
            ),
          ),
          dividerColor: FratheliColors.border,
          chipTheme: ChipThemeData(
            backgroundColor: FratheliColors.surfaceAlt,
            selectedColor: FratheliColors.gold.withOpacity(0.25),
            labelStyle: const TextStyle(color: FratheliColors.text),
            side: const BorderSide(color: FratheliColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: FratheliColors.espresso,
              foregroundColor: FratheliColors.paper,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: FratheliColors.cherry,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: FratheliColors.paper,
            surfaceTintColor: Colors.transparent,
          ),
        ),
        home: const AuthGate(),
        routes: {
          '/home': (_) => const HomePage(),
          '/login': (_) => const LoginPage(),
          '/cadastro': (_) => const CadastroPage(),
          '/minha_conta': (_) => const MinhaContaPage(),
          '/meus_pedidos': (_) => const MeusPedidosPage(),
          '/pedido': (_) => const OrderDetailsPage(),
        },
      ),
    );
  }
}
