import 'dart:convert';
import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:howler/howler.dart';

void main() {
  runApp(MyApp());
}

Howl howl = new Howl();

void stop() {
  howl.stopAll();
}

void play(String s) {
  howl = Howl(
      src: [s], // source in MP3 and WAV fallback
      loop: false,
      volume: 1 // Play with 60% of original volume.
      );
  howl.play();
  // howl.pause();
}

AudioPlayer player = AudioPlayer();

bool playing = false;
bool paused = false;
bool got = false;
Duration position;
Duration duration;
Map song;

final String host = "https://api.heavenly.mbastin.ir";

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<Object>.value(value: Object()),
      ],
      child: MaterialApp(
        title: 'Heavenly',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(),
        routes: {
          '/songs': (context) => SongsScreen(),
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<Object>(
        builder: (context, value, child) => Scaffold(
              backgroundColor: Color(0xff222831),
              appBar: AppBar(
                backgroundColor: Color(0xff00adb5),
                title: Text("Heavenly"),
              ),
              body: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[SearchBox(), Flexible(child: Albums())],
                  )),
              bottomNavigationBar: null,
            ));
  }
}

class SearchBox extends StatefulWidget {
  @override
  _SearchBoxState createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Container(
          color: Color(0xff393e46),
          height: 50,
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: TextField(
              enabled: false,
            ),
          )),
    );
  }
}

class Albums extends StatefulWidget {
  @override
  _AlbumsState createState() => _AlbumsState();
}

class _AlbumsState extends State<Albums> {
  Future getAlbums;
  Object object;

  void initState() {
    object = Provider.of<Object>(context, listen: false);
    getAlbums = object.getAlbums();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getAlbums,
        builder: (context, snapshot) =>
            snapshot.connectionState == ConnectionState.waiting
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 50),
                    child: GridView.builder(
                      scrollDirection: Axis.vertical,
                      // shrinkWrap: true,
                      // physics: ClampingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1,
                      ),
                      itemCount: myObject.albums.length,
                      itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.all(30),
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/songs', arguments: {
                              "pk": myObject.albums[index]['pk'],
                              "image": Image.network(
                                myObject.albums[index]['image'],
                                fit: BoxFit.cover,
                              ),
                            });
                          },
                          child: Container(
                            color: Colors.white,
                            // height: 300,
                            // width: 100,
                            child: Stack(
                              children: [
                                Image.network(
                                  myObject.albums[index]['image'],
                                  fit: BoxFit.cover,
                                ),
                                // Center(
                                //   child: Text(myObject.albums[index]['title']),
                                // )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ));
  }
}

Object myObject = new Object();

class Object with ChangeNotifier {
  List albums;
  List songs;

  Future<int> getAlbums() async {
    int result = 1;

    var res = await http.get("$host/albums/", headers: {
      'Content-Type': 'application/json',
    });

    if (res.statusCode == 200) {
      myObject.albums = json.decode(res.body);
      result = 1;
    } else {
      result = 0;
    }

    return result;
  }

  Future<int> getSongs(int pk) async {
    // print("in here");
    // print(pk);
    int result = 1;

    var res = await http.get("$host/albums/$pk", headers: {
      'Content-Type': 'application/json',
    });

    if (res.statusCode == 200) {
      myObject.songs = json.decode(res.body);
      result = 1;
      // print("ok");
    } else {
      result = 0;
      // print(res.body);
    }

    return result;
  }
}

class Songs extends StatefulWidget {
  final Function refresh;
  Songs({@required this.refresh});

  @override
  _SongsState createState() => _SongsState();
}

class _SongsState extends State<Songs> {
  Future getSongs;
  Object object;
  StreamSubscription<AudioPlayerState> _audioPlayerStateSubscription;
  StreamSubscription<Duration> _positionSubscription;

  void initState() {
    object = Provider.of<Object>(context, listen: false);
    // getSongs = object.getSongs(pk));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Map args = ModalRoute.of(context).settings.arguments;

    return FutureBuilder(
        future: object.getSongs(args['pk']),
        builder: (context, snapshot) =>
            snapshot.connectionState == ConnectionState.waiting
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 50),
                    child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      // shrinkWrap: true,
                      // physics: ClampingScrollPhysics(),

                      itemCount: myObject.songs.length,
                      itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.only(left: 30, top: 15),
                        child: InkWell(
                          onTap: () {
                            // var howl = new Howl(
                            //     src: [
                            //       myObject.songs[index]["file"]
                            //     ], // source in MP3 and WAV fallback
                            //     loop: false,
                            //     volume: 0.6 // Play with 60% of original volume.
                            //     );

                            // howl.stopAll();
                            // howl.play();
                            if (playing) {
                             stop();
                            } 
                            // else {
                            //   howl.play();
                            // }
                            // playing = !playing;
                            // print(playing);
                            // stop();
                            song = myObject.songs[index];
                            playing = true;
                            play(myObject.songs[index]["file"]);
                            // player.stop();

                            // player.play(myObject.songs[index]["file"]);

                            widget.refresh();

                            // _positionSubscription = player
                            //     .onAudioPositionChanged
                            //     .listen((p) => setState(() => position = p));
                            // _audioPlayerStateSubscription =
                            //     player.onPlayerStateChanged.listen((s) {
                            //   if (s == AudioPlayerState.PLAYING) {
                            //     setState(() {
                            //       print("some");
                            //       got = true;
                            //       duration = player.duration;
                            //     });
                            //   }
                            // });
                          },
                          child: Container(
                            color: Color(0xffeeeeee),
                            // height: 300,
                            // width: 100,
                            child: Row(
                              children: [
                                SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: args['image']),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(myObject.songs[index]["index"].toString()),
                                SizedBox(
                                  width: 20,
                                ),
                                Text(myObject.songs[index]["title"])
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ));
  }
}

class SongsScreen extends StatefulWidget {
  @override
  _SongsScreenState createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  Widget songs;
  void refresh() {
    setState(() {
      // print("got");
    });
  }

  void initState() {
    songs = Songs(
      refresh: refresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xff222831),
        appBar: AppBar(
          backgroundColor: Color(0xff00adb5),
          title: Text("Heavenly"),
        ),
        body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[SearchBox(), Flexible(child: songs)],
            )),
        bottomNavigationBar: playing
            ? Container(
              color: Colors.white,
                width: MediaQuery.of(context).size.width,
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Text(song['title']),
                    Container(
                      // color: Colors.white,
                      width: 100,
                      child: Row(children: [
                        // IconButton(
                        //     icon: Icon(Icons.pause),
                        //     onPressed: () {
                        //       setState(() {
                        //         // player.pause();

                        //         paused = !paused;
                        //       });
                        //     }),
                        IconButton(
                            icon: Icon(Icons.stop),
                            onPressed: () {
                              setState(() {
                                playing = false;
                                stop();
                              });
                            })
                      ]),
                    )
                  ],
                ),
              )
            : null);
  }
}
