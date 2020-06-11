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
import 'package:handwash/auth/login_page.dart';
import 'package:handwash/basemodel.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() {
    return _SignUpPageState();
  }
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  bool usernameInvalid = false;
  bool emailInvalid = false;
  bool passwordInvalid = false;
  FocusNode focusEmail;
  FocusNode focusUserName;
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
      bgAsset: "assets/bg/signup.png",
      child: Column(
        children: [
          Container(
            height: getScreenHeight(context) * .25,
            padding: EdgeInsets.only(left: 15, right: 15, top: 15),
            //alignment: Alignment.centerLeft,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: EdgeInsets.only(top: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Sign Up!",
                          style: textStyle(
                            true,
                            40,
                            AppConfig.appColor,
                          ),
                        ),
                        addSpace(10),
                        Text(
                          '"Lets get you started!"',
                          style: textStyle(
                            true,
                            20,
                            AppConfig.appColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Image.asset("assets/bg/mas_left.png"),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              //mainAxisSize: MainAxisSize.min,
              //mainAxisAlignment: MainAxisAlignment.center,
              padding: EdgeInsets.only(top: 0),
              children: <Widget>[
                textInputField(
                    controller: userNameController,
                    focusNode: focusUserName,
                    title: "Username:",
                    hint: "johndoe",
                    asset: "null",
                    icon: Icons.person),
                textInputField(
                    controller: emailController,
                    focusNode: focusEmail,
                    title: "E-mail:",
                    hint: "johndoe@email.com",
                    asset: "null",
                    icon: Icons.alternate_email),
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
                Container(
                  padding: EdgeInsets.all(15),
                  child: RawMaterialButton(
                    onPressed: () {
                      handleSignUp("app");
                    },
                    fillColor: AppConfig.appColor,
                    padding: EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    elevation: 10,
                    child: Center(
                        child: Text(
                      "Sigu Up",
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
                        "Or Sign-Up With",
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
                            handleSignUp("facebook");
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
                              handleSignUp("apple");
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
                              handleSignUp("google");
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
                    popUpUntil(context, LoginPage());
                  },
                  child: Container(
                    padding: EdgeInsets.all(15),
                    alignment: Alignment.center,
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: "Already have an Account? ",
                          style: textStyle(true, 16, black)),
                      TextSpan(
                          text: "Sign In? ",
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

  handleSignUp(String type) async {
    var result = await (Connectivity().checkConnectivity());
    if (result == ConnectivityResult.none) {
      snack("No internet connectivity");
      return;
    }

    if (type == "app") {
      String email = emailController.text.trim();
      String username = userNameController.text.trim();
      String password = passwordController.text;
      String appEmail = "$username@handwash.app";

      if (username.isEmpty) {
        snack("Enter Username!");
        return;
      }

      if (email.isEmpty) {
        snack("Enter Your Email!");
        return;
      }

      if (password.isEmpty) {
        snack("Enter Password!");
        return;
      }
      showProgress(true, context, msg: "Loggin In");
      loginIntoApp(null, email: appEmail, pass: password);
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
                .createUserWithEmailAndPassword(email: email, password: pass)
            : FirebaseAuth.instance.signInWithCredential(credential))
        .then((value) {
      final account = value.user;

      final emailCredential = EmailAuthProvider.getCredential(
          email: emailController.text, password: pass);
      //value.user.linkWithCredential(emailCredential);

      Firestore.instance
          .collection(USER_BASE)
          .document(account.uid)
          .get()
          .then((doc) {
        if (!doc.exists) {
          userModel
            ..put(USER_ID, account.uid)
            ..put(EMAIL, emailController.text)
            ..put(USER_IMAGE, account.photoUrl)
            ..put(NAME, account.displayName)
            ..put(USERNAME, userNameController.text)
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
