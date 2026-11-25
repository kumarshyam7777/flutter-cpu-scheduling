import 'package:flutter/material.dart';
import 'models.dart';
import 'scheduler.dart';
import 'widgets/input_field.dart';
import 'widgets/panel.dart';
import 'widgets/process_table.dart';
import 'widgets/gantt_chart.dart';

void main() => runApp(const CPUSchedulerApp());

class CPUSchedulerApp extends StatelessWidget {
  const CPUSchedulerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0B1220),
          textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto'),
        ),
        home: const _SchedulerHome(),
      );
}

class _SchedulerHome extends StatefulWidget {
  const _SchedulerHome({Key? key}) : super(key: key);

  @override
  _SchedulerHomeState createState() => _SchedulerHomeState();
}

class _SchedulerHomeState extends State<_SchedulerHome> {
  final pidCtrl = TextEditingController();
  final arrivalCtrl = TextEditingController();
  final burstCtrl = TextEditingController();
  final priorityCtrl = TextEditingController();
  final quantumCtrl = TextEditingController(text: '2');
  String algorithm = 'fcfs';
  List<Process> processes = [];
  List<Process>? stats;
  List<GanttSegment> timeline = [];

  bool get _isPriorityAlgo =>
      algorithm == 'priority' || algorithm == 'priority_p';

  void addProcess() {
    final pid = pidCtrl.text.trim();
    final arrival = int.tryParse(arrivalCtrl.text) ?? -1;
    final burst = int.tryParse(burstCtrl.text) ?? -1;
    final priority = int.tryParse(priorityCtrl.text) ?? 0;

    if (pid.isEmpty || arrival < 0 || burst <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill valid fields')),
      );
      return;
    }

    if (_isPriorityAlgo && priorityCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a priority value')),
      );
      return;
    }

    final color = colorPalette[processes.length % colorPalette.length];
    setState(() {
      processes.add(Process(
        pid: pid,
        arrival: arrival,
        burst: burst,
        color: color,
        priority: priority,
      ));
      pidCtrl.clear();
      arrivalCtrl.clear();
      burstCtrl.clear();
      priorityCtrl.clear();
      stats = null;
      timeline = [];
    });
  }

  void resetAll() {
    setState(() {
      processes.clear();
      stats = null;
      timeline = [];
    });
  }

  void calculate() {
    final quantum = int.tryParse(quantumCtrl.text) ?? 2;
    final result = schedule(processes, algorithm, quantum: quantum);
    setState(() {
      stats = result.stats;
      timeline = result.timeline;
    });
  }

  @override
  void dispose() {
    pidCtrl.dispose();
    arrivalCtrl.dispose();
    burstCtrl.dispose();
    priorityCtrl.dispose();
    quantumCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CPU Scheduling Simulator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Panel(
                  title: 'Add Process',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      InputField(label: 'Process ID', controller: pidCtrl),
                      InputField(
                        label: 'Arrival Time',
                        controller: arrivalCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      InputField(
                        label: 'Burst Time',
                        controller: burstCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      if (_isPriorityAlgo)
                        InputField(
                          label: 'Priority',
                          controller: priorityCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ElevatedButton(
                          onPressed: addProcess, child: const Text('+ Add')),
                      ElevatedButton(
                        onPressed: resetAll,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade800),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
                Panel(
                  title: 'Algorithm',
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: algorithm,
                        dropdownColor: Colors.grey.shade900,
                        items: {
                          'fcfs': 'FCFS',
                          'sjf': 'SJF',
                          'srtf': 'SRTF',
                          'rr': 'RR',
                          'priority': 'PRIORITY (NP)',
                          'priority_p': 'PRIORITY (P)',
                        }
                            .entries
                            .map((entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            algorithm = value!;
                            stats = null;
                            timeline = [];
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      if (algorithm == 'rr')
                        SizedBox(
                          width: 120,
                          child: InputField(
                            label: 'Quantum',
                            controller: quantumCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                          onPressed: calculate,
                          child: const Text('▶ Calculate')),
                    ],
                  ),
                ),
                Panel(
                    title: 'Process Table',
                    child: ProcessTable(processes: processes, stats: stats)),
                if (stats != null)
                  Panel(
                    title: 'Summary',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Avg Turnaround',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 6),
                            Text(
                                _avg(stats!, (p) => p.tat ?? 0)
                                    .toStringAsFixed(2),
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Avg Waiting',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 6),
                            Text(
                                _avg(stats!, (p) => p.wt ?? 0)
                                    .toStringAsFixed(2),
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (timeline.isNotEmpty)
                  Panel(
                      title: 'Gantt Chart',
                      child: GanttChart(segments: timeline)),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _avg(List<Process> list, int Function(Process) selector) =>
      list.isEmpty
          ? 0
          : list.map(selector).reduce((a, b) => a + b) / list.length;
}
