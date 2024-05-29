import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:postgres/postgres.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/timezone.dart' as tz;

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await dotenv.load(fileName: 'resource.env');

    var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = DarwinInitializationSettings();
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    await checkForNewTasks();
    await checkForExpiringTasks();

    return Future.value(true);
  });
}

Future<void> checkForNewTasks() async {
  final connection = PostgreSQLConnection(
    '${dotenv.env['DB_HOST']}',
    int.parse('${dotenv.env['DB_PORT']}'),
    '${dotenv.env['DB_DATABASE']}',
    username: '${dotenv.env['DB_USER']}',
    password: '${dotenv.env['DB_PASSWORD']}',
  );

  await connection.open();

  final results = await connection.query('SELECT * FROM tasks WHERE created_at > NOW() - INTERVAL \'1 MINUTE\'');

  for (var row in results) {
    await _showNotification('New Task Added', 'Task: ${row[1]}');
  }

  await connection.close();
}

Future<void> checkForExpiringTasks() async {
  final connection = PostgreSQLConnection(
    '${dotenv.env['DB_HOST']}',
    int.parse('${dotenv.env['DB_PORT']}'),
    '${dotenv.env['DB_DATABASE']}',
    username: '${dotenv.env['DB_USER']}',
    password: '${dotenv.env['DB_PASSWORD']}',
  );

  await connection.open();

  final results = await connection.query('SELECT * FROM tasks WHERE due_date < NOW() + INTERVAL \'15 MINUTES\' AND due_date > NOW()');

  for (var row in results) {
    var taskDueDate = row[2] as DateTime;
    var notificationTime = taskDueDate.subtract(Duration(minutes: 15));
    await _scheduleNotification('Task Expiring Soon', 'Task: ${row[1]}', notificationTime);
  }

  await connection.close();
}

Future<void> _showNotification(String title, String body) async {
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id', 'your_channel_name',
      importance: Importance.max, priority: Priority.high, showWhen: false);
  var iOSPlatformChannelSpecifics = DarwinNotificationDetails();
  var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
      0, title, body, platformChannelSpecifics, payload: 'item x');
}

Future<void> _scheduleNotification(String title, String body, DateTime scheduledTime) async {
  var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'MyTaskBuddy', 'Your have a new task',
      importance: Importance.max, priority: Priority.high, showWhen: true);
  var iOSPlatformChannelSpecifics = DarwinNotificationDetails();
  var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);

  tz.TZDateTime scheduledNotificationDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

  await flutterLocalNotificationsPlugin.zonedSchedule(
      0, title, body, scheduledNotificationDateTime, platformChannelSpecifics,
      androidAllowWhileIdle: true, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
}

