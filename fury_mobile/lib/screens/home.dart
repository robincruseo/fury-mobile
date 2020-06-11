import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fury_mobile/screens/second_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic.dart';
import '../main.dart';
import 'second_screen.dart';



// this page is seen as the login page


class HomePage extends StatefulWidget {
  const HomePage({this.scheduleNotification});
  final Function scheduleNotification;
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MethodChannel platform =
      MethodChannel('crossingthestreams.io/resourceResolver');
  @override
  void initState() {
    super.initState();
    _requestIOSPermissions();
    _configureDidReceiveLocalNotificationSubject();
    _configureSelectNotificationSubject();
    checkname();
  }

  void _requestIOSPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _configureDidReceiveLocalNotificationSubject() {
    didReceiveLocalNotificationSubject.stream
        .listen((ReceivedNotification receivedNotification) async {
      await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: receivedNotification.title != null
              ? Text(receivedNotification.title)
              : null,
          content: receivedNotification.body != null
              ? Text(receivedNotification.body)
              : null,
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Ok'),
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SecondScreen(
                      payload: receivedNotification.payload,
                      scheduleNotification: widget.scheduleNotification,
                    ),
                  ),
                );
              },
            )
          ],
        ),
      );
    });
  }

  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String payload) async {
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SecondScreen(
                  payload: payload,
                  scheduleNotification: widget.scheduleNotification,
                )),
      );
    });
  }

  @override
  void dispose() {
    didReceiveLocalNotificationSubject.close();
    selectNotificationSubject.close();
    super.dispose();
  }

//////////new line ///////////////////
  checkname() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('name');
    if (name != null) {
      print('$name');
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => SecondScreen()),
          (Route<dynamic> route) => false);
    }
  }

  String _name;

  final _formKey = GlobalKey<FormState>();

  var _dropdownValue = '15';
  @override
  Widget build(BuildContext context) {
    var logic = Provider.of<Logic>(context);
    return Scaffold(
      body: ListView(
        children: <Widget>[
          Container(
              width: MediaQuery.of(context).size.height,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/login.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Center(
                child: Stack(children: <Widget>[
                  Positioned(
                    child: Builder(builder: (BuildContext context) {
                      return Form(
                          key: _formKey,
                          child: Column(
                            children: <Widget>[
                              SizedBox(
                                height: MediaQuery.of(context).size.height / 2,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      'choose an interval in minutes',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(width: 23),
                                    DropdownButton(
                                      items: <String>['15', '30', '45', '60']
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                            value: value, child: Text(value));
                                      }).toList(),
                                      onChanged: (String value) {
                                        setState(() {
                                          _dropdownValue = value;
                                        });
                                      },
                                      value: _dropdownValue,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: TextFormField(
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return 'name cannot be empty';
                                    }
                                  },
                                  onSaved: (value) {
                                    setState(() {
                                      _name = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                      hintText: 'Your name please',
                                      border: OutlineInputBorder()),
                                ),
                              ),
                              SizedBox(
                                height: 23,
                              ),
                              MaterialButton(
                                minWidth: 380,
                                height: 50,
                                color: Colors.purple[900],
                                onPressed: () async {
                                  await widget.scheduleNotification(
                                      interval: _dropdownValue,
                                      title: '$_name Covid Prevention',
                                      body: 'its time to wash your hands');
                                  // save users name in shared prefrence
                                  logic.signin(_name);
                                  // save users interval choice in shared prefrence
                                  logic.setInterval(_dropdownValue);
                                  print('$_name');
                                  // check if form is valid and save data
                                  if (_formKey.currentState.validate()) {
                                    _formKey.currentState.save();
                                    print('valid');
                                    // Navigate to dashboard
                                    Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                            builder: (context) => SecondScreen()),
                                        (Route<dynamic> route) => false);
                                  }
                                },
                                child: Text(
                                  'start notifying me',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            ],
                          ));
                    }),
                  ),
                ]),
              )),
        ],
      ),
    );
  }
}
