import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:postgres/postgres.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
final FlutterLocalNotificationsPlugin notificationsPlugin =
FlutterLocalNotificationsPlugin();

class NotifyService {
  Future<void> initNotification() async {
    AndroidInitializationSettings initializationSettingsAndroid =
    const AndroidInitializationSettings('flutter_logo');

    var initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payload) async {});

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await notificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {});
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
        android: AndroidNotificationDetails('channelId', 'channelName',
            importance: Importance.max),
        iOS: DarwinNotificationDetails());
  }

  Future showNotification(
      {int id = 0, String? title, String? body, String? payLoad}) async {
    await initNotification();
    print("Notification triggered");
    return notificationsPlugin.show(
        id, title, body, await notificationDetails());
  }
}
Future<void> checkForNewTasks() async {
  print("uslo");
  final connection = PostgreSQLConnection(
    '${dotenv.env['DB_HOST']}',
    int.parse('${dotenv.env['DB_PORT']}'),
    '${dotenv.env['DB_DATABASE']}',
    username: '${dotenv.env['DB_USER']}',
    password: '${dotenv.env['DB_PASSWORD']}',
  );

  await connection.open();

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final int? storedTaskCount = prefs.getInt('storedTaskCount') ?? 0;
  final results = await connection.query('SELECT * FROM tasks');
  final rows=results.map((row) {
    return {
      'id': row[0],
      'startTime': row[3],
      'endTime': row[4],
      'activity': row[1],
      'date': row[2],
      'location': row[5],
      'priority': row[6],
      'progress': row[7],
      'status': row[8],
      'userId': row[9],
      'parentId': row[10]
    };
  });
  final userId = prefs.getString('userid');final todayTasks = rows.where((task) {

    return isSameDate(DateTime.now(), task['date']) && userId==task['userId'].toString();
  }).toList();
  final int todayTaskCount = todayTasks.length;
  if (todayTaskCount != storedTaskCount) {
    await NotifyService().showNotification( title:'MyTaskBuddy', body: 'Your have a new task');
    await prefs.setInt('storedTaskCount', todayTaskCount);
  }

  await connection.close();
}

bool isSameDate(DateTime date1, DateTime date2) {
  return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
}