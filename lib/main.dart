import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hyprland_ipc/hyprland_ipc.dart';

void main() async {
  runApp(const ProviderScope(child: MyApp()));
}

final hyprlandIPCProvider = FutureProvider((ref) => HyprlandIPC.fromInstance());
final lastWorkspaceNameProvider = StateProvider<String>((ref) => "");
final isEmptyProvider = StreamProvider<bool>((ref) async* {
  final hyprlandIPC = ref.watch(hyprlandIPCProvider).valueOrNull;
  String lastWorkspaceName = ref.read(lastWorkspaceNameProvider);

  if (hyprlandIPC != null) {
    await for (final event in hyprlandIPC.eventsStream) {
      if (event is WorkspaceEvent) {
        ref.read(lastWorkspaceNameProvider.notifier).state =
            event.workspaceName;
        lastWorkspaceName = event.workspaceName;
      } else {
        lastWorkspaceName = ref.read(lastWorkspaceNameProvider);
      }
      if (event is WorkspaceEvent ||
          event is MoveWindowEvent ||
          event is CloseWindowEvent ||
          event is OpenWindowEvent) {
        final clients = await hyprlandIPC.getClients();
        if (clients
            .any((client) => client.workspaceName == lastWorkspaceName)) {
          yield false;
          continue;
        }
        yield true;
      }
    }
  }
});
final timeProvider = StreamProvider((ref) async* {
  await for (final _ in Stream.periodic(const Duration(milliseconds: 500))) {
    yield DateTime.now();
  }
});

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(context, ref) {
    final isEmpty = ref.watch(isEmptyProvider).valueOrNull ?? false;
    final time = ref.watch(timeProvider).valueOrNull ?? DateTime.now();

    final secondsTurns = useState<double>(0);
    final sideOpen = useState(false);

    useEffect(() {
      double newTurn = secondsTurns.value.floor() + time.second / 60;
      if (newTurn < secondsTurns.value) {
        newTurn++;
      }
      secondsTurns.value = newTurn;
      return null;
    }, [time]);

    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: MouseRegion(
          onHover: (e) {
            final rightTriggerSpace = sideOpen.value ? 800 : 200;
            sideOpen.value = e.position.dx > 1920 - rightTriggerSpace;
          },
          child: Stack(
            children: [
              Positioned(
                child: Image.asset("assets/clock/background.png"),
              ),
              // if (isEmpty)
              Positioned(
                left: 579,
                top: 110,
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: secondsTurns.value,
                  alignment: Alignment.bottomCenter,
                  curve: Curves.bounceOut,
                  child: Image.asset("assets/clock/seconds.png"),
                ),
              ),
              // if (isEmpty)
              Positioned(
                left: 528,
                top: 235,
                child: Transform.rotate(
                  angle: (time.minute / 60 +
                          time.second / 60 / 60 +
                          time.millisecond / 60 / 60 / 1000) *
                      2 *
                      pi,
                  alignment: Alignment.bottomCenter,
                  child: Image.asset("assets/clock/minutes.png"),
                ),
              ),
              // if (isEmpty)
              Positioned(
                left: 552,
                top: 262,
                child: Transform.rotate(
                  angle: (time.hour % 12 / 12 +
                          time.minute / 60 / 12 +
                          time.second / 60 / 60 / 12) *
                      2 *
                      pi,
                  alignment: Alignment.bottomCenter,
                  child: Image.asset("assets/clock/hours.png"),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                top: -25,
                left: 1920 - 790 * (sideOpen.value ? 1 : 0),
                child: Stack(
                  children: [
                    Image.asset("assets/other/arrow.png"),
                    Container(
                      width: 890,
                      height: 1180,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${time.hour}:${time.minute.toString().padLeft(2, "0")}:${time.second.toString().padLeft(2, "0")}",
                              style: const TextStyle(
                                inherit: true,
                                fontSize: 100.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: "Arial",
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${time.day}/${time.month}/${time.year}",
                              style: const TextStyle(
                                inherit: true,
                                fontSize: 70.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: "Arial",
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
