import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_notifications_tutorial/notifications.dart';
import 'package:flutter_awesome_notifications_tutorial/plant_stats_page.dart';
import 'package:flutter_awesome_notifications_tutorial/utilities.dart';
import 'package:flutter_awesome_notifications_tutorial/widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addObserver(this);

    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Allow Notifications'),
            content: Text('Our app would like to send you notifications'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Don\'t Allow',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                  ),
                ),
              ),
              TextButton(
                  onPressed: () =>
                      AwesomeNotifications().requestPermissionToSendNotifications().then((_) => Navigator.pop(context)),
                  child: Text(
                    'Allow',
                    style: TextStyle(
                      color: Colors.teal,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ))
            ],
          ),
        );
      }
    });

    AwesomeNotifications().createdStream.listen((notification) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Notification Created on ${notification.channelKey}',
        ),
      ));
    });

    AwesomeNotifications().actionStream.listen((notification) {
      if (notification.channelKey == 'basic_channel' && Platform.isIOS) {
        AwesomeNotifications().getGlobalBadgeCounter().then(
              (value) => AwesomeNotifications().setGlobalBadgeCounter(value - 1),
            );
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PlantStatsPage(),
        ),
        (route) => route.isFirst,
      );
    });
  }

  @override
  void dispose() {
    AwesomeNotifications().actionSink.close();
    AwesomeNotifications().createdSink.close();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final DateTime alcsChangedAt = DateTime.now().toUtc();

    switch (state) {
      case AppLifecycleState.inactive:
        print('App went to the foreground inactive state at $alcsChangedAt');
        break;

      case AppLifecycleState.paused:
        print('App went to background at $alcsChangedAt');
        Future<int>.value(1).then((int value) async {
          await Future.delayed(const Duration(seconds: 1)); // this is the most important to reproduce this problem
          // Above Future delay is a web API call, for example, to get upcoming appointments
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: createUniqueId(),
              channelKey: 'scheduled_channel',
              title: '${Emojis.wheater_droplet} Add some water to your plant!',
              body: 'Water your plant regularly to keep it healthy.',
              notificationLayout: NotificationLayout.Default,
            ),
            actionButtons: [
              NotificationActionButton(
                key: 'MARK_DONE',
                label: 'Mark Done',
              ),
            ],
            schedule: NotificationCalendar.fromDate(date: DateTime.now().add(Duration(seconds: 5))),
          );
        });
        break;

      case AppLifecycleState.resumed:
        print('App resumed from background at $alcsChangedAt');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: AppBarTitle(),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlantStatsPage(),
                ),
              );
            },
            icon: Icon(
              Icons.insert_chart_outlined_rounded,
              size: 30,
            ),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PlantImage(),
            SizedBox(
              height: 25,
            ),
            HomePageButtons(
              onPressedOne: createPlantFoodNotification,
              onPressedTwo: () async {
                NotificationWeekAndTime? pickedSchedule = await pickSchedule(context);

                if (pickedSchedule != null) {
                  createWaterReminderNotification(pickedSchedule);
                }
              },
              onPressedThree: cancelScheduledNotifications,
            ),
          ],
        ),
      ),
    );
  }
}
