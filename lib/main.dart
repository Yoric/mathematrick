import 'package:flutter/material.dart';

import 'package:speech_to_text/speech_to_text.dart';

import 'package:mathematrick/parser.dart';

void main() {
  runApp(Root());
}

class Root extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StackPage(itemCount: 1024),
    );
  }
}

class StackPage extends StatefulWidget {
  StackPage({Key key, @required this.itemCount}) : super(key: key);
  final int itemCount;
  @override
  _StackPageState createState() => _StackPageState(itemCount: this.itemCount);
}

class _StackPageState extends State<StackPage> {
  _StackPageState({@required this.itemCount});

  final int itemCount;
  final TextStyle textStyle = new TextStyle(fontSize: 32);
  final Parser parser = Parser();

  // `true` if we couldn't initialize.
  bool _hasSpeechError = false;
  bool _isListening = false;
  String _status = "(prêt)";

  @override
  void initState() {
    print("itemCount: $itemCount");
    assert(parser.stack.length >= 0);
    assert(itemCount >= 0);
    assert(_status == "(prêt)");
    super.initState();
  }

  final SpeechToText _speech = SpeechToText();
  bool _speechInitialized = false;

  Future<SpeechToText> getSpeech() async {
    if (_speechInitialized) return _speech;
    bool hasSpeech = await _speech.initialize(debugLogging: true);
    if (!hasSpeech) {
      setState(() {
        _hasSpeechError = true;
      });
      throw ("Cannot use speech");
    }
    _speechInitialized = true;
    return _speech;
  }

  Future<void> onMic() async {
    var speech = await getSpeech();
    setState(() {
      _isListening = true;
    });
    speech.listen(
        pauseFor: Duration(seconds: 5),
        partialResults: false,
        onResult: (recognition) {
          setState(() {
            _isListening = false;
          });
          // FIXME: Handle alternative interpretations.
          var regexp = RegExp(r"\S+");
          var text = recognition.recognizedWords;
          print("Recognized words: $text");
          var matches = regexp.allMatches(text);
          print("Matches: $matches");
          var words =
              matches.map((match) => text.substring(match.start, match.end));
          print("Words: $words");
          setState(() {
            _status = "$words";
          });
          parser.handleWords(words, onStatus: (status) {
            print("Got status!");
            setState(() {
              _status = "$status";
            });
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body:
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          ListView.separated(
        reverse: true,
        itemCount: 128, // FIXME: This should be an argument.
        itemBuilder: (_ctx, index) {
          print("itemBuilder $index, ${parser.stack.length}");
          if (index >= parser.stack.length || parser.stack[index] == null) {
            return Text(
              "$index => ",
              style: textStyle,
            );
          }
          return Text(
            "$index => ${parser.stack[index]}",
            style: textStyle,
          );
        },
        separatorBuilder: (_ctx, _index) {
          return Divider();
        },
      ),
      backgroundColor: Colors.blueGrey.shade200,
      floatingActionButton: FloatingActionButton(
          backgroundColor: _hasSpeechError
              ? Color.fromARGB(255, 255, 0, 0)
              : Color.fromARGB(255, 0, 0, 255),
          child: _isListening
              ? const Icon(Icons.settings_voice)
              : const Icon(Icons.mic),
          onPressed: onMic),
          bottomSheet: Text(_status),
    );
  }
}
