import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //
  //
  String url;
  bool isAsset = false;
  AudioPlayer _audioPlayer;
  AudioCache _audioCache;
  PlayerState _playerState = PlayerState.STOPPED;
  bool get _isPlaying => _playerState == PlayerState.PLAYING;
  bool get _isLocal => !url.contains('https');
  bool get isPlaying => _playerState == PlayerState.PLAYING;

  //
  //
  Future<String> _loadFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/flutter_assets/audioku.mp3');

    if (await _assetAlreadyPresent(file.path)) {
      return file.path;
    }

    final bytes = await readBytes(Uri.parse('https://drive.google.com/uc?export=view&id=1d9qseAB8t9I4uImCFF75_4ha3HkPJoPN'));

    await file.writeAsBytes(bytes);

    return file.path;
  }

  //
  //
  Future<bool> _assetAlreadyPresent(String filePath) async {
    final File file = File(filePath);
    return file.exists();
  }

  //
  //
  @override
  void initState() {
    _audioPlayer = AudioPlayer(mode: PlayerMode.MEDIA_PLAYER);
    _audioCache = AudioCache(fixedPlayer: _audioPlayer);

    _audioPlayer.onPlayerError.listen((msg) {
      setState(() {
        _playerState = PlayerState.STOPPED;
      });
    });
    super.initState();
  }

  //
  //
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  //
  //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audioku'),
      ),
      body: FutureBuilder<String>(
        future: _loadFilePath(),
        builder: (context, snapshot) {
          url = snapshot.data ?? "";
          isAsset == false;
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Column(
              children: [
                Text('Local Audio'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 32,
                          color: Colors.green,
                        ),
                        onPressed: () => _playPause()),
                    _isPlaying
                        ? IconButton(
                            onPressed: () => _stop(),
                            icon: Icon(
                              Icons.stop,
                              size: 32,
                              color: Colors.red,
                            ),
                          )
                        : Container(),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  //
  //
  //
  _playPause() async {
    if (_playerState == PlayerState.PLAYING) {
      final playerResult = await _audioPlayer.pause();
      if (playerResult == 1) {
        setState(() {
          _playerState = PlayerState.PAUSED;
        });
      }
    } else if (_playerState == PlayerState.PAUSED) {
      final playerResult = await _audioPlayer.resume();
      if (playerResult == 1) {
        setState(() {
          _playerState = PlayerState.PLAYING;
        });
      }
    } else {
      if (isAsset) {
        _audioPlayer = await _audioCache.play(url);
        setState(() {
          _playerState = PlayerState.PLAYING;
        });
      } else {
        final playerResult = await _audioPlayer.play(url, isLocal: _isLocal);
        if (playerResult == 1) {
          setState(() {
            _playerState = PlayerState.PLAYING;
          });
        }
      }
    }
  }

  _stop() async {
    final playerResult = await _audioPlayer.stop();
    if (playerResult == 1) {
      setState(() {
        _playerState = PlayerState.STOPPED;
      });
    }
  }
}
