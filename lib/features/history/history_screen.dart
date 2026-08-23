import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/history_record.dart';
import '../../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() =>
      _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService history =
      HistoryService.instance;

  String? selectedDevice;
  _HistoryRange selectedRange =
      _HistoryRange.twentyFourHours;

  @override
  void initState() {
    super.initState();
    history.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<HistoryRecord>>(
      valueListenable: history.records,
      builder: (context, records, child) {
        final deviceIds = records
            .map((record) => record.deviceId)
            .toSet()
            .toList();

        final filteredByDevice =
            selectedDevice == null
                ? records
                : records
                    .where(
                      (record) =>
                          record.deviceId ==
                          selectedDevice,
                    )
                    .toList();

        final rangeStart = DateTime.now().subtract(
          selectedRange.duration,
        );

        final ranged = filteredByDevice
            .where(
              (record) =>
                  record.timestamp.isAfter(
                rangeStart,
              ),
            )
            .toList()
          ..sort(
            (a, b) => a.timestamp.compareTo(
              b.timestamp,
            ),
          );

        return Scaffold(
          body: Column(
            children: [
              _buildHeader(
                records,
                deviceIds,
              ),
              Expanded(
                child: records.isEmpty
                    ? const _EmptyHistory()
                    : ListView(
                        padding:
                            const EdgeInsets.all(12),
                        children: [
                          _RangeSelector(
                            selectedRange:
                                selectedRange,
                            onChanged: (range) {
                              setState(() {
                                selectedRange =
                                    range;
                              });
                            },
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          _HistoryGraphCard(
                            title:
                                'Battery Voltage',
                            unit: 'V',
                            records: ranged,
                            valueSelector:
                                (record) =>
                                    record
                                        .batteryVoltage,
                            decimals: 2,
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          _HistoryGraphCard(
                            title:
                                'Battery Current',
                            unit: 'A',
                            records: ranged,
                            valueSelector:
                                (record) =>
                                    record
                                        .batteryCurrent,
                            decimals: 2,
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          _HistoryGraphCard(
                            title: 'State of Charge',
                            unit: '%',
                            records: ranged,
                            valueSelector:
                                (record) =>
                                    record
                                        .stateOfCharge,
                            minYOverride: 0,
                            maxYOverride: 100,
                            decimals: 1,
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          _HistoryGraphCard(
                            title: 'Solar Power',
                            unit: 'W',
                            records: ranged,
                            valueSelector:
                                (record) =>
                                    record.pvPower,
                            minYOverride: 0,
                            decimals: 0,
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          const Text(
                            'Stored samples',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          if (filteredByDevice.isEmpty)
                            const Card(
                              child: Padding(
                                padding:
                                    EdgeInsets.all(
                                  18,
                                ),
                                child: Text(
                                  'No samples for '
                                  'this device.',
                                ),
                              ),
                            )
                          else
                            ...filteredByDevice.map(
                              (record) =>
                                  _HistoryCard(
                                record: record,
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    List<HistoryRecord> records,
    List<String> deviceIds,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (records.isNotEmpty)
            DropdownButton<String?>(
              value: selectedDevice,
              hint: const Text(
                'All devices',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'All devices',
                  ),
                ),
                ...deviceIds.map(
                  (id) {
                    final record =
                        records.firstWhere(
                      (record) =>
                          record.deviceId == id,
                    );

                    return DropdownMenuItem<
                        String?>(
                      value: id,
                      child: Text(
                        record.deviceName.isEmpty
                            ? id
                            : record.deviceName,
                      ),
                    );
                  },
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedDevice = value;
                });
              },
            ),

          const SizedBox(
            width: 8,
          ),

          if (records.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              onPressed: _confirmClear,
              icon: const Icon(
                Icons.delete_outline,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmClear() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Clear history?',
          ),
          content: const Text(
            'All stored Victron history '
            'will be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'CANCEL',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'CLEAR',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await history.clear();

    if (!mounted) return;

    setState(() {
      selectedDevice = null;
    });
  }
}

class _RangeSelector extends StatelessWidget {
  final _HistoryRange selectedRange;
  final ValueChanged<_HistoryRange> onChanged;

  const _RangeSelector({
    required this.selectedRange,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_HistoryRange>(
      segments: const [
        ButtonSegment(
          value: _HistoryRange.oneHour,
          label: Text('1H'),
        ),
        ButtonSegment(
          value: _HistoryRange.sixHours,
          label: Text('6H'),
        ),
        ButtonSegment(
          value:
              _HistoryRange.twentyFourHours,
          label: Text('24H'),
        ),
        ButtonSegment(
          value: _HistoryRange.sevenDays,
          label: Text('7D'),
        ),
      ],
      selected: {
        selectedRange,
      },
      onSelectionChanged: (selection) {
        if (selection.isEmpty) {
          return;
        }

        onChanged(
          selection.first,
        );
      },
      showSelectedIcon: false,
    );
  }
}

class _HistoryGraphCard extends StatelessWidget {
  final String title;
  final String unit;

  final List<HistoryRecord> records;

  final double? Function(
    HistoryRecord record,
  ) valueSelector;

  final double? minYOverride;
  final double? maxYOverride;
  final int decimals;

  const _HistoryGraphCard({
    required this.title,
    required this.unit,
    required this.records,
    required this.valueSelector,
    this.minYOverride,
    this.maxYOverride,
    required this.decimals,
  });

  @override
  Widget build(BuildContext context) {
    final dataPoints =
        <_GraphPoint>[];

    for (final record in records) {
      final value =
          valueSelector(record);

      if (value == null) {
        continue;
      }

      dataPoints.add(
        _GraphPoint(
          time: record.timestamp,
          value: value,
        ),
      );
    }

    if (dataPoints.isEmpty) {
      return Card(
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              const Center(
                child: Text(
                  'No data in this range',
                  style: TextStyle(
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final start =
        dataPoints.first.time;

    final spots = dataPoints.map(
      (point) {
        final seconds =
            point.time
                .difference(start)
                .inSeconds
                .toDouble();

        return FlSpot(
          seconds,
          point.value,
        );
      },
    ).toList();

    final values =
        dataPoints
            .map(
              (point) =>
                  point.value,
            )
            .toList();

    double minY =
        values.reduce(
      (a, b) => a < b ? a : b,
    );

    double maxY =
        values.reduce(
      (a, b) => a > b ? a : b,
    );

    if (minYOverride != null) {
      minY = minYOverride!;
    }

    if (maxYOverride != null) {
      maxY = maxYOverride!;
    }

    if ((maxY - minY).abs() < 0.001) {
      minY -= 1;
      maxY += 1;
    }

    final padding =
        (maxY - minY) * 0.08;

    if (minYOverride == null) {
      minY -= padding;
    }

    if (maxYOverride == null) {
      maxY += padding;
    }

    final latest =
        dataPoints.last.value;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                Text(
                  '${latest.toStringAsFixed(decimals)} $unit',
                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  borderData:
                      FlBorderData(
                    show: false,
                  ),
                  gridData:
                      const FlGridData(
                    show: true,
                  ),
                  titlesData:
                      FlTitlesData(
                    topTitles:
                        const AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: false,
                      ),
                    ),
                    rightTitles:
                        const AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: false,
                      ),
                    ),
                    leftTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        getTitlesWidget:
                            (
                          value,
                          meta,
                        ) {
                          return Text(
                            value
                                .toStringAsFixed(
                              decimals > 1
                                  ? 1
                                  : decimals,
                            ),
                            style:
                                const TextStyle(
                              fontSize: 10,
                              color:
                                  Colors.white54,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval:
                            _bottomInterval(
                          spots,
                        ),
                        getTitlesWidget:
                            (
                          value,
                          meta,
                        ) {
                          final time =
                              start.add(
                            Duration(
                              seconds:
                                  value.round(),
                            ),
                          );

                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              top: 6,
                            ),
                            child: Text(
                              _timeLabel(
                                time,
                              ),
                              style:
                                  const TextStyle(
                                fontSize: 10,
                                color:
                                    Colors.white54,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData:
                      LineTouchData(
                    touchTooltipData:
                        LineTouchTooltipData(
                      getTooltipItems:
                          (spots) {
                        return spots.map(
                          (spot) {
                            final time =
                                start.add(
                              Duration(
                                seconds:
                                    spot.x
                                        .round(),
                              ),
                            );

                            return LineTooltipItem(
                              '${_dateTime(time)}\n'
                              '${spot.y.toStringAsFixed(decimals)} $unit',
                              const TextStyle(),
                            );
                          },
                        ).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      dotData:
                          FlDotData(
                        show:
                            spots.length <
                                30,
                      ),
                      barWidth: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _bottomInterval(
    List<FlSpot> spots,
  ) {
    if (spots.length < 2) {
      return 1;
    }

    final total =
        spots.last.x -
            spots.first.x;

    if (total <= 0) {
      return 1;
    }

    return total / 4;
  }

  static String _timeLabel(
    DateTime time,
  ) {
    String two(int value) =>
        value
            .toString()
            .padLeft(2, '0');

    return '${two(time.hour)}:'
        '${two(time.minute)}';
  }

  static String _dateTime(
    DateTime value,
  ) {
    final local =
        value.toLocal();

    String two(int value) =>
        value
            .toString()
            .padLeft(2, '0');

    return '${local.year}-'
        '${two(local.month)}-'
        '${two(local.day)} '
        '${two(local.hour)}:'
        '${two(local.minute)}';
  }
}

class _GraphPoint {
  final DateTime time;
  final double value;

  const _GraphPoint({
    required this.time,
    required this.value,
  });
}

class _HistoryCard extends StatelessWidget {
  final HistoryRecord record;

  const _HistoryCard({
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: ExpansionTile(
        leading: const Icon(
          Icons.timeline,
        ),
        title: Text(
          record.deviceName.isEmpty
              ? 'Victron device'
              : record.deviceName,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _dateTime(
            record.timestamp,
          ),
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        children: [
          if (record.batteryVoltage != null)
            _Row(
              label: 'Battery voltage',
              value:
                  '${record.batteryVoltage!.toStringAsFixed(2)} V',
            ),

          if (record.batteryCurrent != null)
            _Row(
              label: 'Battery current',
              value:
                  '${record.batteryCurrent!.toStringAsFixed(2)} A',
            ),

          if (record.batteryPower != null)
            _Row(
              label: 'Battery power',
              value:
                  '${record.batteryPower!.toStringAsFixed(0)} W',
            ),

          if (record.stateOfCharge != null)
            _Row(
              label: 'SOC',
              value:
                  '${record.stateOfCharge!.toStringAsFixed(1)} %',
            ),

          if (record.pvVoltage != null)
            _Row(
              label: 'PV voltage',
              value:
                  '${record.pvVoltage!.toStringAsFixed(2)} V',
            ),

          if (record.pvCurrent != null)
            _Row(
              label: 'PV current',
              value:
                  '${record.pvCurrent!.toStringAsFixed(2)} A',
            ),

          if (record.pvPower != null)
            _Row(
              label: 'PV power',
              value:
                  '${record.pvPower!.toStringAsFixed(0)} W',
            ),

          if (record.chargeCurrent != null)
            _Row(
              label: 'Charge current',
              value:
                  '${record.chargeCurrent!.toStringAsFixed(2)} A',
            ),

          if (record.chargeState != null)
            _Row(
              label: 'Charge state',
              value:
                  record.chargeState!,
            ),

          if (record.inputVoltage != null)
            _Row(
              label: 'Input voltage',
              value:
                  '${record.inputVoltage!.toStringAsFixed(2)} V',
            ),

          if (record.outputVoltage != null)
            _Row(
              label: 'Output voltage',
              value:
                  '${record.outputVoltage!.toStringAsFixed(2)} V',
            ),

          if (record.outputCurrent != null)
            _Row(
              label: 'Output current',
              value:
                  '${record.outputCurrent!.toStringAsFixed(2)} A',
            ),

          if (record.outputPower != null)
            _Row(
              label: 'Output power',
              value:
                  '${record.outputPower!.toStringAsFixed(0)} W',
            ),
        ],
      ),
    );
  }

  static String _dateTime(
    DateTime value,
  ) {
    final local =
        value.toLocal();

    String two(int value) =>
        value
            .toString()
            .padLeft(2, '0');

    return '${local.year}-'
        '${two(local.month)}-'
        '${two(local.day)}  '
        '${two(local.hour)}:'
        '${two(local.minute)}:'
        '${two(local.second)}';
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color:
                    Colors.white70,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 64,
          ),
          SizedBox(
            height: 16,
          ),
          Text(
            'No history yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            'Victron measurements will '
            'appear here automatically.',
            style: TextStyle(
              color:
                  Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

enum _HistoryRange {
  oneHour,
  sixHours,
  twentyFourHours,
  sevenDays,
}

extension _HistoryRangeExtension on _HistoryRange {
  Duration get duration {
    switch (this) {
      case _HistoryRange.oneHour:
        return const Duration(
          hours: 1,
        );

      case _HistoryRange.sixHours:
        return const Duration(
          hours: 6,
        );

      case _HistoryRange.twentyFourHours:
        return const Duration(
          hours: 24,
        );

      case _HistoryRange.sevenDays:
        return const Duration(
          days: 7,
        );
    }
  }
}