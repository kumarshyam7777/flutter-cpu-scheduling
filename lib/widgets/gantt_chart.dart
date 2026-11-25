import 'package:flutter/material.dart';
import '../models.dart';

class GanttChart extends StatelessWidget {
  final List<GanttSegment> segments;

  const GanttChart({Key? key, required this.segments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();
    final total = segments.last.end;
    const scale = 42.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 96,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ...segments.map((segment) {
              final width = segment.duration * scale;
              final color = segment.type == 'idle' ? Colors.grey.shade700 : segment.color;
              return Container(
                width: width,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 64,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(segment.pid,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('${segment.start}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(width: 16),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('$total', style: const TextStyle(color: Colors.white70)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
