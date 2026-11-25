import 'package:flutter/material.dart';
import 'models.dart';

const colorPalette = [
  Color(0xFFE74C3C),
  Color(0xFF3498DB),
  Color(0xFF2ECC71),
  Color(0xFFF39C12),
  Color(0xFF9B59B6),
  Color(0xFF1ABC9C),
  Color(0xFFE67E22),
  Color(0xFFE91E63),
  Color(0xFF00BCD4),
  Color(0xFF8BC34A),
];

const idleColor = Color(0xFF475569);

class SchedulerResult {
  final List<Process> stats;
  final List<GanttSegment> timeline;

  SchedulerResult({required this.stats, required this.timeline});
}

Process _complete(Process process, int completion) =>
    process.completedAt(completion);

SchedulerResult runFCFS(List<Process> processes) {
  final sorted = [...processes]..sort((a, b) => a.arrival.compareTo(b.arrival));
  int time = 0;
  final completed = <Process>[];
  final timeline = <GanttSegment>[];

  for (var process in sorted) {
    if (time < process.arrival) {
      timeline.add(GanttSegment(
        type: 'idle',
        pid: 'Idle',
        color: idleColor,
        start: time,
        end: process.arrival,
      ));
      time = process.arrival;
    }
    timeline.add(GanttSegment(
      type: 'process',
      pid: process.pid,
      color: process.color,
      start: time,
      end: time + process.burst,
    ));
    time += process.burst;
    completed.add(_complete(process, time));
  }

  return SchedulerResult(stats: completed, timeline: timeline);
}

SchedulerResult runSJF(List<Process> processes) {
  final sorted = [...processes]..sort((a, b) => a.arrival.compareTo(b.arrival));
  int time = 0;
  final remaining = sorted.map((process) => process.copyWith()).toList();
  final completed = <Process>[];
  final timeline = <GanttSegment>[];

  while (remaining.isNotEmpty) {
    final available =
        remaining.where((process) => process.arrival <= time).toList();
    if (available.isEmpty) {
      final next = remaining
          .map((process) => process.arrival)
          .reduce((a, b) => a < b ? a : b);
      timeline.add(GanttSegment(
          type: 'idle', pid: 'Idle', color: idleColor, start: time, end: next));
      time = next;
      continue;
    }
    available.sort((a, b) => a.burst.compareTo(b.burst));
    final selected = available.first;
    timeline.add(GanttSegment(
      type: 'process',
      pid: selected.pid,
      color: selected.color,
      start: time,
      end: time + selected.burst,
    ));
    time += selected.burst;
    completed.add(_complete(selected, time));
    remaining.removeWhere((process) => process.pid == selected.pid);
  }

  return SchedulerResult(stats: completed, timeline: timeline);
}

SchedulerResult runSRTF(List<Process> processes) {
  final remaining = processes.map((process) => process.copyWith()).toList();
  for (var process in remaining) {
    process.rem = process.burst;
  }
  final completed = <Process>[];
  final timeline = <GanttSegment>[];
  int time = 0;
  String? lastPid;

  while (remaining.isNotEmpty) {
    final available =
        remaining.where((process) => process.arrival <= time).toList();
    if (available.isEmpty) {
      final next = remaining
          .map((process) => process.arrival)
          .reduce((a, b) => a < b ? a : b);
      timeline.add(GanttSegment(
          type: 'idle', pid: 'Idle', color: idleColor, start: time, end: next));
      time = next;
      continue;
    }
    available.sort((a, b) => a.rem.compareTo(b.rem));
    final selected = available.first;
    final start = time;
    selected.rem -= 1;
    time += 1;
    final end = time;
    if (lastPid == selected.pid &&
        timeline.isNotEmpty &&
        timeline.last.type == 'process') {
      timeline.last.end = end;
    } else {
      timeline.add(GanttSegment(
          type: 'process',
          pid: selected.pid,
          color: selected.color,
          start: start,
          end: end));
    }
    lastPid = selected.pid;
    if (selected.rem == 0) {
      completed.add(_complete(selected, time));
      remaining.removeWhere((process) => process.pid == selected.pid);
    }
  }

  return SchedulerResult(stats: completed, timeline: timeline);
}

SchedulerResult runRR(List<Process> processes, int quantum) {
  final sorted = [...processes]..sort((a, b) => a.arrival.compareTo(b.arrival));
  final remaining = sorted.map((process) => process.copyWith()).toList();
  for (var process in remaining) {
    process.rem = process.burst;
  }
  final queue = <Process>[];
  final completed = <Process>[];
  final timeline = <GanttSegment>[];
  int time = 0;
  int idx = 0;

  while (remaining.isNotEmpty || queue.isNotEmpty) {
    while (idx < remaining.length && remaining[idx].arrival <= time) {
      queue.add(remaining[idx++]);
    }
    if (queue.isEmpty && idx < remaining.length) {
      final nextA = remaining[idx].arrival;
      if (time < nextA) {
        timeline.add(GanttSegment(
            type: 'idle',
            pid: 'Idle',
            color: idleColor,
            start: time,
            end: nextA));
        time = nextA;
      }
      queue.add(remaining[idx++]);
    }
    final current = queue.removeAt(0);
    final exec = current.rem < quantum ? current.rem : quantum;
    final start = time;
    time += exec;
    final end = time;
    if (timeline.isNotEmpty &&
        timeline.last.type == 'process' &&
        timeline.last.pid == current.pid) {
      timeline.last.end = end;
    } else {
      timeline.add(GanttSegment(
          type: 'process',
          pid: current.pid,
          color: current.color,
          start: start,
          end: end));
    }
    current.rem -= exec;
    while (idx < remaining.length && remaining[idx].arrival <= time) {
      queue.add(remaining[idx++]);
    }
    if (current.rem == 0) {
      completed.add(_complete(current, time));
      remaining.removeWhere((process) => process.pid == current.pid);
    } else {
      queue.add(current);
    }
  }

  return SchedulerResult(stats: completed, timeline: timeline);
}

SchedulerResult runPriority(List<Process> processes) {
  final sorted = [...processes]..sort((a, b) => a.arrival.compareTo(b.arrival));
  int time = 0;
  final remaining = sorted.map((process) => process.copyWith()).toList();
  final completed = <Process>[];
  final timeline = <GanttSegment>[];

  while (remaining.isNotEmpty) {
    final available =
        remaining.where((process) => process.arrival <= time).toList();
    if (available.isEmpty) {
      final next = remaining
          .map((process) => process.arrival)
          .reduce((a, b) => a < b ? a : b);
      timeline.add(GanttSegment(
          type: 'idle', pid: 'Idle', color: idleColor, start: time, end: next));
      time = next;
      continue;
    }
    available.sort((a, b) {
      final cmp = a.priority.compareTo(b.priority);
      return cmp != 0 ? cmp : a.arrival.compareTo(b.arrival);
    });
    final selected = available.first;
    timeline.add(GanttSegment(
        type: 'process',
        pid: selected.pid,
        color: selected.color,
        start: time,
        end: time + selected.burst));
    time += selected.burst;
    completed.add(_complete(selected, time));
    remaining.removeWhere((process) => process.pid == selected.pid);
  }

  return SchedulerResult(stats: completed, timeline: timeline);
}

SchedulerResult runPreemptivePriority(List<Process> processes) {
  final remaining = processes.map((process) => process.copyWith()).toList();
  for (var process in remaining) {
    process.rem = process.burst;
  }
  final completed = <Process>[];
  final timeline = <GanttSegment>[];
  int time = 0;
  String? lastPid;

  while (remaining.isNotEmpty) {
    final available =
        remaining.where((process) => process.arrival <= time).toList();
    if (available.isEmpty) {
      final next = remaining
          .map((process) => process.arrival)
          .reduce((a, b) => a < b ? a : b);
      timeline.add(GanttSegment(
          type: 'idle', pid: 'Idle', color: idleColor, start: time, end: next));
      time = next;
      continue;
    }
    available.sort((a, b) {
      final cmp = a.priority.compareTo(b.priority);
      return cmp != 0 ? cmp : a.rem.compareTo(b.rem);
    });
    final selected = available.first;
    final start = time;
    selected.rem -= 1;
    time += 1;
    final end = time;
    if (lastPid == selected.pid &&
        timeline.isNotEmpty &&
        timeline.last.type == 'process') {
      timeline.last.end = end;
    } else {
      timeline.add(GanttSegment(
          type: 'process',
          pid: selected.pid,
          color: selected.color,
          start: start,
          end: end));
    }
    lastPid = selected.pid;
    if (selected.rem == 0) {
      completed.add(_complete(selected, time));
      remaining.removeWhere((process) => process.pid == selected.pid);
    }
  }

  return SchedulerResult(stats: completed, timeline: timeline);
}

SchedulerResult schedule(
  List<Process> processes,
  String algorithm, {
  int quantum = 2,
}) {
  switch (algorithm) {
    case 'fcfs':
      return runFCFS(processes);
    case 'sjf':
      return runSJF(processes);
    case 'srtf':
      return runSRTF(processes);
    case 'rr':
      return runRR(processes, quantum);
    case 'priority':
      return runPriority(processes);
    case 'priority_p':
      return runPreemptivePriority(processes);
    default:
      return runFCFS(processes);
  }
}
