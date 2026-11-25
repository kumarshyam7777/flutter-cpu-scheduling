import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cpu_scheduler/main.dart';

void main() {
  testWidgets('App loads and shows title', (tester) async {
    await tester.pumpWidget(const CPUSchedulerApp());
    expect(find.text('CPU Scheduling Simulator'), findsOneWidget);
  });
}
