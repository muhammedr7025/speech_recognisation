import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:text_to_speech/text_to_speech.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSpeechEnabled = false;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  int level = 0;
  String chargingStatus = "";
  var battery = Battery();
  TextToSpeech tts = TextToSpeech();
  final Battery _battery = Battery();
  final databaseReference = FirebaseDatabase.instance.reference();
  BatteryState? _batteryState;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  void batteryUtils() async {
    final batteryLevel = await _battery.batteryLevel;
    level = batteryLevel;
    setState(() {
      level = batteryLevel;
      _battery.onBatteryStateChanged.listen(_updateBatteryState);
    });
  }

  void _updateBatteryState(BatteryState state) {
    if (_batteryState == state) return;
    setState(() {
      _batteryState = state;
    });
  }

  @override
  void initState() {
    super.initState();
    _battery.batteryState.then(_updateBatteryState);
    _batteryStateSubscription =
        _battery.onBatteryStateChanged.listen(_updateBatteryState);
    batteryUtils();
    _initSpeech();
    initTTS();
  }

  initTTS() async {
    String language = 'en-US';
    tts.setLanguage(language);
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    batteryUtils();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
    if (_lastWords.contains('charging status') ||
        _lastWords.contains('battery state') ||
        _lastWords.contains('charging or not')) {
      if (_batteryState == BatteryState.discharging) {
        tts.speak("Is not charging");
      } else if (_batteryState == BatteryState.charging) {
        tts.speak("Is charging");
      }
    } else if (_lastWords.contains('plug') || _lastWords.contains('socket')) {
      String text = "Now you will here beep";
      tts.speak(text);
    } else if (_lastWords.contains('adapter') ||
        _lastWords.contains('adaptor')) {
      String text = "Adapter alarms";
      tts.speak(text);
    } else if (_lastWords.contains('battery') ||
        _lastWords.contains('charge')) {
      String text = "Battery percentage is $level";
      tts.speak(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const Spacer(),
            const Spacer(),
            Center(
              child: GestureDetector(
                onTap: () async {
                  final batteryLevel = await _battery.batteryLevel;

                  batteryUtils();
                  setState(() {
                    isSpeechEnabled = !isSpeechEnabled;
                    level = batteryLevel;
                  });
                  if (isSpeechEnabled) {
                    _startListening();
                  } else {
                    _stopListening();
                  }
                },
                child: const Material(
                  elevation: 5.0,
                  shape: CircleBorder(),
                  child: CircleAvatar(
                    radius: 160,
                    backgroundColor: Colors.black,
                    child: Icon(
                      Icons.mic_rounded,
                      color: Colors.yellow,
                      size: 110,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'Recognized words:',
              style: TextStyle(fontSize: 20.0),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                // If listening is active show the recognized words
                _speechToText.isListening
                    ? _lastWords
                    // If listening isn't active but could be tell the user
                    // how to start it, otherwise indicate that speech
                    // recognition is not yet ready or not supported on
                    // the target device
                    : _speechEnabled
                        ? 'Tap the microphone to start listening...'
                        : 'Speech not available',
              ),
            ),
            Text("Battery percent:-$level"),
            Text("$_batteryState"),
            const Text("")
          ],
        ),
      ),
    );
  }
}
