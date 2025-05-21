import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../chatmessage.dart';
import '../threedots.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import 'notes_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late NoteService _noteService;
  
  // Speech recognition
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _lastWords = '';
  
  // Text to speech
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    Gemini.init(apiKey: dotenv.env["API_KEY"]!);
    _initializeNoteService();
    _initializeSpeech();
    _initializeTts();
  }

  Future<void> _initializeNoteService() async {
    final prefs = await SharedPreferences.getInstance();
    _noteService = NoteService(prefs);
  }

  Future<void> _initializeSpeech() async {
    await _speechToText.initialize();
    setState(() {});
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: "en_US",
    );
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(result) {
    if (!mounted) return;
    setState(() {
      _lastWords = result.recognizedWords;
      if (result.finalResult) {
        _controller.text = _lastWords;
        _sendMessage();
      }
    });
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }
    if (!mounted) return;
    setState(() {
      _isSpeaking = true;
    });
    await _flutterTts.speak(text);
    _flutterTts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;
    ChatMessage message = ChatMessage(
      text: _controller.text,
      sender: "user",
      isImage: false,
    );

    setState(() {
      _messages.insert(0, message);
      _isTyping = true;
    });

    String userMessage = _controller.text;
    _controller.clear();

    try {
      final gemini = Gemini.instance;
      String fullResponse = '';
      await for (final value in gemini.streamGenerateContent(userMessage)) {
        if (value.output != null) {
          fullResponse += value.output!;
          insertNewData(fullResponse, isImage: false);
        }
      }
      // Speak the response
      await _speak(fullResponse);
    } catch (e) {
      insertNewData("An error occurred while generating the response.", isImage: false);
      print("Error: $e");
    }
  }

  void insertNewData(String response, {bool isImage = false}) {
    ChatMessage botMessage = ChatMessage(
      text: response,
      sender: "bot",
      isImage: isImage,
    );

    setState(() {
      _isTyping = false;
      if (_messages.isNotEmpty && _messages[0].sender == "bot") {
        _messages[0] = botMessage;
      } else {
        _messages.insert(0, botMessage);
      }
    });
  }

  void _saveMessageAsNote(String content) async {
    final note = Note(
      id: DateTime.now().toString(),
      content: content,
      createdAt: DateTime.now(),
      isReminder: false,
    );
    await _noteService.addNote(note);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message saved as note')),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            onPressed: () {
              if (_isListening) {
                _stopListening();
              } else {
                _startListening();
              }
            },
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (value) => _sendMessage(),
              decoration: const InputDecoration.collapsed(
                hintText: "Ask me anything...",
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Assistant"),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotesScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return GestureDetector(
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Save as Note'),
                            content: const Text('Do you want to save this message as a note?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  _saveMessageAsNote(message.text);
                                  Navigator.pop(context);
                                },
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: message,
                    );
                  },
                ),
              ),
            ),
            if (_isTyping) const ThreeDots(),
            _buildTextComposer(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
    super.dispose();
  }
} 