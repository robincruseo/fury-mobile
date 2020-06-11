import 'package:audioplayers/audio_cache.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';

class SecondScreen extends StatefulWidget {
  const SecondScreen({this.payload, this.scheduleNotification});

  final String payload;
  final Function scheduleNotification;

  @override
  State<StatefulWidget> createState() => SecondScreenState();
}

class SecondScreenState extends State<SecondScreen> {
  String _payload;
  @override
  void initState() {
    super.initState();
    _payload = widget.payload;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: CircularCountDownTimer(
              duration: 30,
              width: MediaQuery.of(context).size.width / 2,
              height: MediaQuery.of(context).size.height / 2,
              color: Colors.purple.shade100,
              fillColor: Colors.deepPurple,
              strokeWidth: 5.0,
              countdownTextStyle: TextStyle(
                  fontSize: 60.0,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold),
              reverseOrder: true,
              onCountDownComplete: () {
                final player = AudioCache();
                player.play('note1.wav');
                widget.scheduleNotification(
                    interval: 15,
                    title: 'Handwash sdsdReminder',
                    body: 'Handwash Reminder');
              }),
        ),
      ),
    );
  }
}
