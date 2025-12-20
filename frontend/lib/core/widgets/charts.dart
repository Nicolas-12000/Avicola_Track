import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FlockWeightChart extends StatelessWidget {
  final List<Map<String, dynamic>> weightData;

  const FlockWeightChart({required this.weightData, super.key});

  @override
  Widget build(BuildContext context) {
    if (weightData.isEmpty) {
      return const Center(child: Text('No hay datos de peso disponibles'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 0.5,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                );
                if (value.toInt() < weightData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Día ${value.toInt() + 1}', style: style),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 0.5,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1)}kg',
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        minX: 0,
        maxX: (weightData.length - 1).toDouble(),
        minY: 0,
        maxY: _getMaxWeight() * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: weightData.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                (entry.value['weight'] as num).toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxWeight() {
    return weightData.fold<double>(
      0.0,
      (max, data) => (data['weight'] as num).toDouble() > max
          ? (data['weight'] as num).toDouble()
          : max,
    );
  }
}

class FlockMortalityChart extends StatelessWidget {
  final List<Map<String, dynamic>> mortalityData;

  const FlockMortalityChart({required this.mortalityData, super.key});

  @override
  Widget build(BuildContext context) {
    if (mortalityData.isEmpty) {
      return const Center(
        child: Text('No hay datos de mortalidad disponibles'),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < mortalityData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Día ${value.toInt() + 1}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 28,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        minX: 0,
        maxX: (mortalityData.length - 1).toDouble(),
        minY: 0,
        maxY: _getMaxMortality() * 1.5,
        lineBarsData: [
          LineChartBarData(
            spots: mortalityData.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                (entry.value['count'] as num).toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.red,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxMortality() {
    return mortalityData.fold<double>(
      0.0,
      (max, data) => (data['count'] as num).toDouble() > max
          ? (data['count'] as num).toDouble()
          : max,
    );
  }
}

class OccupancyPieChart extends StatelessWidget {
  final int occupiedSheds;
  final int totalSheds;

  const OccupancyPieChart({
    required this.occupiedSheds,
    required this.totalSheds,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (totalSheds == 0) {
      return const Center(child: Text('No hay datos de galpones'));
    }

    final availableSheds = totalSheds - occupiedSheds;
    final occupancyPercent = (occupiedSheds / totalSheds * 100).toInt();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: Colors.green,
                  value: occupiedSheds.toDouble(),
                  title: '$occupiedSheds',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.grey[300],
                  value: availableSheds.toDouble(),
                  title: '$availableSheds',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Ocupados', Colors.green, occupiedSheds),
            const SizedBox(width: 24),
            _buildLegendItem('Disponibles', Colors.grey[300]!, availableSheds),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Ocupación: $occupancyPercent%',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text('$label ($value)', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class InventoryBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> inventoryData;

  const InventoryBarChart({required this.inventoryData, super.key});

  @override
  Widget build(BuildContext context) {
    if (inventoryData.isEmpty) {
      return const Center(child: Text('No hay datos de inventario'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxQuantity() * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${inventoryData[groupIndex]['name']}\n${rod.toY.toInt()} unidades',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < inventoryData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      inventoryData[value.toInt()]['name'] as String,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        barGroups: inventoryData.asMap().entries.map((entry) {
          final color = _getBarColor(entry.value['status'] as String);
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: (entry.value['quantity'] as num).toDouble(),
                color: color,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  double _getMaxQuantity() {
    return inventoryData.fold<double>(
      0.0,
      (max, data) => (data['quantity'] as num).toDouble() > max
          ? (data['quantity'] as num).toDouble()
          : max,
    );
  }

  Color _getBarColor(String status) {
    switch (status) {
      case 'critical':
        return Colors.red;
      case 'low':
        return Colors.orange;
      case 'normal':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}
