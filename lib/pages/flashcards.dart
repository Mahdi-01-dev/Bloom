import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drplanguageapp/main.dart';
import 'package:drplanguageapp/pages/languages.dart';
import 'package:flutter/material.dart';

class Flashcard {
  final String word;
  final String translation;
  final String sentence;
  final String translatedSentence;

  Flashcard({
    required this.word,
    required this.translation,
    required this.sentence,
    required this.translatedSentence,
  });
}

Future<List<Flashcard>> getFlashcards(String userID, String language) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userID)
        .collection('flashcards')
        .doc('language')
        .collection(language)
        .get();
    return querySnapshot.docs.map((doc) {
      return Flashcard(
        word: doc['word'],
        translation: doc['trWord'],
        sentence: doc['sentence'],
        translatedSentence: doc['trSentence'],
      );
    }).toList();
  } catch (e) {
    return [];
  }
}

class WordsListPage extends StatefulWidget {
  final String userID;
  final String? language;

  const WordsListPage({super.key, required this.userID, this.language});

  @override
  WordsListPageState createState() => WordsListPageState();
}

class WordsListPageState extends State<WordsListPage> {
  final List<String> languages = ['Arabic', 'Urdu', 'Bangla'];
  String language = 'Arabic';
  Future<List<Flashcard>> flashcards = Future<List<Flashcard>>.value([]);

  @override
  void initState() {
    super.initState();
    flashcards = getFlashcards('userID', language);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Flashcards'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (String newLanguage) {
              setState(() {
                language = newLanguage;
                flashcards = getFlashcards('userID', language);
              });
            },
            itemBuilder: (BuildContext context) {
              return languages.map((String value) {
                return PopupMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList();
            },
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/dashboard',
                (Route<dynamic> route) => false,
              );
            },
            icon: const Icon(Icons.dashboard),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.lime,
        child: Column(
          children: [
            const DrawerHeader(
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/images/bloom.png'),
                radius: 50,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Dashboard"),
              onTap: () {
                Navigator.pushNamed(context, '/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble),
              title: const Text("Conversation"),
              onTap: () {
                Navigator.pushNamed(context, '/dashboard/conversation');
              },
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text("Highlights"),
              onTap: () {
                Navigator.pushNamed(context, '/dashboard/highlights');
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_stories),
              title: const Text("Comprehension"),
              onTap: () {
                Navigator.pushNamed(context, '/selection');
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Flashcard>>(
        future: flashcards,
        builder:
            (BuildContext context, AsyncSnapshot<List<Flashcard>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            if (snapshot.data != null && snapshot.data!.isNotEmpty) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Center(
                      child: Text(
                        snapshot.data![index].word,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FlashcardPage(
                            flashcard: snapshot.data![index],
                            flashcards: snapshot.data!,
                            langauge: language,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            } else {
              return const Center(
                child: Text('You have no flashcards yet!'),
              );
            }
          }
        },
      ),
    );
  }
}

class FlashcardPage extends StatelessWidget {
  final Flashcard flashcard;
  final List<Flashcard> flashcards;
  final String langauge;

  const FlashcardPage(
      {super.key,
      required this.flashcard,
      required this.flashcards,
      required this.langauge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/dashboard');
            },
            icon: const Icon(Icons.dashboard),
          ),
        ],
      ),
      body: Center(
        child: SpinWordWidget(
          flashcard: flashcard,
          flashcards: flashcards,
          language: langauge,
        ),
      ),
    );
  }
}


// ignore: must_be_immutable
class SpinWordWidget extends StatefulWidget {
  Flashcard flashcard;
  final String language;
  final List<Flashcard> flashcards;

  SpinWordWidget({
    super.key,
    required this.flashcard,
    required this.flashcards,
    required this.language,
  });

  @override
  SpinWordWidgetState createState() => SpinWordWidgetState();
}

class SpinWordWidgetState extends State<SpinWordWidget>
    with TickerProviderStateMixin {
  bool _showWord = true;
  late AnimationController _controller;
  late Animation<double> _rotateWordAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _rotateWordAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  void _toggleWord() {
    if (_showWord) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _showWord = !_showWord;
  }

  void _goToNextFlashcard() {
    int currentIndex = widget.flashcards.indexOf(widget.flashcard);
    if (currentIndex < widget.flashcards.length - 1) {
      setState(() {
        widget.flashcard = widget.flashcards[currentIndex + 1];
      });
    }
  }

  void _goToPreviousFlashcard() {
    int currentIndex = widget.flashcards.indexOf(widget.flashcard);
    if (currentIndex > 0) {
      setState(() {
        widget.flashcard = widget.flashcards[currentIndex - 1];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Langauge langStore = Langauge();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _toggleWord,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _rotateWordAnimation,
                    builder: (context, child) {
                      return Transform(
                        alignment: FractionalOffset.center,
                        transform: Matrix4.rotationY(
                            _rotateWordAnimation.value * 3.14),
                        child: _rotateWordAnimation.value <= 0.5
                            ? Text(widget.flashcard.word,
                                style: const TextStyle(fontSize: 28))
                            : Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(3.14),
                                child: Text(widget.flashcard.translation,
                                    style: const TextStyle(fontSize: 28)),
                              ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AnimatedBuilder(
                      animation: _rotateWordAnimation,
                      builder: (context, child) {
                        return AnimatedCrossFade(
                          firstChild: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              const Divider(),
                              Text(
                                widget.flashcard.sentence,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          secondChild: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              const Divider(),
                              Text(
                                widget.flashcard.translatedSentence,
                                style: const TextStyle(
                                    fontSize: 20, fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                          crossFadeState: _showWord
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          duration: const Duration(milliseconds: 300),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ElevatedButton(
            onPressed: widget.flashcards.indexOf(widget.flashcard) > 0
                ? _goToPreviousFlashcard
                : null,
            child: const Icon(Icons.arrow_back),
          ),
          ElevatedButton(
            onPressed: () async {
              await speak(widget.flashcard.word,
                  langStore.getSpeechCode(widget.language));
            },
            child: const Icon(Icons.volume_up),
          ),
          ElevatedButton(
            onPressed: widget.flashcards.indexOf(widget.flashcard) <
                    widget.flashcards.length - 1
                ? _goToNextFlashcard
                : null,
            child: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
