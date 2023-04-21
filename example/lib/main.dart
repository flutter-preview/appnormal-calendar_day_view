import 'dart:math';

import 'package:flutter/material.dart';
import 'package:calendar_day_view/calendar_day_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<DayItemWidget> children = [
    item(1, '5:30', '8:00', Colors.red),
    item(5, '10:00', '13:00', Colors.orange),
    item(2, '5:00', '9:00', Colors.green),
    item(3, '7:00', '11:00', Colors.amber),
    item(4, '8:00', '10:00', Colors.blue),
    item(6, '9:00', '11:00', Colors.orange.shade700),
  ];

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Container(
          color: Colors.white,
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: DayViewWidget(
                    height: 24 * 40,
                    date: DateTime.now(),
                    children: children,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: Colors.black.withOpacity(.5),
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        children.add(randomItem());
                      });
                    },
                    style: const ButtonStyle(
                      padding: MaterialStatePropertyAll(EdgeInsets.all(20)),
                    ),
                    child: const Text('Add random item'),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  DayItemWidget randomItem() {
    final now = DateTime.now().midnight;
    final start = now.add(Duration(hours: Random().nextInt(20), minutes: Random().nextInt(11) * 5));
    final end = start.add(Duration(hours: 1 + Random().nextInt(2)));
    return item(
      children.length,
      '${start.hour}:${start.minute}',
      '${end.hour}:${end.minute}',
      Colors.primaries[start.hour % Colors.primaries.length],
    );
  }
}

DayItemWidget item(
  int i,
  String start,
  String end,
  Color color,
) =>
    DayItemWidget(
      start: start.toDateTime(),
      end: end.toDateTime(),
      child: Container(
        margin: const EdgeInsets.all(1),
        child: Material(
          borderRadius: BorderRadius.circular(4),
          color: color,
          child: InkWell(
            onTap: () => debugPrint('Tapped $i'),
            borderRadius: BorderRadius.circular(4),
            splashColor: Colors.black.withOpacity(0.3),
            highlightColor: Colors.black.withOpacity(0.3),
            hoverColor: Colors.black.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                'Item $i',
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
        ),
      ),
    );

extension DateTimeEx on DateTime {
  DateTime get midnight => subtract(Duration(
        hours: hour,
        minutes: minute,
        seconds: second,
        milliseconds: millisecond,
        microseconds: microsecond,
      ));
}

extension StringEx on String {
  DateTime toDateTime() {
    final now = DateTime.now();
    final time = split(':');
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(time[0]),
      int.parse(time[1]),
    );
  }
}
