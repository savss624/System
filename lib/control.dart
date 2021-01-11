import 'dart:async';
import 'package:flutter/material.dart';
import 'package:background_stt/background_stt.dart';
import 'package:flashlight/flashlight.dart';
import 'package:hardware_buttons/hardware_buttons.dart' as HardwareButtons;
import 'package:system_shortcuts/system_shortcuts.dart';
import 'package:battery/battery.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:device_apps/device_apps.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:home_widget/home_widget.dart';
import 'package:delayed_display/delayed_display.dart';

class Control extends StatefulWidget {
  @override
  _ControlState createState() => _ControlState();
}

class _ControlState extends State<Control> with WidgetsBindingObserver {

  StreamSubscription<HardwareButtons.HomeButtonEvent> _homeButtonSubscription;

  var _service = BackgroundStt();
  var voiceReply = "";
  var isListening = false;
  var batteryLevel;
  var result = "Say something !";
  bool saying = false;

  List<Contact> contacts = [];
  List<Application> apps = [];

  Battery _battery = Battery();

  BatteryState _batteryState;
  StreamSubscription<BatteryState> _batteryStateSubscription;

  Future<void> send() {
    try{
      return Future.wait([
        HomeWidget.saveWidgetData<String>('Message', 'yes'),
      ]);
    } catch(e) {
      debugPrint(e);
    }
  }

  Future<void> update() {
    try{
      return HomeWidget.updateWidget(
        name: 'Home',
        androidName: 'Home',
      );
    } catch(e) {
      debugPrint(e);
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _service.startSpeechListenService;
    /*QuickActions quickActions = QuickActions();
    quickActions.initialize((type) {
      print(type);
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      ShortcutItem(
        type: 'reopen',
      )
    ]);
    send();
    update();*/
    _batteryStateSubscription =
        _battery.onBatteryStateChanged.listen((BatteryState state) {
          setState(() {
            _batteryState = state;
          });
        });

    _homeButtonSubscription = HardwareButtons.homeButtonEvents.listen((event) {
      _service.startSpeechListenService;
      _service.resumeListening();
    });
    getAllApps();
    getAllContacts();

    setState(() {
      if (mounted) isListening = true;
    });
    _service.getSpeechResults().onData((data) {
      print("getSpeechResults: ${data.result} , ${data.isPartial} [STT Mode]");

      protocols(data.result);

      setState(() {
        voiceReply = "";
        result = data.result;
      });
    });
    // TODO: implement initState
    super.initState();
  }

  Future<void> protocols (String command) async {

    if(command.toLowerCase().contains('hey')
        || command.toLowerCase().contains('hello')
        || command.toLowerCase().contains('anyone here')
        || command.toLowerCase().contains('koi hai')
        || command.toLowerCase().contains('jago')
        || command.toLowerCase().contains('utho')){
      if(saying == false) {
        saying = true;
        await _service.speak('at your service sir', false);
      }
      Timer(
          Duration(seconds: 1),
              () {
            saying = false;
          }
      );
    }

    if((command.toLowerCase().contains('flashlight')
            || command.toLowerCase().contains('flash'))
        && (command.toLowerCase().contains('khol')
            || command.toLowerCase().contains('on'))){
      Flashlight.lightOn();
    }

    if((command.toLowerCase().contains('flashlight')
            || command.toLowerCase().contains('flash'))
        && (command.toLowerCase().contains('of')
            || command.toLowerCase().contains('off')
            || command.toLowerCase().contains('band'))){
      Flashlight.lightOff();
    }

    if(command.toLowerCase().contains('rest')
        || command.toLowerCase().contains('mode')){
      _service.pauseListening();
      await _service.speak("", false);
    }

    if(command.toLowerCase().contains('bluetooth')
        && (command.toLowerCase().contains('khol')
            || command.toLowerCase().contains('on'))){
      if(!await SystemShortcuts.checkBluetooth)
        await SystemShortcuts.bluetooth();
    }

    if(command.toLowerCase().contains('bluetooth')
        && (command.toLowerCase().contains('of')
            || command.toLowerCase().contains('off')
            || command.toLowerCase().contains('band'))){
      if(await SystemShortcuts.checkBluetooth)
        await SystemShortcuts.bluetooth();
    }

    if(command.toLowerCase().contains('exit')
        || command.toLowerCase().contains('home')){
      await SystemShortcuts.home();
    }

    batteryLevel = await _battery.batteryLevel;
    if((command.toLowerCase().contains('battery')
            || command.toLowerCase().contains('phone'))
        && (command.toLowerCase().contains('bata')
            || command.toLowerCase().contains('kitn')
            || command.toLowerCase().contains('left')
            || command.toLowerCase().contains('kya')
            || command.toLowerCase().contains('what')
            || command.toLowerCase().contains('tell'))){
      if(saying == false) {
        saying = true;
        await _service.speak(batteryLevel.toString() + ' percent battery level', false);
      }
      Timer(
        Duration(seconds: 3),
          () {
            saying = false;
          }
      );
    }

    if((command.toLowerCase().contains('date')
        && (command.toLowerCase().contains('bata')
            || command.toLowerCase().contains('kitn')
            || command.toLowerCase().contains('aaj')
            || command.toLowerCase().contains('today')
            || command.toLowerCase().contains('kya')
            || command.toLowerCase().contains('what')
            || command.toLowerCase().contains('tell')))){
      if(saying == false) {
        saying = true;
        await _service.speak(DateTime.now().toString().substring(0, DateTime.now().toString().length - 15), false);
      }
      Timer(
          Duration(seconds: 4),
              () {
            saying = false;
          }
      );
    }

    if((command.toLowerCase().contains('time')
        && (command.toLowerCase().contains('bata')
            || command.toLowerCase().contains('kitn')
            || command.toLowerCase().contains('abhi')
            || command.toLowerCase().contains('now')
            || command.toLowerCase().contains('kya')
            || command.toLowerCase().contains('bro')
            || command.toLowerCase().contains('what')
            || command.toLowerCase().contains('tell')))){
      if(saying == false) {
        saying = true;
        await _service.speak(DateTime.now().toString().substring(DateTime.now().toString().length - 15, DateTime.now().toString().length - 7), false);
      }
      Timer(
          Duration(seconds: 4),
              () {
            saying = false;
          }
      );
    }

    if(command.toLowerCase().contains('call')
        || command.toLowerCase().contains('phone')
        || command.toLowerCase().contains('mila')){
      for (int i = 0; i < contacts.length; i++)
        if (command.toLowerCase().contains(contacts[i].displayName.toLowerCase())) {
          await _service.pauseListening();
          FlutterPhoneDirectCaller.callNumber(
              contacts[i].phones.elementAt(0).value.toString());
          break;
        }
    }

    if(command.toLowerCase().contains('open')
        || command.toLowerCase().contains('khol')){
      for (int k = 0, i = 0; i < apps.length; i++) {
        List<String> s = apps[i].packageName.split(".");
        for (int j = 1; j < s.length; j++)
          if ((' '+command.toLowerCase()+' ').contains(' '+s[j].toLowerCase()+' ') && s[j] != 'in' && s[j] != 'app') {
            DeviceApps.openApp(apps[i].packageName);
            k = 1;
            break;
          }
        if (k == 1) break;
      }
    }

  }

  getAllApps() async {
    List<Application> _apps = await DeviceApps.getInstalledApplications();
    setState(() {
      apps = _apps;
    });
  }

  getAllContacts() async {
    List<Contact> _contacts =
    (await ContactsService.getContacts(withThumbnails: false)).toList();
    setState(() {
      contacts = _contacts;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _homeButtonSubscription?.cancel();
    if (_batteryStateSubscription != null) {
      _batteryStateSubscription.cancel();
    }
    _service.stopSpeechListenService;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Center(
            child: Image.asset(
                'assets/ui.gif',
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width,
            ),
          ),
          DelayedDisplay(
            delay: Duration(seconds: 1),
            fadingDuration: Duration(seconds: 1),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(right: 40, left: 40),
                child: Container(
                  height: 85,
                  child: Container(
                    child: SingleChildScrollView(
                        reverse: true,
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Text('$result\n\n',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        )),
                    width: MediaQuery.of(context).size.width*.33,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
