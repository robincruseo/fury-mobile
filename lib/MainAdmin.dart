import 'dart:async';
import 'dart:io';
import 'dart:io' as io;
import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:handwash/assets.dart';
import 'package:handwash/basemodel.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:location/location.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

import 'AppEngine.dart';
import 'app_config.dart';

Map<String, List> unreadCounter = Map();
Map otherPeronInfo = Map();
List<BaseModel> allStoryList = new List();
final firebaseMessaging = FirebaseMessaging();
final chatMessageController = StreamController<bool>.broadcast();
final homeRefreshController = StreamController<bool>.broadcast();
final uploadingController = StreamController<String>.broadcast();
final pageSubController = StreamController<int>.broadcast();
final overlayController = StreamController<bool>.broadcast();
final subscriptionController = StreamController<bool>.broadcast();
final adsController = StreamController<bool>.broadcast();

const bool kAutoConsume = true;
final connection = InAppPurchaseConnection.instance;

List<String> _notFoundIds = [];
List<ProductDetails> availablePackages = [];
List<PurchaseDetails> _purchases = [];

bool packagesAvailable = false;
bool _purchasePending = false;
bool _loading = true;
String _queryProductError;

List connectCount = [];
List<String> stopListening = List();
List<BaseModel> lastMessages = List();
bool chatSetup = false;
List showNewMessageDot = [];
bool showNewNotifyDot = false;
List newStoryIds = [];
String visibleChatId;
bool itemsLoaded = false;
List hookupList = [];
bool strockSetup = false;

List matches = [];
bool matchSetup = false;

Location location = new Location();
GeoFirePoint myLocation;

bool serviceEnabled = false;
PermissionStatus permissionGranted;
LocationData locationData;

List<BaseModel> adsList = [];
bool adsSetup = false;

var notificationsPlugin = FlutterLocalNotificationsPlugin();

class MainAdmin extends StatefulWidget {
  @override
  _MainAdminState createState() => _MainAdminState();
}

class _MainAdminState extends State<MainAdmin>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  PageController peoplePageController = PageController();
  List<StreamSubscription> subs = List();
  int timeOnline = 0;
  String noInternetText = "";

  String flashText = "";
  bool setup = false;
  bool settingsLoaded = false;
  String uploadingText;
  int peopleCurrentPage = 0;
  bool tipHandled = false;
  bool tipShown = true;

  @override
  void dispose() {
    // TODO: implement dispose
    WidgetsBinding.instance.removeObserver(this);
    for (var sub in subs) {
      sub.cancel();
    }
    strockImagesTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    itemsLoaded = false;
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(Duration(seconds: 1), () {
      createUserListener();
    });
    var subSub = subscriptionController.stream.listen((b) {
      if (!b) return;
      showMessage(context, Icons.check, green, "Congratulations!",
          "You are now a Premium User. Enjoy the benefits!");
    });
    subs.add(subSub);
    var pageSub = pageSubController.stream.listen((int p) {
      setState(() {
        peopleCurrentPage = p;
      });
    });
    subs.add(pageSub);
    var uploadingSub = uploadingController.stream.listen((text) {
      setState(() {
        uploadingText = text;
      });
    });
    subs.add(uploadingSub);

//    final Stream purchaseUpdates =
//        InAppPurchaseConnection.instance.purchaseUpdatedStream;
//    var purchaseSub = purchaseUpdates.listen((purchases) {
//      print(purchases);
//    });
//    subs.add(purchaseSub);
  }

  checkTip() {
    if (!tipHandled &&
        peopleCurrentPage != hookupList.length - 1 &&
        hookupList.length > 1) {
      tipHandled = true;
      Future.delayed(Duration(seconds: 1), () async {
        SharedPreferences pref = await SharedPreferences.getInstance();
        tipShown = pref.getBool("swipe_tipx") ?? false;
        if (!tipShown) {
          pref.setBool("swipe_tipx", true);
          setState(() {});
        }
      });
    }
  }

  okLayout(bool manually) {
    checkTip();
    itemsLoaded = true;
    if (mounted) setState(() {});
    Future.delayed(Duration(milliseconds: 1000), () {
//      if(manually)pageScrollController.add(-1);
      if (manually) peoplePageController.jumpToPage(peopleCurrentPage);
    });
  }

  Future<int> getSeenCount(String id) async {
    var pref = await SharedPreferences.getInstance();
    List<String> list = pref.getStringList(SHOWN) ?? [];
    int index = list.indexWhere((s) => s.contains(id));
    if (index != -1) {
      String item = list[index];
//      print(item);
      var parts = item.split(SPACE);
      int seenCount = int.parse(parts[1].trim());
      return seenCount;
    }
    return 0;
  }

  void createUserListener() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    if (user != null) {
      var userSub = Firestore.instance
          .collection(USER_BASE)
          .document(user.uid)
          .snapshots()
          .listen((shot) async {
        if (shot != null) {
          FirebaseUser user = await FirebaseAuth.instance.currentUser();
          if (user == null) return;

          userModel = BaseModel(doc: shot);
          isAdmin = userModel.getBoolean(IS_ADMIN) ||
              userModel.getString(EMAIL) == "johnebere58@gmail.com" ||
              userModel.getString(EMAIL) == "ammaugost@gmail.com";
          loadBlocked();

          if (!settingsLoaded) {
            settingsLoaded = true;
            loadSettings();
          }
        }
      });
      subs.add(userSub);
    }
  }

  loadSettings() async {
    var settingsSub = Firestore.instance
        .collection(APP_SETTINGS_BASE)
        .document(APP_SETTINGS)
        .snapshots()
        .listen((shot) {
      if (shot != null) {
        appSettingsModel = BaseModel(doc: shot);
        chkUpdate();
        List banned = appSettingsModel.getList(BANNED);
        if (banned.contains(userModel.getObjectId()) ||
            banned.contains(userModel.getString(DEVICE_ID)) ||
            banned.contains(userModel.getEmail())) {
          io.exit(0);
        }

        String genMessage = appSettingsModel.getString(GEN_MESSAGE);
        int genMessageTime = appSettingsModel.getInt(GEN_MESSAGE_TIME);

        if (userModel.getInt(GEN_MESSAGE_TIME) != genMessageTime &&
            genMessageTime > userModel.getTime()) {
          userModel.put(GEN_MESSAGE_TIME, genMessageTime);
          userModel.updateItems();

          String title = !genMessage.contains("+")
              ? "Announcement!"
              : genMessage.split("+")[0].trim();
          String message = !genMessage.contains("+")
              ? genMessage
              : genMessage.split("+")[1].trim();
          showMessage(context, Icons.info, blue0, title, message);
        }

        if (!setup) {
          setup = true;
          blockedIds.addAll(userModel.getList(BLOCKED));
          onResume();
          //loadItems();
          loadNotification();
          loadMessages();
          loadConnects();
          setupPush();

          loadBlocked();
          loadStory();
          updatePackage();
          setUpLocation();
          checkPhotos();
          loadQuickStrock();
          loadStrockTimer();
          loadRecommended();
          loadAds();
          //loadStoreInfo();
        }
      }
    });
    subs.add(settingsSub);
  }

  loadStoreInfo() async {
    final bool isAvailable = await connection.isAvailable();
    print("ava $isAvailable");
    if (!isAvailable) {
      setState(() {
        packagesAvailable = isAvailable;
        availablePackages = [];
        _purchases = [];
        _notFoundIds = [];
//        _consumables = [];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    final productIds =
        Set<String>.from(appSettingsModel.getList(PURCHASE_PRODUCT_IDS))
            .toSet();

    print(productIds);
    //return;

    ProductDetailsResponse productDetailResponse =
        await connection.queryProductDetails(productIds);
    if (productDetailResponse.error != null) {
      setState(() {
        _queryProductError = productDetailResponse.error.message;
        packagesAvailable = isAvailable;
        availablePackages = productDetailResponse.productDetails;
        _purchases = [];
        _notFoundIds = productDetailResponse.notFoundIDs;
//        _consumables = [];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _queryProductError = null;
        packagesAvailable = isAvailable;
        availablePackages = productDetailResponse.productDetails;
        _purchases = [];
        _notFoundIds = productDetailResponse.notFoundIDs;
//        _consumables = [];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    final QueryPurchaseDetailsResponse purchaseResponse =
        await connection.queryPastPurchases();
    if (purchaseResponse.error != null) {
      // handle query past purchase error..
    }
    final List<PurchaseDetails> verifiedPurchases = [];
    for (PurchaseDetails purchase in purchaseResponse.pastPurchases) {
      if (await _verifyPurchase(purchase)) {
        verifiedPurchases.add(purchase);
      }
    }
//    List<String> consumables = await ConsumableStore.load();
    setState(() {
      packagesAvailable = isAvailable;
      availablePackages = productDetailResponse.productDetails;
      _purchases = verifiedPurchases;
      _notFoundIds = productDetailResponse.notFoundIDs;
//      _consumables = consumables;
      _purchasePending = false;
      _loading = false;
    });
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) {
    // IMPORTANT!! Always verify a purchase before delivering the product.
    // For the purpose of an example, we directly return true.
    return Future<bool>.value(true);
  }

  loadAds() async {
    var adsSub = Firestore.instance
        .collection(ADS_BASE)
        .where(COUNTRY, isEqualTo: userModel.getString(COUNTRY))
        .where(ADS_EXPIRY, isLessThan: DateTime.now().millisecondsSinceEpoch)
        .snapshots()
        .listen((shots) {
      for (var doc in shots.documentChanges) {
        print(shots.documents.length);
        final model = BaseModel(doc: doc.document);
        if (doc.type == DocumentChangeType.removed) {
          adsList.removeWhere((e) => e.getObjectId() == model.getObjectId());
          continue;
        }
        //if (model.myItem()) continue;
        if (model.getInt(STATUS) != APPROVED) continue;
        int p =
            adsList.indexWhere((e) => e.getObjectId() == model.getObjectId());
        if (p != -1) {
          adsList[p] = model;
        } else {
          adsList.add(model);
        }
      }

      adsSetup = true;
      if (mounted) setState(() {});
    });
    subs.add(adsSub);
  }

  loadRecommended() async {
    QuerySnapshot shots1 = await Firestore.instance
        .collection(USER_BASE)
        .where(GENDER, isEqualTo: userModel.getInt(PREFERENCE))
        .where(RELATIONSHIP, isEqualTo: userModel.getInt(RELATIONSHIP))
        .getDocuments();

    QuerySnapshot shots2 = await Firestore.instance
        .collection(USER_BASE)
        .where(GENDER, isEqualTo: userModel.getInt(PREFERENCE))
        .where(ETHNICITY, isEqualTo: userModel.getInt(ETHNICITY))
        .getDocuments();

    List allShots = [];
    allShots.addAll(shots1.documents);
    allShots.addAll(shots2.documents);

    for (DocumentSnapshot doc in allShots) {
      BaseModel model = BaseModel(doc: doc);
      if (model.myItem()) continue;
      if (userModel.getList(BLOCKED).contains(model.getObjectId())) continue;
      int index =
          matches.indexWhere((bm) => model.getObjectId() == bm.getObjectId());
      if (index == -1) {
        matches.add(model);
      }
    }
    matchSetup = true;
    if (mounted) setState(() {});
  }

  String strockImage;
  var loadingSub;
  int minAge = 18;
  int maxAge = 80;
  int onlineType = -1;
  int interestType = -1;
  int genderType = -1;
  Timer strockImagesTimer;

  loadQuickStrock() async {
    if (loadingSub != null) {
      loadingSub.cancel();
      hookupList.clear();
      setup = false;
      setState(() {});
    }
    Geoflutterfire geo = Geoflutterfire();
    Map myPosition = userModel.getMap(POSITION);
    if (myPosition.isEmpty) {
      return;
    }
    GeoPoint geoPoint = myPosition["geopoint"];
    double lat = geoPoint.latitude;
    double lon = geoPoint.longitude;
    // if (filterLocation != null) {
    //   lat = filterLocation.getDouble(LATITUDE);
    //   lon = filterLocation.getDouble(LONGITUDE);
    // }
    GeoFirePoint center = geo.point(latitude: lat, longitude: lon);

    // get the collection reference or query
    var collectionReference = Firestore.instance
        .collection(USER_BASE)
        .where(QUICK_HOOKUP, isEqualTo: 0);
    double radius = 50000;
    loadingSub = geo
        .collection(collectionRef: collectionReference)
        .within(center: center, radius: radius, field: POSITION)
        .listen((event) {
      for (DocumentSnapshot doc in event) {
        BaseModel model = BaseModel(doc: doc);
        if (model.myItem()) continue;
        if (!model.signUpCompleted) continue;
        if (genderType != -1) if (model.getInt(GENDER) != genderType) continue;
        if (onlineType > 0) {
          if (onlineType == 1) if (!isOnline(model)) continue;
          int now = DateTime.now().millisecondsSinceEpoch;
          if (onlineType == 2) if ((now - (model.getInt(TIME))) >
              Duration.millisecondsPerSecond) continue;
        }

        if (minAge != -1) {
          int age = getAge(DateTime.parse(model.getString(BIRTH_DATE)));
          if (minAge > age) continue;
        }
        if (maxAge != -1) {
          int age = getAge(DateTime.parse(model.getString(BIRTH_DATE)));
          if (maxAge < age) continue;
        }
        if (interestType != -1) {
          if (model.getInt(RELATIONSHIP) != interestType) continue;
        }

        if (model.hookUpPhotos.isEmpty) continue;
        if (model.getInt(GENDER) != userModel.getInt(PREFERENCE)) continue;
        int index = hookupList
            .indexWhere((bm) => bm.getObjectId() == model.getObjectId());
        if (index == -1) hookupList.add(model);
      }
      loadingSub.cancel();
      strockSetup = true;
      if (mounted) setState(() {});
    });
  }

  loadStrockTimer() {
    strockImagesTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (hookupList.isEmpty) return;

      final rand = Random();
      int p = rand.nextInt(hookupList.length);
      BaseModel model = hookupList[p];
      //print(p);
      //print(model.getList(HOOKUP_PHOTOS));
      //print(model.items);
      // if (model.hookUpPhotos.isEmpty) {
      //   model = peopleList[nextP];
      //   strockImage = model.hookUpPhotos[0].imageUrl;
      // }
      strockImage = model.hookUpPhotos[model.getInt(DEF_STROCK_PHOTO)].imageUrl;
      if (mounted) setState(() {});
    });
  }

  checkPhotos() {
    List<BaseModel> profilePhotos = userModel.profilePhotos;
    List<BaseModel> hookUpPhotos = userModel.hookUpPhotos;

    final notUploadedPhotos = profilePhotos.where((e) => e.isLocal);
    final notUploadedHooks = hookUpPhotos.where((e) => e.isLocal);

    if (notUploadedPhotos.isEmpty && notUploadedHooks.isEmpty) return;

    uploadMediaFiles(profilePhotos, onError: (e) {
      uploadMediaFiles(profilePhotos, onError: (e) {},
          onUploaded: (List<BaseModel> p) {
        userModel
          ..put(PROFILE_PHOTOS, p.map((e) => e.items).toList())
          ..updateItems();
        setState(() {});
      });
    }, onUploaded: (List<BaseModel> p) {
      userModel
        ..put(PROFILE_PHOTOS, p.map((e) => e.items).toList())
        ..updateItems();
      setState(() {});
    });

    uploadMediaFiles(hookUpPhotos, onError: (e) {
      uploadMediaFiles(hookUpPhotos, onError: (e) {},
          onUploaded: (List<BaseModel> p) {
        userModel
          ..put(HOOKUP_PHOTOS, p.map((e) => e.items).toList())
          ..updateItems();
        setState(() {});
      });
    }, onUploaded: (List<BaseModel> p) {
      userModel
        ..put(HOOKUP_PHOTOS, p.map((e) => e.items).toList())
        ..updateItems();
      setState(() {});
    });
  }

  chkUpdate() async {
    int version = appSettingsModel.getInt(VERSION_CODE);
    PackageInfo pack = await PackageInfo.fromPlatform();
    String v = pack.buildNumber;
    int myVersion = int.parse(v);
    if (myVersion < version) {
      pushAndResult(context, UpdateLayout(), opaque: false);
    }
  }

  handleMessage(var message) async {
    final dynamic data = Platform.isAndroid ? message['data'] : message;
    BaseModel model = BaseModel(items: data);
    String title = model.getString("title");
    String body = model.getString("message");

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'strock.maugost.nt', 'Maugost', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await notificationsPlugin.show(0, title, body, platformChannelSpecifics,
        payload: 'item x');

    if (data != null) {
      String type = data[TYPE];
      String id = data[OBJECT_ID];
      if (type != null) {
        if (type == PUSH_TYPE_CHAT && visibleChatId != id) {
//          pushAndResult(
//              context,
//              ChatMain(
//                id,
//                otherPerson: null,
//              ));
        }
      }
    }
  }

  setUpLocation() async {
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    locationData = await location.getLocation();
    Geoflutterfire geo = Geoflutterfire();

    myLocation = geo.point(
        latitude: locationData.latitude, longitude: locationData.longitude);

    //Placemark.
    final placemark = await Geolocator()
        .placemarkFromCoordinates(myLocation.latitude, myLocation.longitude);

//    print(
//        "PlaceMarker ${placemark[0].toJson()}  Lat ${myLocation.latitude} Long ${myLocation.longitude}");
//

    userModel
      ..put(POSITION, myLocation.data)
      ..put(MY_LOCATION, placemark[0].name)
      ..put(COUNTRY, placemark[0].country)
      ..put(COUNTRY_CODE, placemark[0].isoCountryCode)
      ..updateItems();
  }

  setupPush() async {
    firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        //handleMessage(message);
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        handleMessage(message);
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        handleMessage(message);
      },
    );
    firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    if (userModel.isAdminItem()) {
      firebaseMessaging.subscribeToTopic('admin');
    }

    firebaseMessaging.subscribeToTopic('all');
    firebaseMessaging.getToken().then((String token) async {
      List myTopics = List.from(userModel.getList(TOPICS));

      if (userModel.isAdminItem() && !myTopics.contains('admin')) {
        myTopics.add('admin');
      }
      if (!myTopics.contains('all')) myTopics.add('all');

      userModel.put(TOPICS, myTopics);
      userModel.put(TOKEN, token);
      userModel.updateItems();
    });

    //local notifications

    notificationsPlugin = FlutterLocalNotificationsPlugin();
    var androidSettings = AndroidInitializationSettings('ic_notify');
    var iosSettings = IOSInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
        onDidReceiveLocalNotification:
            (int id, String title, String body, String payload) async {
          print(payload);
        });

    var initializationSettings =
        InitializationSettings(androidSettings, iosSettings);
    await notificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String payload) async {});

    if (Platform.isIOS) {
      var result = await notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      print("Permission result $result");
    }
  }

  void onPause() {
    if (userModel == null) return;
    int prevTimeOnline = userModel.getInt(TIME_ONLINE);
    int timeActive = (DateTime.now().millisecondsSinceEpoch) - timeOnline;
    int newTimeOnline = timeActive + prevTimeOnline;
    userModel.put(IS_ONLINE, false);
    userModel.put(TIME_ONLINE, newTimeOnline);
    userModel.updateItems();
    timeOnline = 0;
  }

  void onResume() async {
    if (userModel == null) return;

    timeOnline = DateTime.now().millisecondsSinceEpoch;
    userModel.put(IS_ONLINE, true);
    userModel.put(
        PLATFORM, Platform.isAndroid ? ANDROID : Platform.isIOS ? IOS : WEB);
    if (!userModel.getBoolean(NEW_APP)) {
      userModel.put(NEW_APP, true);
    }
    userModel.updateItems();

    Future.delayed(Duration(seconds: 2), () {
      setUpLocation();
      checkLaunch();
    });
  }

  Future<void> checkLaunch() async {
    const platform = const MethodChannel("channel.john");
    try {
      Map response = await platform
          .invokeMethod('launch', <String, String>{'message': ""});
      int type = response[TYPE];
      String chatId = response[CHAT_ID];

//      toastInAndroid(type.toString());
//      toastInAndroid(chatId);

      if (type == LAUNCH_CHAT) {
//        pushAndResult(
//            context,
//            ChatMain(
//              chatId,
//              otherPerson: null,
//            ));
      }

      if (type == LAUNCH_REPORTS) {
//        pushAndResult(context, ReportMain());
      }

      //toastInAndroid(response);
    } catch (e) {
      //toastInAndroid(e.toString());
      //batteryLevel = "Failed to get what he said: '${e.message}'.";
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    if (state == AppLifecycleState.paused) {
      onPause();
    }
    if (state == AppLifecycleState.resumed) {
      onResume();
    }

    super.didChangeAppLifecycleState(state);
  }

  List loadedIds = [];
  loadMessages() async {
    var lock = Lock();
    await lock.synchronized(() async {
//      List<Map> myChats = List.from(userModel.getList(MY_CHATS));
      var sub = Firestore.instance
          .collection(CHAT_IDS_BASE)
          .where(PARTIES, arrayContains: userModel.getObjectId())
          .snapshots()
          .listen((shots) {
        for (DocumentSnapshot doc in shots.documents) {
          BaseModel chatIdModel = BaseModel(doc: doc);
          String chatId = chatIdModel.getObjectId();
          if (userModel.getList(DELETED_CHATS).contains(chatId)) continue;
          if (loadedIds.contains(chatId)) {
            continue;
          }
          loadedIds.add(chatId);

          var sub = Firestore.instance
              .collection(CHAT_BASE)
              .where(PARTIES, arrayContains: userModel.getUserId())
              .where(CHAT_ID, isEqualTo: chatId)
              .orderBy(TIME, descending: true)
              .limit(1)
              .snapshots()
              .listen((shots) async {
            if (shots.documents.isNotEmpty) {
              BaseModel cModel = BaseModel(doc: (shots.documents[0]));
              if (isBlocked(null, userId: getOtherPersonId(cModel))) {
                lastMessages.removeWhere(
                    (bm) => bm.getString(CHAT_ID) == cModel.getString(CHAT_ID));
                chatMessageController.add(true);
                return;
              }
            }
            if (stopListening.contains(chatId)) return;
            for (DocumentSnapshot doc in shots.documents) {
              BaseModel model = BaseModel(doc: doc);
              String chatId = model.getString(CHAT_ID);
              int index = lastMessages.indexWhere(
                  (bm) => bm.getString(CHAT_ID) == model.getString(CHAT_ID));
              if (index == -1) {
                lastMessages.add(model);
              } else {
                lastMessages[index] = model;
              }

              if (!model.getList(READ_BY).contains(userModel.getObjectId()) &&
                  !model.myItem() &&
                  visibleChatId != model.getString(CHAT_ID)) {
                try {
                  if (!showNewMessageDot.contains(chatId))
                    showNewMessageDot.add(chatId);
                  setState(() {});
                } catch (E) {
                  if (!showNewMessageDot.contains(chatId))
                    showNewMessageDot.add(chatId);
                  setState(() {});
                }
                countUnread(chatId);
              }
            }

            String otherPersonId = getOtherPersonId(chatIdModel);
            loadOtherPerson(otherPersonId);

            try {
              lastMessages
                  .sort((bm1, bm2) => bm2.getTime().compareTo(bm1.getTime()));
            } catch (E) {}
          });

          subs.add(sub);
        }
        chatSetup = true;
        if (mounted) setState(() {});
      });
      subs.add(sub);
    });
  }

  loadConnects() async {
    var lock = Lock();
    await lock.synchronized(() async {
      var sub = Firestore.instance
          .collection(CONNECTS_BASE)
          .where(PARTIES, arrayContains: userModel.getObjectId())
          .snapshots()
          .listen((shots) {
        for (DocumentSnapshot doc in shots.documents) {
          BaseModel connect = BaseModel(doc: doc);
          if (!connect.getList(READ_BY).contains(userModel.getObjectId())) {
            if (!connectCount.contains(connect.getObjectId()))
              connectCount.add(connect.getObjectId());
          }
        }
        if (mounted) setState(() {});
      });
      subs.add(sub);
    });
  }

  loadOtherPerson(String uId, {int delay = 0}) async {
    var lock = Lock();
    await lock.synchronized(() async {
      Future.delayed(Duration(seconds: delay), () async {
        DocumentSnapshot doc =
            await Firestore.instance.collection(USER_BASE).document(uId).get();

        if (doc == null) return;
        if (!doc.exists) return;

        BaseModel user = BaseModel(doc: doc);
        otherPeronInfo[uId] = user;
        if (mounted) setState(() {});
      });
    }, timeout: Duration(seconds: 10));
  }

  countUnread(String chatId) async {
    var lock = Lock();
    lock.synchronized(() async {
      int count = 0;
      QuerySnapshot shots = await Firestore.instance
          .collection(CHAT_BASE)
          .where(CHAT_ID, isEqualTo: chatId)
          .getDocuments();

      List list = [];
      for (DocumentSnapshot doc in shots.documents) {
        BaseModel model = BaseModel(doc: doc);
        if (!model.getList(READ_BY).contains(userModel.getObjectId()) &&
            !model.myItem()) {
          count++;
          list.add(model);
        }
      }
      if (list.isNotEmpty) unreadCounter[chatId] = list;
      chatMessageController.add(true);
    });
  }

  loadNotification() async {
    var sub = Firestore.instance
        .collection(NOTIFY_BASE)
        .where(PARTIES, arrayContains: userModel.getUserId())
        .limit(1)
        .orderBy(TIME_UPDATED, descending: true)
        .snapshots()
        .listen((shots) {
      //toastInAndroid(shots.documents.length.toString());
      for (DocumentSnapshot d in shots.documents) {
        BaseModel model = BaseModel(doc: d);
        /*int p = nList
            .indexWhere((bm) => bm.getObjectId() == model.getObjectId());
        if (p == -1) {
          nList.add(model);
        } else {
          nList[p] = model;
        }*/

        if (!model.getList(READ_BY).contains(userModel.getObjectId()) &&
            !model.myItem()) {
          showNewNotifyDot = true;
          setState(() {});
        }
      }
      /*nList.sort((bm1, bm2) =>
          bm2.getInt(TIME_UPDATED).compareTo(bm1.getInt(TIME_UPDATED)));*/
    });

    subs.add(sub);
    //notifySetup = true;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: () {
        //backThings();
        io.exit(0);
        return;
      },
      child: Scaffold(
        backgroundColor: AppConfig.appColor,
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                color: AppConfig.appColor,
                height: MediaQuery.of(context).size.height * .3,
              ),
              page()
            ],
          ),
        ),
      ),
    );
  }

  topWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          //duration: Duration(milliseconds: 500),
//      color: AppConfig.appColor,
          color: showTop ? AppConfig.appColor : transparent,
//      height: 100,
          margin: EdgeInsets.only(bottom: 0),
          padding: EdgeInsets.only(top: 0, right: 15, left: 15, bottom: 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(
//        mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  fit: FlexFit.tight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(
                            text: "Hi ",
                            style: textStyle(true, showTop ? 20 : 30, white)),
                        TextSpan(
                            text: "${userModel.getUserName()},",
                            // text: "Maugost,",
                            style: textStyle(true, showTop ? 20 : 30, white))
                      ])),
                      Text("Have you washed your hands Today?.",
                          style: textStyle(
                              true, showTop ? 15 : 20, white.withOpacity(.7)))
                    ],
                  ),
                ),
                userImageItem(context, userModel, size: showTop ? 55 : 80)
              ],
            ),
          ]),
        ),
        if (showTop) gradientLine(reverse: true)
      ],
    );
  }

  bool showTop = false;
  page() {
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              color: AppConfig.appColor,
              height: 200,
              width: double.infinity,
              child: Opacity(
                  opacity: .2,
                  child: Image.asset("assets/bg/clock_bg.jpg",
                      height: 200, width: double.infinity, fit: BoxFit.cover)),
            ),
            Expanded(
                child: Container(
              color: white,
              width: double.infinity,
            ))
          ],
        ),
        NotificationListener(
          onNotification: (ScrollNotification n) {
            double px = n.metrics.pixels;
//            print("Scroll: $px");
            if (px > 85) {
              if (!showTop) {
                showTop = true;
                setState(() {});
              }
            } else {
              if (showTop) {
                showTop = false;
                setState(() {});
              }
            }
            return true;
          },
          child: Container(
              child: ListView(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
            children: [addSpace(40), topWidget(), remindersList()],
          )),
        ),
        if (showTop) topWidget()
      ],
    );
  }

  remindersList() {
    return ListView.builder(
        itemCount: 9,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (ctx, p) {
          return reminderItem(p);
        });
  }

  reminderItem(int p) {
    bool active = p == 0;
    return Container(
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: (active ? white : black).withOpacity(active ? 0.5 : 0.2),
                blurRadius: 5)
          ],
          color: active ? AppConfig.appColor : white,
          borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.all(15),
      padding: EdgeInsets.all(15),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Wake up alarm",
                style:
                    textStyle(false, 16, active ? white : AppConfig.appColor),
              ),
              Text(
                "9:00",
                style: textStyle(true, 30, active ? white : AppConfig.appColor),
              ),
              Text(
                "Mon,Wed,Tues",
                style:
                    textStyle(false, 14, active ? white : AppConfig.appColor),
              )
            ],
          ),
          Spacer(),
          platformSwitch(switchStatus, (b) {
            setState(() {
              switchStatus = !switchStatus;
            });
          }, active: active)
        ],
      ),
    );
  }

  bool switchStatus = false;

  platformSwitch(bool value, onChange, {bool active = false}) {
    bool isIos = Platform.isIOS;
    return isIos
        ? CupertinoSwitch(
            value: value,
            onChanged: onChange,
            trackColor: active ? white : null,
            activeColor: AppConfig.appColor,
          )
        : Switch(
            onChanged: onChange,
            activeTrackColor: active ? white : null,
            activeColor: AppConfig.appColor,
            value: value,
          );
  }

  backThings() {
    if (userModel != null && !userModel.getBoolean(HAS_RATED)) {
      showMessage(context, Icons.star, blue0, "Rate Us",
          "Enjoying the App? Please support us with 5 stars",
          clickYesText: "RATE APP", clickNoText: "Later", onClicked: (_) {
        if (_ == true) {
          if (appSettingsModel == null ||
              appSettingsModel.getString(PACKAGE_NAME).isEmpty) {
            onPause();
            Future.delayed(Duration(seconds: 1), () {
              io.exit(0);
            });
          } else {
            rateApp();
          }
        } else {
          onPause();
          Future.delayed(Duration(seconds: 1), () {
            io.exit(0);
          });
        }
      });
      return;
    }
    onPause();
    Future.delayed(Duration(seconds: 1), () {
      io.exit(0);
    });
  }

  loadStory() async {
    var storySub = Firestore.instance
        .collection(STORY_BASE)
        .where(GENDER, isEqualTo: userModel.isMale() ? FEMALE : MALE)
        .where(TIME,
            isGreaterThan: (DateTime.now().millisecondsSinceEpoch -
                (Duration.millisecondsPerDay * 2)))
        .snapshots()
        .listen((shots) {
      bool added = false;
      for (DocumentSnapshot shot in shots.documents) {
        if (!shot.exists) continue;
        BaseModel model = BaseModel(doc: shot);
        if (isBlocked(model)) continue;
        int index = allStoryList
            .indexWhere(((bm) => bm.getObjectId() == model.getObjectId()));
        if (index == -1) {
          allStoryList.add(model);
          added = true;
          if (!model.myItem() &&
              !model.getList(SHOWN).contains(userModel.getObjectId())) {
            if (!newStoryIds.contains(model.getObjectId()))
              newStoryIds.add(model.getObjectId());
          }
        } else {
          allStoryList[index] = model;
        }
      }
      homeRefreshController.add(true);
    });
    var myStorySub = Firestore.instance
        .collection(STORY_BASE)
        .where(USER_ID, isEqualTo: userModel.getObjectId())
        .snapshots()
        .listen((shots) {
      bool added = false;
      for (DocumentSnapshot shot in shots.documents) {
        if (!shot.exists) continue;
        BaseModel model = BaseModel(doc: shot);
        if (isBlocked(model)) continue;
        int index = allStoryList
            .indexWhere(((bm) => bm.getObjectId() == model.getObjectId()));
        if (index == -1) {
          allStoryList.add(model);
          added = true;
        } else {
          allStoryList[index] = model;
        }
      }
      homeRefreshController.add(true);
    });
    subs.add(storySub);
    subs.add(myStorySub);
  }

  loadBlocked() async {
    var lock = Lock();
    lock.synchronized(() async {
      QuerySnapshot shots = await Firestore.instance
          .collection(USER_BASE)
          .where(BLOCKED, arrayContains: userModel.getObjectId())
          .getDocuments();

      for (DocumentSnapshot doc in shots.documents) {
        BaseModel model = BaseModel(doc: doc);
        String uId = model.getObjectId();
        String deviceId = model.getString(DEVICE_ID);
        if (!blockedIds.contains(uId)) blockedIds.add(uId);
        if (deviceId.isNotEmpty) if (!blockedIds.contains(deviceId))
          blockedIds.add(deviceId);
      }
    }, timeout: Duration(seconds: 10));
  }

  saveStories(List models) async {
    if (models.isEmpty) {
      uploadingController.add("Uploading Successful");
      Future.delayed(Duration(seconds: 1), () {
        uploadingController.add(null);
      });
      return;
    }
    uploadingController.add("Uploading Story");

    BaseModel model = models[0];
    String image = model.getString(STORY_IMAGE);
    uploadFile(File(image), (res, error) {
      if (error != null) {
        saveStories(models);
        return;
      }
      model.put(STORY_IMAGE, res);
      model.saveItem(STORY_BASE, true);
      models.removeAt(0);
      saveStories(models);
    });
  }

  getStackedImages(List list) {
    List items = [];
    int count = 0;
    for (int i = 0; i < list.length; i++) {
      if (count > 10) break;
      BaseModel model = hookupList[i];
      items.add(Container(
        margin: EdgeInsets.only(left: double.parse((i * 20).toString())),
        child: userImageItem(context, model,
            size: 40, padLeft: false, type: "nah"),
      ));
      count++;
    }
    List<Widget> children = List.from(items.reversed);
    return IgnorePointer(
      ignoring: true,
      child: Container(
        height: 40,
        child: Stack(
          children: children,
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class UpdateLayout extends StatelessWidget {
  BuildContext con;
  @override
  Widget build(BuildContext context) {
    String features = appSettingsModel.getString(NEW_FEATURE);
    if (features.isNotEmpty) features = "* $features";
    bool mustUpdate = appSettingsModel.getBoolean(MUST_UPDATE);
    con = context;
    return WillPopScope(
      onWillPop: () {},
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: black.withOpacity(.6),
              )),
          Container(
            padding: EdgeInsets.all(15),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      if (isAdmin) {
                        Navigator.pop(con);
                      }
                    },
                    child: Image.asset(
                      ic_plain,
                      width: 60,
                      height: 60,
                      color: white,
                    ),
                  ),
                  addSpace(10),
                  Text(
                    "New Update Available",
                    style: textStyle(true, 22, white),
                    textAlign: TextAlign.center,
                  ),
                  addSpace(10),
                  Text(
                    features.isEmpty
                        ? "Please update your App to proceed"
                        : features,
                    style: textStyle(false, 16, white.withOpacity(.5)),
                    textAlign: TextAlign.center,
                  ),
                  addSpace(15),
                  Container(
                    height: 40,
                    width: 120,
                    child: FlatButton(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                        color: blue3,
                        onPressed: () {
                          String appLink =
                              appSettingsModel.getString(APP_LINK_IOS);
                          if (Platform.isAndroid)
                            appLink =
                                appSettingsModel.getString(APP_LINK_ANDROID);
                          openLink(appLink);
                        },
                        child: Text(
                          "UPDATE",
                          style: textStyle(true, 14, white),
                        )),
                  ),
                  addSpace(15),
                  if (!mustUpdate)
                    Container(
                      height: 40,
                      child: FlatButton(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                          color: red0,
                          onPressed: () {
                            Navigator.pop(con);
                          },
                          child: Text(
                            "Later",
                            style: textStyle(true, 14, white),
                          )),
                    )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
