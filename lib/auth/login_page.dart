import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:device_info/device_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:handwash/AppEngine.dart';
import 'package:handwash/MainAdmin.dart';
import 'package:handwash/app/navigation.dart';
import 'package:handwash/app_config.dart';
import 'package:handwash/assets.dart';
import 'package:handwash/basemodel.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'SignUpPage.dart';
import 'forgot_password.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  bool usernameInvalid = false;
  bool passwordInvalid = false;
  FocusNode focusEmail;
  FocusNode focusPassword;
  BuildContext context;
  bool passwordVisible = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isSignUp = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    focusEmail = new FocusNode();
    focusPassword = new FocusNode();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    userNameController.dispose();
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext cc) {
    return WillPopScope(
      onWillPop: () async {
        pushReplacementAndResult(context, LoginPage());
        return false;
      },
      child: Scaffold(
          backgroundColor: white,
          key: _scaffoldKey,
          resizeToAvoidBottomInset: true,
          body: Builder(builder: (c) {
            context = c;
            return page();
          })),
    );
  }

  bool rememberMe = false;

  page() {
    return BackgroundScaffold(
      bgAsset: "assets/bg/login.png",
      child: Column(
        children: [
          Container(
            height: getScreenHeight(context) * .25,
            padding: EdgeInsets.all(15),
            alignment: Alignment.centerLeft,
            child: Text(
              "Welcome!",
              style: textStyle(
                true,
                50,
                AppConfig.appColor,
              ),
            ),
          ),
          Flexible(
            child: ListView(
              //mainAxisSize: MainAxisSize.min,
              //mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                textInputField(
                    controller: userNameController,
                    focusNode: focusEmail,
                    title: "Username or Email:",
                    hint: "johndoe",
                    asset: "null",
                    icon: Icons.person),
                textInputField(
                    controller: passwordController,
                    focusNode: focusPassword,
                    title: "Password",
                    hint: "*********",
                    asset: "null",
                    isPass: true,
                    icon: Icons.lock,
                    refresh: () => setState(() {})),
                addSpace(20),
                GestureDetector(
                  onTap: () {
                    pushAndResult(context, ForgotPassword(), depend: false);
                  },
                  child: Container(
                    padding: EdgeInsets.all(15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              rememberMe = !rememberMe;
                            });
                          },
                          child: Row(
                            children: [
                              Container(
                                height: 25,
                                width: 25,
                                alignment: Alignment.center,
                                //padding: EdgeInsets.all(2),
                                child: rememberMe
                                    ? Center(
                                        child: Icon(
                                          Icons.check,
                                          size: 12,
                                        ),
                                      )
                                    : null,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: AppConfig.appColor,
                                        width: rememberMe ? 2 : 1)),
                              ),
                              addSpaceWidth(10),
                              Text(
                                "REMEMBER ME?",
                                style: textStyle(
                                  true,
                                  14,
                                  AppConfig.appColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "FORGOT PASSWORD?",
                          style: textStyle(true, 14, AppConfig.appColor,
                              underlined: true),
                        ),
                      ],
                    ),
                  ),
                ),
                addSpace(20),
                Container(
                  padding: EdgeInsets.all(15),
                  child: RawMaterialButton(
                    onPressed: () {
                      handleSignIn("app");
                    },
                    fillColor: AppConfig.appColor,
                    padding: EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    elevation: 10,
                    child: Center(
                        child: Text(
                      "Login",
                      style: textStyle(true, 24, white),
                    )),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(15),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      Flexible(
                        child: Container(
                          height: 1,
                          color: black,
                          margin: EdgeInsets.all(10),
                        ),
                      ),
                      Text(
                        "Or Login With",
                        style: textStyle(false, 15, black),
                      ),
                      Flexible(
                        child: Container(
                          height: 1,
                          color: black,
                          margin: EdgeInsets.all(10),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(15),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      Flexible(
                        child: FlatButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            //mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                "assets/icons/facebook.png",
                                height: 20,
                                width: 20,
                                color: white,
                              ),
                              addSpaceWidth(5),
                              Text('FACEBOOK',
                                  style: textStyle(true, 14, white)),
                            ],
                          ),
                          onPressed: () {
                            handleSignIn("facebook");
                          },
                          padding: EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                              //side: BorderSide(color: white.withOpacity(.4), width: 2),
                              borderRadius: BorderRadius.circular(8)),
                          color: Color(0xFF4267B2),
                        ),
                      ),
                      addSpaceWidth(20),
                      if (Platform.isIOS)
                        Flexible(
                          child: FlatButton(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              //mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  "assets/icons/apple.png",
                                  height: 20,
                                  width: 20,
                                  color: white,
                                ),
                                addSpaceWidth(5),
                                Text('APPLE',
                                    style: textStyle(true, 14, white)),
                              ],
                            ),
                            onPressed: () {
                              handleSignIn("apple");
                            },
                            padding: EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                                //side: BorderSide(color: white.withOpacity(.4), width: 2),
                                borderRadius: BorderRadius.circular(8)),
                            color: black,
                          ),
                        )
                      else
                        Flexible(
                          child: FlatButton(
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    "assets/icons/google.png",
                                    height: 20,
                                    width: 20,
                                    //color: white,
                                  ),
                                  addSpaceWidth(5),
                                  Text(
                                    'GOOGLE',
                                    style: textStyle(true, 14, black),
                                  ),
                                ],
                              ),
                            ),
                            onPressed: () {
                              handleSignIn("google");
                            },
                            padding: EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    color: black.withOpacity(0.5), width: 1),
                                borderRadius: BorderRadius.circular(8)),
                            //color: Color(0xFFf4c20d),
                          ),
                        )
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    pushReplacementAndResult(context, SignUpPage(),
                        depend: false);
                  },
                  child: Container(
                    padding: EdgeInsets.all(15),
                    alignment: Alignment.center,
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: "New User? ",
                          style: textStyle(true, 16, black)),
                      TextSpan(
                          text: "Sign Up? ",
                          style: textStyle(true, 16, AppConfig.appColor,
                              underlined: true))
                    ])),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  snack(String text) {
    Future.delayed(Duration(milliseconds: 500), () {
      showSnack(_scaffoldKey, text, useWife: true);
    });
  }

  textInputField({
    @required TextEditingController controller,
    @required String title,
    @required String hint,
    @required String asset,
    bool isPass = false,
    FocusNode focusNode,
    IconData icon,
    void Function() refresh,
  }) {
    return Container(
      padding: EdgeInsets.only(left: 15, right: 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          addSpace(5),
          Text(
            title,
            style: textStyle(false, 14, AppConfig.appColor),
          ),
          addSpace(4),
          Container(
            padding: EdgeInsets.only(left: 15, right: 15),
            decoration: BoxDecoration(
                color: white,
                border: Border.all(
                  color: black.withOpacity(.2),
                ),
                borderRadius: BorderRadius.circular(25)),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppConfig.appColor,
                ),
                Container(
                  height: 20,
                  width: 1,
                  color: black.withOpacity(.1),
                  margin: EdgeInsets.only(left: 5, right: 15),
                ),
                Flexible(
                  child: TextField(
                    controller: controller,
                    obscureText: isPass && !passwordVisible,
                    decoration: InputDecoration(
                        suffix: !isPass
                            ? null
                            : GestureDetector(
                                onTap: () {
                                  passwordVisible = !passwordVisible;
                                  if (refresh != null) refresh();
                                },
                                child: Text(
                                  passwordVisible ? "HIDE" : "SHOW",
                                  style: textStyle(
                                      false, 12, black.withOpacity(.5)),
                                )),
                        hintText: hint,
                        border: InputBorder.none),
                  ),
                ),
                addSpaceWidth(10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  handleSignIn(String type) async {
    var result = await (Connectivity().checkConnectivity());
    if (result == ConnectivityResult.none) {
      snack("No internet connectivity");
      return;
    }

    if (type == "app") {
      String username = userNameController.text.trim();
      String password = passwordController.text;
      String email = "$username@handwash.app";

      if (username.isEmpty) {
        snack("Enter Username!");
        return;
      }

      if (password.isEmpty) {
        snack("Enter Password!");
        return;
      }
      showProgress(true, context, msg: "Loggin In");
      loginIntoApp(null, email: email, pass: password);
      return;
    }

    showProgress(true, context, msg: "Loggin In");
    if (type == "google") {
      GoogleSignIn googleSignIn = GoogleSignIn();
      googleSignIn.signIn().then((account) async {
        account.authentication.then((googleAuth) {
          final credential = GoogleAuthProvider.getCredential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          loginIntoApp(credential);
        }).catchError((e) {
          onError("Error 001", e);
        });
      }).catchError((e) {
        onError("Error 01", e);
      });
    }

    if (type == "facebook") {
      FacebookAuth.instance.login().then((account) {
        final credential = FacebookAuthProvider.getCredential(
          accessToken: account.accessToken.token,
        );
        loginIntoApp(credential);
      }).catchError((e) {
        onError("Error 02", e);
      });
    }

    if (type == "apple") {
      SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      ).then((value) {
        final credential = OAuthProvider(providerId: 'apple.com').getCredential(
          accessToken: value.authorizationCode,
          idToken: value.identityToken,
        );
        loginIntoApp(credential);
      }).catchError((e) {
        onError("Error 04", e);
      });
    }
  }

  loginIntoApp(AuthCredential credential,
      {String email, String pass, bool useCred = true}) async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    String deviceId;
    if (Platform.isIOS) {
      final deviceInfo = await deviceInfoPlugin.iosInfo;
      deviceId = deviceInfo.identifierForVendor;
    } else {
      final deviceInfo = await deviceInfoPlugin.androidInfo;
      deviceId = deviceInfo.androidId;
    }

    (useCred
            ? FirebaseAuth.instance
                .signInWithEmailAndPassword(email: email, password: pass)
            : FirebaseAuth.instance.signInWithCredential(credential))
        .then((value) {
      final account = value.user;

      Firestore.instance
          .collection(USER_BASE)
          .document(account.uid)
          .get()
          .then((doc) {
        if (!doc.exists) {
          userModel
            ..put(USER_ID, account.uid)
            ..put(EMAIL, account.email)
            ..put(USER_IMAGE, account.photoUrl)
            ..put(NAME, account.displayName)
            ..putInList(DEVICE_ID, deviceId, true)
            ..saveItem(USER_BASE, false, document: account.uid);
        }
        userModel = BaseModel(doc: doc);
        popUpUntil(context, MainAdmin());
      }).catchError((e) {
        onError("Error 04", e);
      });
    }).catchError((e) {
      onError("Error 03", e);
    });
  }

  onError(String type, e) {
    showProgress(false, context);
    showMessage(context, Icons.error, red0, type, e?.message,
        delayInMilli: 1200, cancellable: true);
  }
}

class BackgroundScaffold extends StatelessWidget {
  final Widget child;
  final String bgAsset;
  const BackgroundScaffold({Key key, @required this.bgAsset, this.child})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(bgAsset),
                  alignment: Alignment.center,
                  fit: BoxFit.cover)),
        ),
        child ?? Container()
      ],
    );
  }
}
