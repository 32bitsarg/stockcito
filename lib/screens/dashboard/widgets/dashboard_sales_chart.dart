import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';

class DashboardSalesChart extends StatelessWidget {
  final double ventasDelMes;

  const DashboardSalesChart({
    super.key,
    required this.ventasDelMes,
  });

  @override
  Widget build(BuildContext context) {
    final ventasPorDia = _generateVentasPorDia(ventasDelMes);
    
    if (ventasPorDia.isEmpty) {
      return _buildEmptyChart();
    }

    return _buildSalesChart(ventasPorDia);
  }

  Widget _buildEmptyChart() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: const Center(
        child: Text(
          'No hay datos de ventas para mostrar',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSalesChart(List<Map<String, dynamic>> ventasPorDia) {
    final maxVenta = ventasPorDia.map((v) => v['total'] as double).reduce((a, b) => a > b ? a : b);
    final now = DateTime.now();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.chartLine,
                color: AppTheme.primaryColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                'Ventas por Día (Últimos 7 días)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: ventasPorDia.map((venta) {
                final fecha = DateTime.parse(venta['fecha']);
                final total = venta['total'] as double;
                final isToday = fecha.day == now.day && fecha.month == now.month;
                final height = maxVenta > 0 ? (total / maxVenta) * 120 : 0.0;
                final day = _getDayName(fecha.weekday);

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 72.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Barra del gráfico
                              Container(
                                width: double.infinity,
                                height: height.clamp(0.0, 60.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: isToday 
                                      ? [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)]
                                      : [AppTheme.primaryColor.withOpacity(0.6), AppTheme.primaryColor.withOpacity(0.3)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Día de la semana
                              Text(
                                day,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isToday ? AppTheme.primaryColor : AppTheme.textSecondary,
                                  fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              // Valor
                              Text(
                                '\$${total.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Generar datos simulados de ventas por día
  List<Map<String, dynamic>> _generateVentasPorDia(double ventasMes) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> ventasPorDia = [];
    final ventasSemana = ventasMes * 0.25; // 25% del mes
    
    for (int i = 6; i >= 0; i--) {
      final fecha = now.subtract(Duration(days: i));
      final factor = _getDayFactor(fecha.weekday);
      final total = (ventasSemana * factor).roundToDouble();
      
      ventasPorDia.add({
        'fecha': fecha.toIso8601String().split('T')[0],
        'total': total,
      });
    }
    
    return ventasPorDia;
  }

  // Obtener factor de ventas por día de la semana
  double _getDayFactor(int weekday) {
    switch (weekday) {
      case 1: return 0.12; // Lunes
      case 2: return 0.15; // Martes
      case 3: return 0.18; // Miércoles
      case 4: return 0.20; // Jueves
      case 5: return 0.22; // Viernes
      case 6: return 0.08; // Sábado
      case 7: return 0.05; // Domingo
      default: return 0.10;
    }
  }

  // Obtener nombre del día
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'L';
      case 2: return 'M';
      case 3: return 'X';
      case 4: return 'J';
      case 5: return 'V';
      case 6: return 'S';
      case 7: return 'D';
      default: return '';
    }
  }
}
