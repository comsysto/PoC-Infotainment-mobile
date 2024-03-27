import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infotainment_mobile_app/core/di/di.dart';
import 'package:infotainment_mobile_app/core/style/style_extensions.dart';
import 'package:infotainment_mobile_app/features/basic_car_controls/presentation/widget/blinker_controls.dart';
import 'package:infotainment_mobile_app/features/basic_car_controls/presentation/widget/telemetry_card.dart';
import 'package:infotainment_mobile_app/features/basic_car_controls/presentation/widget/throttle_controls.dart';
import 'package:sliver_tools/sliver_tools.dart';

class BasicControlsScreen extends HookConsumerWidget {
  const BasicControlsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryData = ref.watch(telemetryProvider);
    final batteryLevel = telemetryData.valueOrNull?.batteryLevel ?? 0;
    final batteryIcon = useMemoized(
      () => switch (batteryLevel) {
        > 0 && <= 10 => const Icon(Icons.battery_1_bar_rounded, size: 40, color: Colors.red),
        > 10 && <= 20 => const Icon(Icons.battery_2_bar_rounded, size: 40, color: Colors.red),
        > 20 && <= 30 => const Icon(Icons.battery_3_bar_rounded, size: 40, color: Colors.orange),
        > 30 && <= 50 => const Icon(Icons.battery_4_bar_rounded, size: 40, color: Colors.yellow),
        > 50 && <= 85 => const Icon(Icons.battery_5_bar_rounded, size: 40, color: Colors.green),
        > 85 && < 100 => const Icon(Icons.battery_6_bar_rounded, size: 40, color: Colors.green),
        == 100 => const Icon(Icons.battery_full_rounded, size: 40, color: Colors.green),
        _ => const Icon(Icons.battery_0_bar_rounded, size: 40, color: Colors.red),
      },
      [telemetryData],
    );

    useEffect(
      () {
        final timer = Timer.periodic(
          const Duration(seconds: 5),
          (_) => ref.read(telemetryControllerProvider).sendEmptyRequest(),
        );
        return () => timer.cancel();
      },
      [],
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: Row(
          children: [
            Image.asset(
              'assets/images/mercedes_logo.png',
              height: 40,
            ),
            const SizedBox(width: 24),
            Text(
              'E350d 4Matic',
              style: context.textTitle,
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.colorGradientBegin, context.colorGradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: MultiSliver(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 60, bottom: 16),
                      child: Image.asset(
                        'assets/images/mercedes_e350d.png',
                        height: 140,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.rotate(
                              angle: 1 / 2 * math.pi,
                              child: batteryIcon,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${batteryLevel.round().toString()}%',
                              style: context.textBody,
                            ),
                          ],
                        ),
                        const SizedBox(width: 28),
                        SvgPicture.asset(
                          'assets/icons/check_engine_light.svg',
                          height: 22,
                          colorFilter: const ColorFilter.mode(
                            Colors.red,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                    telemetryData.when(
                      data: (value) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 16, bottom: 8),
                              child: TelemetryCard(
                                title: 'Current speed',
                                value: value.speed.toString(),
                                type: TelemetryType.speed,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TelemetryCard(
                                title: 'Current RPM',
                                value: value.rpm.toString(),
                                type: TelemetryType.rpm,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () {
                        return const Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 16, bottom: 8),
                              child: TelemetryCard(
                                title: 'Current speed',
                                value: '0',
                                type: TelemetryType.speed,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: TelemetryCard(
                                title: 'Current RPM',
                                value: '0',
                                type: TelemetryType.rpm,
                              ),
                            ),
                          ],
                        );
                      },
                      error: (error, stackTrace) {
                        log('Error: $error', stackTrace: stackTrace);
                        return const SizedBox.shrink();
                      },
                    ),
                    ref.watch(commandChannelProvider).when(
                      data: (value) {
                        log('Command channel value: $value');
                        return const SizedBox.shrink();
                      },
                      error: (error, stackTrace) {
                        log('Error: $error', stackTrace: stackTrace);
                        return const SizedBox.shrink();
                      },
                      loading: () {
                        return const SizedBox.shrink();
                      },
                    ),
                    const BlinkerControls(),
                    const SizedBox(height: 16),
                    const ThrottleControls(),
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
