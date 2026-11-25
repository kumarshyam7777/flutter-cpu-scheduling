import 'package:flutter/material.dart';

class Process {
  final String pid;
  final int arrival;
  final int burst;
  final Color color;
  final int priority;
  int rem;
  int? completion;
  int? tat;
  int? wt;

  Process({
    required this.pid,
    required this.arrival,
    required this.burst,
    required this.color,
    this.priority = 0,
  }) : rem = burst;

  Process copyWith({
    int? rem,
    int? completion,
    int? tat,
    int? wt,
    Color? color,
  }) {
    final p = Process(
      pid: pid,
      arrival: arrival,
      burst: burst,
      color: color ?? this.color,
      priority: priority,
    );
    p.rem = rem ?? this.rem;
    p.completion = completion ?? this.completion;
    p.tat = tat ?? this.tat;
    p.wt = wt ?? this.wt;
    return p;
  }

  Process completedAt(int completion) => copyWith(
        completion: completion,
        tat: completion - arrival,
        wt: completion - arrival - burst,
      );
}

class GanttSegment {
  final String type;
  final String pid;
  final Color color;
  final int start;
  int end;

  GanttSegment({
    required this.type,
    required this.pid,
    required this.color,
    required this.start,
    required this.end,
  });

  int get duration => end - start;
}
