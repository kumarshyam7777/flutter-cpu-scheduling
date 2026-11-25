import 'package:flutter/material.dart';
import '../models.dart';

class ProcessTable extends StatelessWidget {
  final List<Process> processes;
  final List<Process>? stats;

  const ProcessTable({Key? key, required this.processes, this.stats})
      : super(key: key);

  Widget _cell(String text, {bool bold = false}) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(text,
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
      );

  @override
  Widget build(BuildContext context) {
    final rows = (stats ?? processes).map((process) {
      return TableRow(children: [
        _cell(process.pid),
        _cell(process.arrival.toString()),
        _cell(process.burst.toString()),
        _cell(process.priority.toString()),
        _cell(stats != null ? (process.completion?.toString() ?? '—') : '—'),
        _cell(stats != null ? (process.tat?.toString() ?? '—') : '—'),
        _cell(stats != null ? (process.wt?.toString() ?? '—') : '—'),
      ]);
    }).toList();

    if (rows.isEmpty) {
      return const Text('No processes added yet.',
          style: TextStyle(color: Colors.grey));
    }

    return Table(
      columnWidths: const {0: FixedColumnWidth(120)},
      border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade800)),
      children: [
        TableRow(children: [
          _cell('Process', bold: true),
          _cell('Arrival', bold: true),
          _cell('Burst', bold: true),
          _cell('Priority', bold: true),
          _cell('Completion', bold: true),
          _cell('TAT', bold: true),
          _cell('WT', bold: true),
        ]),
        ...rows,
      ],
    );
  }
}
