import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'blocs/dashboard/dashboard_bloc.dart';
import 'blocs/dashboard/dashboard_event.dart';
import 'blocs/scanner/scanner_bloc.dart';
import 'blocs/scanner/scanner_event.dart';

import 'repositories/document_repository.dart';
import 'services/scanner_service.dart';

import 'ui/screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FolioApp());
}

class FolioApp extends StatelessWidget {
  const FolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [

        RepositoryProvider(
          create: (context) => DocumentRepository(),
        ),

        RepositoryProvider(
          create: (context) => ScannerService(),
        ),
      ],

      child: MultiBlocProvider(
        providers: [

          BlocProvider(
            create: (context) => DashboardBloc(
              repository: context.read<DocumentRepository>(),
            )..add(LoadDashboard()),
          ),

          BlocProvider(
            create: (context) => ScannerBloc(
              repository: context.read<DocumentRepository>(),
              scannerService: context.read<ScannerService>(),
            ),
          ),
        ],

        child: MaterialApp(

          debugShowCheckedModeBanner: false,

          title: 'Folio',

          themeMode: ThemeMode.dark,

          theme: ThemeData(

            useMaterial3: true,

            // BACKGROUND
            scaffoldBackgroundColor:
            const Color(0xFF12101C),

            // COLOR SCHEME
            colorScheme: ColorScheme.fromSeed(

              seedColor:
              const Color(0xFF7C5CFC),

              brightness: Brightness.dark,

              primary:
              const Color(0xFF7C5CFC),

              secondary:
              const Color(0xFFA78BFA),

              surface:
              const Color(0xFF1F1B2E),
            ),

            // TEXT
            textTheme:
            GoogleFonts.poppinsTextTheme(
              ThemeData.dark().textTheme,
            ).apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),

            // APP BAR
            appBarTheme: const AppBarTheme(

              backgroundColor:
              Color(0xFF12101C),

              elevation: 0,

              centerTitle: true,

              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),

              iconTheme: IconThemeData(
                color: Colors.white,
              ),
            ),

            // CARDS
            cardColor:
            const Color(0xFF1F1B2E),

            // FAB
            floatingActionButtonTheme:
            const FloatingActionButtonThemeData(

              backgroundColor:
              Color(0xFF7C5CFC),

              foregroundColor: Colors.white,
            ),

            // DIVIDER
            dividerColor:
            const Color(0xFF312A46),
          ),

          darkTheme: ThemeData(

            useMaterial3: true,

            scaffoldBackgroundColor:
            const Color(0xFF12101C),

            colorScheme: const ColorScheme.dark(

              primary:
              Color(0xFF7C5CFC),

              secondary:
              Color(0xFFA78BFA),

              surface:
              Color(0xFF1F1B2E),
            ),

            textTheme:
            GoogleFonts.poppinsTextTheme(
              ThemeData.dark().textTheme,
            ).apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),

            appBarTheme: const AppBarTheme(

              backgroundColor:
              Color(0xFF12101C),

              elevation: 0,

              centerTitle: true,

              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),

              iconTheme: IconThemeData(
                color: Colors.white,
              ),
            ),

            cardColor:
            const Color(0xFF1F1B2E),

            floatingActionButtonTheme:
            const FloatingActionButtonThemeData(

              backgroundColor:
              Color(0xFF7C5CFC),

              foregroundColor: Colors.white,
            ),

            dividerColor:
            const Color(0xFF312A46),
          ),

          home: const DashboardScreen(),
        ),
      ),
    );
  }
}