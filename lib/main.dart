import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'game_logic.dart';
import 'firebase_options.dart';
import 'country_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(Game2048App());
}

class Game2048App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048 Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      String country = await CountryService.fetchCountry();
      if (['au', 'sg', 'id', 'my'].contains(country.toLowerCase())) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WebView()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Game2048Screen(country: country),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE4E2DD),
      body: Center(
        child: Image.asset(
          'icons/2048.png',
          width: 250,
          height: 250,
        ),
      ),
    );
  }
}



class Game2048Screen extends StatefulWidget {

  final String country;

  Game2048Screen({required this.country});
  @override
  _Game2048ScreenState createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  late Game2048 game;
  String country = 'Fetching...';
  bool isRestricted = false;
  bool gameOver = false;
  bool nameInputVisible = false;
  TextEditingController nameController = TextEditingController();
  final List<String> restrictedCountries = ['my', 'sg', 'au', 'id'];

  @override
  void initState() {
    super.initState();
    game = Game2048(gridSize: 4);
    setState(() {
      country= widget.country;
    });
  }

  Future<void> savePlayerDataToFirebase(String name, int score, String country) async {
    try {
      final playersRef = FirebaseFirestore.instance.collection('players');
      await playersRef.add({
        'name': name,
        'score': score,
        'country': country,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Player data saved to Firestore');
    } catch (e) {
      print('Error saving player data to Firestore: $e');
    }
  }

  void onSwipe(Direction direction) {
    setState(() {
      if (!game.isGameOver()) {
        switch (direction) {
          case Direction.left:
            game.moveLeft();
            break;
          case Direction.right:
            game.moveRight();
            break;
          case Direction.up:
            game.moveUp();
            break;
          case Direction.down:
            game.moveDown();
            break;
        }
      }
      gameOver = game.isGameOver();
      if (gameOver) {
        nameInputVisible = true;
      }
    });
  }

  void resetGame() {
    setState(() {
      game.resetGame();
      gameOver = false;
      nameInputVisible = false;
      nameController.clear();
    });
  }

  void savePlayerData(String name) {
    savePlayerDataToFirebase(name, game.score, country);
    setState(() {
      nameInputVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('2048 - Country: $country'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: resetGame,
          )
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            onSwipe(Direction.right);
          } else if (details.primaryVelocity! < 0) {
            onSwipe(Direction.left);
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            onSwipe(Direction.down);
          } else if (details.primaryVelocity! < 0) {
            onSwipe(Direction.up);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (gameOver && !nameInputVisible) ...[
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Game Over',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Final Score: ${game.score}',
                      style: TextStyle(fontSize: 24, color: Colors.black87),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: resetGame,
                      child: Text('Play Again'),
                    ),
                  ],
                ),
              ),
            ] else if (nameInputVisible) ...[
              // Name Input Section
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Enter your name',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      String name = nameController.text;
                      if (name.isNotEmpty) {
                        savePlayerData(name);
                      }
                    },
                    child: Text('Submit'),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Score: ${game.score}',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: game.grid.map((row) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: row.map((value) => buildTile(value)).toList(),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildTile(int value) {
    return Container(
      width: 80,
      height: 80,
      margin: EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: getTileColor(value),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value == 0 ? '' : '$value',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: value > 4 ? Colors.white : Colors.black),
      ),
    );
  }

  Color getTileColor(int value) {
    switch (value) {
      case 2: return Colors.orange[100]!;
      case 4: return Colors.orange[200]!;
      case 8: return Colors.orange[300]!;
      case 16: return Colors.orange[400]!;
      case 32: return Colors.orange[500]!;
      case 64: return Colors.orange[600]!;
      case 128: return Colors.green[200]!;
      case 256: return Colors.green[300]!;
      case 512: return Colors.green[400]!;
      case 1024: return Colors.green[500]!;
      case 2048: return Colors.green[600]!;
      default: return Colors.grey[300]!;
    }
  }
}

class WebView extends StatefulWidget {
  const WebView({super.key});

  @override
  _WebViewState createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {

  late PullToRefreshController pullToRefreshController;
  bool isProcessingUrl = false;
  String? url = "https://m.md88safe.com/";
  double progress = 0;
  final urlController = TextEditingController();
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  bool isSlowConnection = false;
  Color progressIndicatorColor = Colors.black54;
  late ConnectivityHandler connectivityHandler;


  @override
  void initState(){
    super.initState();
    connectivityHandler = ConnectivityHandler(context);
    connectivityHandler.checkConnectionPeriodically();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    _initializeNonCriticalFeatures();
  }

  @override
  void dispose() {
    connectivityHandler.dispose();
    super.dispose();
  }

  Future<int> checkConnectionLatency(String url) async {
    final response = await Isolate.run(() async {
      Stopwatch stopwatch = Stopwatch()..start();
      try {
        Uri uri = Uri.parse(url);
        String host = uri.host;

        if (host.isNotEmpty) {
          final result = await InternetAddress.lookup(host).timeout(
            const Duration(seconds: 5),
            onTimeout: () => [],
          );

          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            stopwatch.stop();
            return stopwatch.elapsedMilliseconds;
          }
        }
      } catch (e) {
        print('Ping failed for $url. Cannot determine connection speed: $e');
      }
      return -1;
    });

    return response;
  }

  void checkConnectionSpeed(String url) async {
    int latency = await checkConnectionLatency(url);

    if (latency == -1) {
      print('Could not measure connection speed.');
      return;
    }

    if (latency > 500) {
      setState(() {
        isSlowConnection = true;
      });
      _showSlowConnectionDialog(url);
    } else {
      setState(() {
        isSlowConnection = false;
      });
    }
  }


  void _showSlowConnectionDialog(String url) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Unable to connect"),
          content: const Text("Oops! It looks like your internet connection is too weak right now. Please refresh once it's stable."),
          backgroundColor: Colors.white,
          titleTextStyle: const TextStyle(color: Colors.black),
          contentTextStyle: const TextStyle(color: Colors.black),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _initializeNonCriticalFeatures() {
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blueGrey,
      ),
      settings: PullToRefreshSettings(
        color: Colors.blueGrey,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        body: ScrollConfiguration(
          behavior: SmoothScrollBehavior(),
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                InAppWebView(
                  key: webViewKey,
                  initialUrlRequest: URLRequest(url: WebUri(url!)),
                  onGeolocationPermissionsShowPrompt:
                      (InAppWebViewController controller,
                      String origin) async {
                    return GeolocationPermissionShowPromptResponse(
                      origin: origin,
                      allow: true,
                      retain: true,
                    );
                  },
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    transparentBackground: true,
                    underPageBackgroundColor: Colors.black45,
                    useShouldOverrideUrlLoading: true,
                    mediaPlaybackRequiresUserGesture: false,
                    verticalScrollBarEnabled: false,
                    javaScriptCanOpenWindowsAutomatically: true,
                    disableVerticalScroll: false,
                    supportZoom: false,
                    useOnDownloadStart: true,
                    userAgent: Platform.isAndroid
                        ? "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Android/1.0"
                        : "Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1 iOS/1.0",
                    useHybridComposition: true,
                    allowFileAccess: true,
                    allowContentAccess: true,
                    databaseEnabled: true,
                    domStorageEnabled: true,
                    loadWithOverviewMode: true,
                    useWideViewPort: true,
                    allowsInlineMediaPlayback: true,
                    applePayAPIEnabled: true,
                    isPagingEnabled: true,
                    geolocationEnabled: true,
                    cacheEnabled: true,
                  ),
                  pullToRefreshController: pullToRefreshController,
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    var url = navigationAction.request.url.toString();
                    // Handle "mailto:" links
                    if (url.startsWith("mailto:")) {
                      if (await canLaunchUrlString(url)) {
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      } else {
                        _showErrorMessage("No mail app available");
                      }
                      return NavigationActionPolicy.CANCEL;
                    }
                    // Handle "tel:" links
                    else if (url.startsWith("tel:")) {
                      if (await canLaunchUrlString(url)) {
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      } else {
                        _showErrorMessage("No phone app available");
                      }
                      return NavigationActionPolicy.CANCEL;
                    }
                    else if (url.startsWith("skype:")) {
                      if (await canLaunchUrlString(url)) {
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      } else {
                        // If Skype app is not available, try opening the link in a browser
                        var browserUrl = url.replaceFirst("skype:", "https://join.skype.com/");
                        if (await canLaunchUrlString(browserUrl)) {
                          await launchUrl(Uri.parse(browserUrl), mode: LaunchMode.externalApplication);
                        } else {
                          _showErrorMessage("No Skype app available and can't open in browser");
                        }
                      }
                      return NavigationActionPolicy.CANCEL;
                    }

                    return NavigationActionPolicy.ALLOW;
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      this.url = url.toString();
                      urlController.text = this.url!;
                    });
                    if (url != null) {
                      checkConnectionSpeed(url.toString());
                    }
                  },
                  onPermissionRequest: (controller, request) async {
                    if (request.resources.contains(
                        PermissionResourceType.CAMERA) ||
                        request.resources.contains(
                            PermissionResourceType.MICROPHONE)) {
                      PermissionStatus cameraStatus = await Permission.camera
                          .request();
                      PermissionStatus microphoneStatus = await Permission
                          .microphone.request();

                      if (cameraStatus.isGranted &&
                          microphoneStatus.isGranted) {
                        return PermissionResponse(
                          resources: request.resources,
                          action: PermissionResponseAction.GRANT,
                        );
                      } else {
                        return PermissionResponse(
                          resources: request.resources,
                          action: PermissionResponseAction.DENY,
                        );
                      }
                    }
                    return PermissionResponse(
                      resources: request.resources,
                      action: PermissionResponseAction.DENY,
                    );
                  },
                  onLoadStop: (controller, url) async{
                    pullToRefreshController.endRefreshing();
                    setState(() {
                      this.url = url.toString();
                      urlController.text = this.url!;
                    });
                  },

                  onLoadError: (controller, url, code, message) {
                    pullToRefreshController.endRefreshing();
                  },
                  onDownloadStart: (controller, url) async {
                    print("Download request received: $url");
                    await _startDownload(url.toString());
                  },
                  onProgressChanged: (controller, progress) {
                    if (progress == 100) {
                      pullToRefreshController.endRefreshing();
                    }
                    setState(() {
                      this.progress = progress / 100;
                      urlController.text = url!;
                    });
                  },
                ),
                     if (progress < 1.0)
                     LinearProgressIndicator(
                         value: progress,
                         color: progressIndicatorColor,
                         backgroundColor: Colors.white,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> canLaunchUrlString(String urlString) async {
    final Uri url = Uri.parse(urlString);
    return await canLaunchUrl(url);
  }

  Future<void> _startDownload(String url) async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: '/storage/emulated/0/Download',
      showNotification: true,
      openFileFromNotification: true,
      saveInPublicStorage: true,
    );
  }




  Future<bool> _onWillPop(BuildContext context) async {
    webViewController?.goBack();
    return false;
  }
}

class SmoothScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return child; // Remove the glow effect on scroll
  }
}

class ConnectivityHandler {
  final BuildContext context;
  Timer? _timer;

  ConnectivityHandler(this.context);

  Future<bool> isConnected() async {
    return await InternetConnectionChecker().hasConnection;
  }

  void showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            "No Internet Connection😔",
            style: TextStyle(color: Colors.black),
          ),
          content: const Text(
            "Oops! It looks like you don't have a internet connection right now. To try again please hit refresh",
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              child: const Text(
                "Refresh",
                style: TextStyle(color: Colors.blue),
              ),
              onPressed: () async {

                bool connected = await isConnected();
                if (connected) {

                  Navigator.of(context).pop();
                  restartConnectionCheck(); // Restart the timer
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Still no connection")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }


  void checkConnectionPeriodically() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      bool connected = await isConnected();
      if (!connected) {
        // If there's no connection, show the no internet dialog
        showNoInternetDialog();
        _timer?.cancel(); // Stop the timer after showing the dialog
      }
    });
  }

  // Method to restart the connection check timer
  void restartConnectionCheck() {
    _timer?.cancel(); // Cancel any existing timer
    checkConnectionPeriodically(); // Start a new periodic check
  }

  // Method to dispose of the timer when no longer needed
  void dispose() {
    _timer?.cancel();
  }
}

enum Direction { up, down, left, right }
