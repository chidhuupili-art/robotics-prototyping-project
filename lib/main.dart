import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ionicons/ionicons.dart';
import 'endgame.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'signin.dart';
import 'providers.dart';
// import 'package:showcaseview/showcaseview.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter-based Scouting App for Robotics',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SignInPage(),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  int selectedIndex = 1;
  late List<Widget> _widgetOptions;

  Timer? _autosaveTimer;
  final Duration _autosaveDelay = const Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const RegularScoringPage(),
      const HomePageContent(),
      const EndgameScoringPage(),
    ];
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel(); // Cancel timer when the page is disposed
    super.dispose();
  }

  void _triggerAutosave() {
    if (selectedIndex != 1) {
      _autosaveTimer?.cancel();

      // Schedule a new timer to call _autosaveMatchData after the delay
      _autosaveTimer = Timer(_autosaveDelay, () {
        _autosaveMatchData();
      });

      // Optionally show a visual indicator to the user
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autosaving match data...'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _autosaveMatchData() async {
    final teamNum = ref.read(teamNumberProvider);
    final matchNum = ref.read(matchNumberProvider);
    final scoutName = ref.read(scoutNameProvider);
    final assemblyScore = ref.read(assemblyTrayNotifierProvider);
    final ovenScore = ref.read(ovenColumnNotifierProvider);
    final deliveryScore = ref.read(deliveryHatchNotifierProvider);
    final pizza5ftCount = ref.read(pizza5ftProvider);
    final pizza10ftCount = ref.read(pizza10ftProvider);
    final pizza15ftCount = ref.read(pizza15ftProvider);
    final pizza20ftCount = ref.read(pizza20ftProvider);
    final motorBurnCount = ref.read(motorBurnPenaltyProvider);
    final elevatorCount = ref.read(elevatorMalfunctionPenaltyProvider);
    final detachedCount = ref.read(mechanismDetachedPenaltyProvider);
    final humanCount = ref.read(humanPlayerPenaltyProvider);
    final robotCount = ref.read(robotOutsidePenaltyProvider);


    if (teamNum.isEmpty || matchNum.isEmpty) {
      // Don't autosave if match info is missing
      return;
    }

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);

    final totalRegularScore = assemblyScore + ovenScore + deliveryScore;
    final totalEndgameScore = (pizza5ftCount * 10) +
        (pizza10ftCount * 25) +
        (pizza15ftCount * 40) +
        (pizza20ftCount * 50);
    final totalPenaltyScore = (motorBurnCount * 20) +
        (elevatorCount * 5) +
        (detachedCount * 5) +
        (humanCount * 30) +
        (robotCount * 30);
    final totalScore = totalRegularScore + totalEndgameScore - totalPenaltyScore;

    final Map<String, dynamic> matchData = {
      'matchInfo': {
        'teamNumber': teamNum,
        'matchNumber': matchNum,
        'saveDate': formattedDate,
        'scoutName': scoutName,
      },
      'scoring': {
        'regular': {
          'assemblyTray': assemblyScore,
          'ovenColumn': ovenScore,
          'deliveryHatch': deliveryScore,
          'total': totalRegularScore
        },
        'endgame': {
          'pizza5ft': pizza5ftCount,
          'pizza10ft': pizza10ftCount,
          'pizza15ft': pizza15ftCount,
          'pizza20ft': pizza20ftCount,
          'total': totalEndgameScore,
        },
        'penalties': {
          'motorBurn': motorBurnCount,
          'elevatorMalfunction': elevatorCount,
          'mechanismDetached': detachedCount,
          'humanPlayer': humanCount,
          'robotOutside': robotCount,
          'totalPointsDeducted': totalPenaltyScore,
        },
        'finalTotal': totalScore,
      }
    };

    try {
      await _saveMatchFile(matchData, isAutosave: true);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match data autosaved successfully.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Autosave Error: $e');
    }
  }

  Future<void> _saveMatchFile(Map<String, dynamic> matchData, {bool isAutosave = false}) async {
    final teamNum = matchData['matchInfo']['teamNumber'] as String;
    final matchNum = matchData['matchInfo']['matchNumber'] as String;
    final formattedDate = matchData['matchInfo']['saveDate'] as String;

    final illegalCharacters = RegExp(r'[/\:*?<>|{}]');
    final safeTeamNum = teamNum.replaceAll(illegalCharacters, '_');
    final safeMatchNum = matchNum.replaceAll(illegalCharacters, '_');
    final String filename =
        'Team-${safeTeamNum}_Match-${safeMatchNum}_$formattedDate';

    final jsonEncoder = JsonEncoder.withIndent('  ');
    final String jsonContent = jsonEncoder.convert(matchData);

    final baseDirectory = await getApplicationDocumentsDirectory();

    final String newMatchDirectoryPath =
        '${baseDirectory.path}/MatchReports/PizzaPanic/$safeTeamNum/$safeMatchNum/$formattedDate';

    final newMatchDirectory = Directory(newMatchDirectoryPath);
    if (!await newMatchDirectory.exists()) {
      await newMatchDirectory.create(recursive: true);
    }

    final jsonFile = File('$newMatchDirectoryPath/$filename.json');
    await jsonFile.writeAsString(jsonContent);
    final String htmlContent = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Match Report: Team ${matchData['matchInfo']['teamNumber']}, Match ${matchData['matchInfo']['matchNumber']}</title>
    </head>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; margin: 20px; max-width: 800px; margin-left: auto; margin-right: auto; padding: 15px; border: 1px solid #ddd; border-radius: 8px;">
        
        <h1>Match Report: Team ${matchData['matchInfo']['teamNumber']} / Match ${matchData['matchInfo']['matchNumber']}</h1>
        <p>
          <strong style="color: #000;">Date:</strong> ${matchData['matchInfo']['saveDate']}<br>
          <strong style="color: #000;">Scout:</strong> ${matchData['matchInfo']['scoutName']}
        </p>
        
        <h2 style="color: #555; border-bottom: 1px solid #ccc; padding-bottom: 3px;">
            Regular Scoring (Total: ${matchData['scoring']['regular']['total']})
        </h2>
        <ul style="list-style-type: none; padding-left: 0;">
            <li style="background: #f9f9f9; margin-bottom: 8px; padding: 10px; border-radius: 5px;">
                <strong style="color: #000;">Assembly Tray:</strong> ${matchData['scoring']['regular']['assemblyTray']}
            </li>
            <li style="background: #f9f9f9; margin-bottom: 8px; padding: 10px; border-radius: 5px;">
                <strong style="color: #000;">Oven Column:</strong> ${matchData['scoring']['regular']['ovenColumn']}
            </li>
            <li style="background: #f9f9f9; margin-bottom: 8px; padding: 10px; border-radius: 5px;">
                <strong style="color: #000;">Delivery Hatch:</strong> ${matchData['scoring']['regular']['deliveryHatch']}
            </li>
        </ul>
        
        <h2 style="color: #555; border-bottom: 1px solid #ccc; padding-bottom: 3px;">
            Endgame Scoring (Total: ${matchData['scoring']['endgame']['total']})
        </h2>
        <ul style="list-style-type: none; padding-left: 0;">
            <li style="background: #f9f9f9; margin-bottom: 8px; padding: 10px; border-radius: 5px;">
                <strong style="color: #000;">5 ft Pizzas (10 pts):</strong> ${matchData['scoring']['endgame']['pizza5ft']}
            </li>
            <li style="background: #f9f9f9; margin-bottom: 8px; padding: 10px; border-radius: 5px;">
                <strong style="color: #000;">10 ft Pizzas (25 pts):</strong> ${matchData['scoring']['endgame']['pizza10ft']}
            </li>
            <li style="background: #f9f9f9; margin-bottom: 8px; padding: 10px; border-radius: 5px;">
                <strong style="color: #000;">15 ft Pizzas (40 pts):</strong> ${matchData['scoring']['endgame']['pizza15ft']}
            </li>
            <li style="background: #f9f9f9; margin-bottom: 8px; padding: 10px; border-radius: 5px;">
                <strong style="color: #000;">20+ ft Pizzas (50 pts):</strong> ${matchData['scoring']['endgame']['pizza20ft']}
            </li>
        </ul>

        <h2 style="color: #c0392b; border-bottom: 1px solid #ccc; padding-bottom: 3px;">
            Penalties (Total: -${matchData['scoring']['penalties']['totalPointsDeducted']})
        </h2>
        <ul style="list-style-type: none; padding-left: 0;">
            <li style="background: #f9f9f9; margin-bottom: 8px; padding: 10px; border-radius: 5px;">
                <strong style="color: #000;">Motor Burn (-20 pts):</strong> ${matchData['scoring']['penalties']['motorBurn']}
            </li>
            <li style="background: #f9f9f9; margin-bottom: 8px; padding: 10px; border-radius: 5px;">
                <strong style="color: #000;">Elevator Malfunction (-5 pts):</strong> ${matchData['scoring']['penalties']['elevatorMalfunction']}
            </li>
            <li style="background: #f9f9f9; margin-bottom: 8px; padding: 10px; border-radius: 5px;">
                <strong style="color: #000;">Mechanism Detached (-5 pts):</strong> ${matchData['scoring']['penalties']['mechanismDetached']}
            </li>
            <li style="background: #f9f9f9; margin-bottom: 8px; padding: 10px; border-radius: 5px;">
                <strong style="color: #000;">Human Player Reaches In (-30 pts):</strong> ${matchData['scoring']['penalties']['humanPlayer']}
            </li>
            <li style="background: #f9f9f9; margin-bottom: 8px; padding: 10px; border-radius: 5px;">
                <strong style="color: #000;">Robot Outside Field (-30 pts):</strong> ${matchData['scoring']['penalties']['robotOutside']}
            </li>
        </ul>
        
        <h2 style="color: #555; border-bottom: 1px solid #ccc; padding-bottom: 3px;">
            Final Score
        </h2>
        <ul style="list-style-type: none; padding-left: 0;">
            <li style="background: #f9f9f9; margin-bottom: 8px; padding: 10px; border-radius: 5px;">
                <strong style="color: #000;">Total Score:</strong> ${matchData['scoring']['finalTotal']}
            </li>
        </ul>
    </body>
    </html>
     """;
    final htmlFile = File('$newMatchDirectoryPath/$filename.html');
    await htmlFile.writeAsString(htmlContent);

    if (!mounted) return;

    if (!isAutosave) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('HTML and JSON saved to ${newMatchDirectory.path}')));

      await _openFolder(newMatchDirectory.path);
    }
  }

  Future<void> _saveMatchData() async {
    final teamNum = ref.read(teamNumberProvider);
    final matchNum = ref.read(matchNumberProvider);
    final scoutName = ref.read(scoutNameProvider);
    final assemblyScore = ref.read(assemblyTrayNotifierProvider);
    final ovenScore = ref.read(ovenColumnNotifierProvider);
    final deliveryScore = ref.read(deliveryHatchNotifierProvider);

    final pizza5ftCount = ref.read(pizza5ftProvider);
    final pizza10ftCount = ref.read(pizza10ftProvider);
    final pizza15ftCount = ref.read(pizza15ftProvider);
    final pizza20ftCount = ref.read(pizza20ftProvider);

    final motorBurnCount = ref.read(motorBurnPenaltyProvider);
    final elevatorCount = ref.read(elevatorMalfunctionPenaltyProvider);
    final detachedCount = ref.read(mechanismDetachedPenaltyProvider);
    final humanCount = ref.read(humanPlayerPenaltyProvider);
    final robotCount = ref.read(robotOutsidePenaltyProvider);

    if (teamNum.isEmpty || matchNum.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter TEAM and MATCH Number!')));
      return;
    }
    if (scoutName.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Scout Name is missing. Please sign in again.')));
      return;
    }

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);

    final totalRegularScore = assemblyScore + ovenScore + deliveryScore;
    final totalEndgameScore = (pizza5ftCount * 10) +
        (pizza10ftCount * 25) +
        (pizza15ftCount * 40) +
        (pizza20ftCount * 50);
    final totalPenaltyScore = (motorBurnCount * 20) +
        (elevatorCount * 5) +
        (detachedCount * 5) +
        (humanCount * 30) +
        (robotCount * 30);

    final totalScore = totalRegularScore + totalEndgameScore - totalPenaltyScore;

    final Map<String, dynamic> matchData = {
      'matchInfo': {
        'teamNumber': teamNum,
        'matchNumber': matchNum,
        'saveDate': formattedDate,
        'scoutName': scoutName,
      },
      'scoring': {
        'regular': {
          'assemblyTray': assemblyScore,
          'ovenColumn': ovenScore,
          'deliveryHatch': deliveryScore,
          'total': totalRegularScore
        },
        'endgame': {
          'pizza5ft': pizza5ftCount,
          'pizza10ft': pizza10ftCount,
          'pizza15ft': pizza15ftCount,
          'pizza20ft': pizza20ftCount,
          'total': totalEndgameScore,
        },
        'penalties': {
          'motorBurn': motorBurnCount,
          'elevatorMalfunction': elevatorCount,
          'mechanismDetached': detachedCount,
          'humanPlayer': humanCount,
          'robotOutside': robotCount,
          'totalPointsDeducted': totalPenaltyScore,
        },
        'finalTotal': totalScore,
      }
    };

    try {
      await _saveMatchFile(matchData, isAutosave: false);

      ref.read(assemblyTrayNotifierProvider.notifier).set(0);
      ref.read(ovenColumnNotifierProvider.notifier).set(0);
      ref.read(deliveryHatchNotifierProvider.notifier).set(0);
      ref.read(teamNumberProvider.notifier).state = '';
      ref.read(matchNumberProvider.notifier).state = '';
      ref.read(scoutNameProvider.notifier).state = '';
      ref.read(pizza5ftProvider.notifier).state = 0;
      ref.read(pizza10ftProvider.notifier).state = 0;
      ref.read(pizza15ftProvider.notifier).state = 0;
      ref.read(pizza20ftProvider.notifier).state = 0;
      ref.read(motorBurnPenaltyProvider.notifier).state = 0;
      ref.read(elevatorMalfunctionPenaltyProvider.notifier).state = 0;
      ref.read(mechanismDetachedPenaltyProvider.notifier).state = 0;
      ref.read(humanPlayerPenaltyProvider.notifier).state = 0;
      ref.read(robotOutsidePenaltyProvider.notifier).state = 0;

    } catch (e) {
      print('Error saving files: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving file: $e')));
    }
  }
  Future<void> _exportData() async {
    try {
      final baseDirectory = await getApplicationDocumentsDirectory();
      final matchReportsPath =
          '${baseDirectory.path}/MatchReports/PizzaPanic';
      final matchReportsDir = Directory(matchReportsPath);

      if (!await matchReportsDir.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: MatchReports directory not found. Save a match first!')));
        await _openFolder(baseDirectory.path);
        return;
      }

      final List<Map<String, dynamic>> allMatches = [];
      await for (final entity
      in matchReportsDir.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final fileContent = await entity.readAsString();
            final jsonData = jsonDecode(fileContent) as Map<String, dynamic>;
            allMatches.add(jsonData);
          } catch (e) {
            print('Could not read or parse file ${entity.path}: $e');
          }
        }
      }

      if (allMatches.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No match data found to export.')));
        return;
      }

      final timestamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      final exportFileName = 'PizzaPanic_Export_$timestamp.json';
      final exportFile = File('${baseDirectory.path}/$exportFileName');

      final jsonEncoder = JsonEncoder.withIndent('  ');
      final String exportJson = jsonEncoder.convert(allMatches);
      await exportFile.writeAsString(exportJson);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Exported ${allMatches.length} matches to ${exportFile.path}')),
      );
      await _openFolder(baseDirectory.path);

    } catch (e) {
      print('Error exporting data: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error exporting data: $e')));
    }
  }
  Future<void> _openFolder(String path) async {
    final uri = Uri.directory(path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open folder: $path')));
    }
  }

  void _loadMatchToState(Map<String, dynamic> matchData) {
    final matchInfo = matchData['matchInfo'];
    final scoring = matchData['scoring'];
    final regular = scoring['regular'];
    final endgame = scoring['endgame'];
    final penalties = scoring['penalties'];

    // Update Match Info
    ref.read(teamNumberProvider.notifier).state = matchInfo['teamNumber'].toString();
    ref.read(matchNumberProvider.notifier).state = matchInfo['matchNumber'].toString();
    ref.read(scoutNameProvider.notifier).state = matchInfo['scoutName'].toString();

    // Update Regular Scoring
    ref.read(assemblyTrayNotifierProvider.notifier).set(regular['assemblyTray'] as int);
    ref.read(ovenColumnNotifierProvider.notifier).set(regular['ovenColumn'] as int);
    ref.read(deliveryHatchNotifierProvider.notifier).set(regular['deliveryHatch'] as int);

    // Update Endgame Scoring (Pizza Counts)
    ref.read(pizza5ftProvider.notifier).state = endgame['pizza5ft'] as int;
    ref.read(pizza10ftProvider.notifier).state = endgame['pizza10ft'] as int;
    ref.read(pizza15ftProvider.notifier).state = endgame['pizza15ft'] as int;
    ref.read(pizza20ftProvider.notifier).state = endgame['pizza20ft'] as int;

    // Update Penalties
    ref.read(motorBurnPenaltyProvider.notifier).state = penalties['motorBurn'] as int;
    ref.read(elevatorMalfunctionPenaltyProvider.notifier).state = penalties['elevatorMalfunction'] as int;
    ref.read(mechanismDetachedPenaltyProvider.notifier).state = penalties['mechanismDetached'] as int;
    ref.read(humanPlayerPenaltyProvider.notifier).state = penalties['humanPlayer'] as int;
    ref.read(robotOutsidePenaltyProvider.notifier).state = penalties['robotOutside'] as int;
  }

  Future<void> _saveImportedMatch(Map<String, dynamic> matchData) async {
    final teamNum = matchData['matchInfo']['teamNumber'] as String;
    final matchNum = matchData['matchInfo']['matchNumber'] as String;
    final formattedDate = matchData['matchInfo']['saveDate'] as String;

    final illegalCharacters = RegExp(r'[/\:*?<>|{}]');
    final safeTeamNum = teamNum.replaceAll(illegalCharacters, '_');
    final safeMatchNum = matchNum.replaceAll(illegalCharacters, '_');
    final String filename =
        'Team-${safeTeamNum}_Match-${safeMatchNum}_$formattedDate';

    final jsonEncoder = JsonEncoder.withIndent('  ');
    final String jsonContent = jsonEncoder.convert(matchData);

    try {
      final baseDirectory = await getApplicationDocumentsDirectory();

      final String newMatchDirectoryPath =
          '${baseDirectory.path}/MatchReports/PizzaPanic/$safeTeamNum/$safeMatchNum/$formattedDate';

      final newMatchDirectory = Directory(newMatchDirectoryPath);
      if (!await newMatchDirectory.exists()) {
        await newMatchDirectory.create(recursive: true);
      }

      final jsonFile = File('$newMatchDirectoryPath/$filename.json');
      await jsonFile.writeAsString(jsonContent);

    } catch (e) {
      print('Error saving imported match (T$teamNum M$matchNum): $e');
    }
  }
  Future<void> _importData() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected for import.')));
      return;
    }

    final filePath = result.files.single.path!;
    final importFile = File(filePath);
    final fileName = result.files.single.name;

    try {
      final String jsonString = await importFile.readAsString();
      final decodedContent = jsonDecode(jsonString);

      final List<Map<String, dynamic>> matchesToImport;

      if (decodedContent is List) {
        matchesToImport = decodedContent
            .whereType<Map<String, dynamic>>()
            .toList();

      } else if (decodedContent is Map<String, dynamic>) {
        matchesToImport = [decodedContent];

      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid JSON structure: Expected a list of matches or a single match object.')));
        return;
      }

      if (matchesToImport.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid match data found in the file.')));
        return;
      }

      int successCount = 0;
      Map<String, dynamic>? lastImportedMatch;

      for (var matchJson in matchesToImport) {
        await _saveImportedMatch(matchJson);
        successCount++;
        lastImportedMatch = matchJson;
      }

      if (lastImportedMatch != null) {
        _loadMatchToState(lastImportedMatch);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Successfully imported $successCount matches from $fileName. Showing last match data.')
          ));

      final baseDirectory = await getApplicationDocumentsDirectory();
      await _openFolder('${baseDirectory.path}/MatchReports/PizzaPanic');

    } on FileSystemException catch (e) {
      print('File System Error during import: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error reading file: Check permissions or if the file is locked.')));
    } catch (e) {
      print('Error during JSON processing: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing import file: $fileName is likely not valid JSON or data structure is incorrect.')));
    }
  }

  Future<void> _logOut() async {
    ref.read(scoutNameProvider.notifier).state = '';
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInPage()),
            (Route<dynamic> route) => false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Logged Out')));
  }

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (selectedIndex != 1) {
      ref.watch(teamNumberProvider);
      ref.watch(matchNumberProvider);
      ref.watch(assemblyTrayNotifierProvider);
      ref.watch(ovenColumnNotifierProvider);
      ref.watch(deliveryHatchNotifierProvider);
      ref.watch(pizza5ftProvider);
      ref.watch(pizza10ftProvider);
      ref.watch(pizza15ftProvider);
      ref.watch(pizza20ftProvider);
      ref.watch(motorBurnPenaltyProvider);
      ref.watch(elevatorMalfunctionPenaltyProvider);
      ref.watch(mechanismDetachedPenaltyProvider);
      ref.watch(humanPlayerPenaltyProvider);
      ref.watch(robotOutsidePenaltyProvider);

      //_triggerAutosave();
    }
    final scoutName = ref.watch(scoutNameProvider);
    final List<String> pageTitles = <String>[
      'Regular Scoring',
      scoutName.isEmpty ? 'Home' : "$scoutName's Home",
      'Endgame Scoring',
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          pageTitles[selectedIndex],
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (String value) {
              if (value == 'save') {
                _saveMatchData();
              } else if (value == 'export') {
                _exportData();
              } else if (value == 'import') {
                _importData();
              } else if (value == 'logout') {
                _logOut();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.save, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Save Match'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Export All Data'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Import Data'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Log Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _widgetOptions.elementAt(selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_rounded),
            label: 'Match',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_rounded),
            label: 'Endgame',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomePageContent extends ConsumerWidget {
  const HomePageContent({
    super.key,
  });
  void _resetPenalties(WidgetRef ref) {
    ref.read(motorBurnPenaltyProvider.notifier).state = 0;
    ref.read(elevatorMalfunctionPenaltyProvider.notifier).state = 0;
    ref.read(mechanismDetachedPenaltyProvider.notifier).state = 0;
    ref.read(humanPlayerPenaltyProvider.notifier).state = 0;
    ref.read(robotOutsidePenaltyProvider.notifier).state = 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Manual Data Entry',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            ref: ref,
            label: 'Team Number',
            provider: teamNumberProvider,
          ),
          _buildTextField(
            ref: ref,
            label: 'Match Number',
            provider: matchNumberProvider,
          ),
          const Divider(height: 30),
          _buildScoreTextField(
            ref: ref,
            label: 'Assembly Tray Score',
            provider: assemblyTrayNotifierProvider,
            icon: Icons.inventory_2_outlined,
          ),
          _buildScoreTextField(
            ref: ref,
            label: 'Oven Column Score',
            provider: ovenColumnNotifierProvider,
            icon: Icons.whatshot_outlined,
          ),
          _buildScoreTextField(
            ref: ref,
            label: 'Delivery Hatch Score',
            provider: deliveryHatchNotifierProvider,
            icon: Icons.local_shipping_outlined,
          ),
          const Divider(height: 30),
          _buildPizzaTextField(
            ref: ref,
            label: '5 ft Pizza Count',
            provider: pizza5ftProvider,
            icon: Ionicons.pizza,
          ),
          _buildPizzaTextField(
            ref: ref,
            label: '10 ft Pizza Count',
            provider: pizza10ftProvider,
            icon: Ionicons.pizza,
          ),
          _buildPizzaTextField(
            ref: ref,
            label: '15 ft Pizza Count',
            provider: pizza15ftProvider,
            icon: Ionicons.pizza,
          ),
          _buildPizzaTextField(
            ref: ref,
            label: '20 ft Pizza Count',
            provider: pizza20ftProvider,
            icon: Ionicons.pizza,
          ),
          const Divider(height: 40),
          // Removed Showcase wrapper
          Text(
            'Penalties',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildPenaltyRow(
            ref: ref,
            label: 'Motor Burn (-20)',
            provider: motorBurnPenaltyProvider,
          ),
          _buildPenaltyRow(
            ref: ref,
            label: 'Elevator Malfunction (-5)',
            provider: elevatorMalfunctionPenaltyProvider,
          ),
          _buildPenaltyRow(
            ref: ref,
            label: 'Mechanism Detached (-5)',
            provider: mechanismDetachedPenaltyProvider,
          ),
          _buildPenaltyRow(
            ref: ref,
            label: 'Human Enters Match Area (-30)',
            provider: humanPlayerPenaltyProvider,
          ),
          _buildPenaltyRow(
            ref: ref,
            label: 'Robot Leaves Match Area (-30)',
            provider: robotOutsidePenaltyProvider,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _resetPenalties(ref),
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Penalties'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenaltyRow({
    required WidgetRef ref,
    required String label,
    required StateProvider<int> provider,
  }) {
    final count = ref.watch(provider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle),
                iconSize: 32,
                color: Colors.green,
                onPressed: () => ref.read(provider.notifier).state++,
              ),
              SizedBox(
                width: 30,
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle),
                iconSize: 32,
                color: Colors.red,
                onPressed: () {
                  if (ref.read(provider) > 0) {
                    ref.read(provider.notifier).state--;
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required WidgetRef ref,
    required String label,
    required StateProvider<String> provider,
  }) {
    final value = ref.watch(provider);
    final controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: controller.text.length));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: label == 'Team Number'
              ? const Icon(Icons.people_alt)
              : const Icon(Icons.tag),
          hintText: 'Enter $label',
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (newValue) {
          ref.read(provider.notifier).state = newValue;
        },
      ),
    );
  }

  Widget _buildScoreTextField({
    required WidgetRef ref,
    required String label,
    required NotifierProvider<ScoreNotifier, int> provider,
    required IconData icon,
  }) {
    final value = ref.watch(provider);
    final controller = TextEditingController(text: value.toString());
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: controller.text.length));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: 'Enter score (e.g., 15)',
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (newValue) {
          ref.read(provider.notifier).set(int.tryParse(newValue) ?? 0);
        },
      ),
    );
  }

  Widget _buildPizzaTextField({
    required WidgetRef ref,
    required String label,
    required StateProvider<int> provider,
    required IconData icon,
  }) {
    final value = ref.watch(provider);
    final controller = TextEditingController(text: value.toString());
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: controller.text.length));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: 'Enter count (e.g., 3)',
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (newValue) {
          ref.read(provider.notifier).state = int.tryParse(newValue) ?? 0;
        },
      ),
    );
  }
}

class RegularScoringPage extends ConsumerWidget {

  const RegularScoringPage({
    super.key,
  });

  void _resetCounters(WidgetRef ref) {
    ref.read(assemblyTrayNotifierProvider.notifier).set(0);
    ref.read(ovenColumnNotifierProvider.notifier).set(0);
    ref.read(deliveryHatchNotifierProvider.notifier).set(0);
    ref.read(teamNumberProvider.notifier).state = '';
    ref.read(matchNumberProvider.notifier).state = '';
  }

  Widget _buildDoubleButton({
    required WidgetRef ref,
    required String label,
    required int points,
    required NotifierProvider<ScoreNotifier, int> provider,
    required IconData icon,
  }) {
    final score = ref.watch(provider);
    final theme = Theme.of(ref.context);

    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle),
              iconSize: 40.0,
              color: Colors.green,
              onPressed: () {
                ref.read(provider.notifier).increment(points);
              },
            ),
            const SizedBox(
              width: 15,
            ),
            SizedBox(
              width: 170,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: theme.colorScheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '$label (+$points pts)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  Text(
                    score.toString(),
                    style: theme.textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            IconButton(
              icon: const Icon(Icons.remove_circle),
              iconSize: 28.0,
              color: Colors.red,
              onPressed: () {
                final currentScore = ref.read(provider);
                final newScore = currentScore - points;
                ref.read(provider.notifier).set(newScore < 0 ? 0 : newScore);
              },
            )
          ],
        ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamNum = ref.watch(teamNumberProvider);
    final matchNum = ref.watch(matchNumberProvider);

    final teamController = TextEditingController(text: teamNum);
    final matchController = TextEditingController(text: matchNum);

    teamController.selection =
        TextSelection.fromPosition(TextPosition(offset: teamController.text.length));
    matchController.selection =
        TextSelection.fromPosition(TextPosition(offset: matchController.text.length));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          FractionallySizedBox(
            widthFactor: 0.6,
            child: TextField(
              controller: teamController,
              decoration: const InputDecoration(
                labelText: 'Team Number',
                hintText: 'Enter team # (e.g. 2046)',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                ref.read(teamNumberProvider.notifier).state = value;
              },
            ),
          ),
          FractionallySizedBox(
            widthFactor: 0.6,
            child: TextField(
              controller: matchController,
              decoration: const InputDecoration(
                labelText: 'Match Number',
                hintText: 'Enter match # (e.g. 3)',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                ref.read(matchNumberProvider.notifier).state = value;
              },
            ),
          ),
          const SizedBox(height: 30),
          _buildDoubleButton(
            ref: ref,
            label: ' Assembly Tray',
            points: 3,
            provider: assemblyTrayNotifierProvider,
            icon: Icons.inventory_2_outlined,
          ),
          _buildDoubleButton(
            ref: ref,
            label: ' Oven Column',
            points: 5,
            provider: ovenColumnNotifierProvider,
            icon: Icons.whatshot_outlined,
          ),
          _buildDoubleButton(
            ref: ref,
            label: ' Delivery Hatch',
            points: 8,
            provider: deliveryHatchNotifierProvider,
            icon: Icons.local_shipping_outlined,
          ),
          const SizedBox(height: 30),
          TextButton.icon(
            onPressed: () => _resetCounters(ref),
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Regular Scores'),
          ),
        ],
      ),
    );
  }
}
// An app to manage scouting data with:
  // - an export function (If a MatchReports folder already exists in the specified directory)
  // - an import function (If a correctly formatted json file is selected through the file picker)
  // - a save match (Saves a folder with multiple folders nested within, the last folder containing 
  //   an HTML and JSON file with the data collected through the app)
//  When you open the app, you'll be prompted to type your name, which will be displayed in the appBar
//  and saved in exported files.
// Once logged in, you'll be taken to the Home Page, where if needed, you can manually enter match data.
// If that isn't necessary, you could click on the menu items on either side of the Home Page icon, which
// take you to pages more specific to the part of the game.
  // In the Match Page, there are two TextFieldControllers:
  //    = Team Number
  //      - no letters are allowed
  //      - it will be included in the JSON file exported as "teamNumber" when you click 
  //        save, or export match.
  //      - it will be part of the overview in the HTML file exported when you click 
  //        save, or export match.
  //      - it will be deleted after the data has been exported
  //    = Match Number
  //      - no letters are allowed
  //      - it will be included in the JSON file exported as "matchNumber" when you click 
  //        save, or export match.
  //      - it will be part of the overview in the HTML file exported when you click 
  //        save, or export match.
  //      - it will be deleted after the data has been exported
  // The data from these controllers will be saved in an array called "matchInfo"
// There is also a button at the bottom that resets the values of each score type to zero, the default value.
// Again, the scores will automatically be reset after export, so unless there was some severe mishap, that
// button shouldn't be used.
// Instead, use the decrement buttons.

// === Match Page Description End ===

// In the Endgame Page, there are three Scoring Rows:
    // =  The Ten Feet Counter
        // - increments 25 points into the totalEndgameScore, which is added into the totalScore
    // = The Fifteen Feet Counter
        // - increments 40 points into the totalEndgameScore, which is added into the totalScore
    // =  The Twenty Plus Feet Counter
        // - increments 40 points into the totalEndgameScore, which is added into the totalScore 
    
// === Endgame Page Description End ===
  
// Other Functionalities
  // The vertical menu located in the top right, when clicked, expands into a menu consisting of three options:
      // = Save Match
              // clicking this button saves match data to a defined folder, which can later be imported using
              // the import button
      // = Export All Data
              // clicking this button exports previous data to the previously defined folder, and returns an error
              // the specified folder isn't found in the directory
      // = Import All Data
              // clicking this button opens a file picker, which allows the user to select any json file in the right
              // format, and with the necessary information within it; otherwise, an error is displayed.
      // = Log Out
              // clicking this button will clear the scoutName variable, or in other words, set its value to an empty
              // string; data previously entered will remain in the app, and only clear once exported or manually reset.
