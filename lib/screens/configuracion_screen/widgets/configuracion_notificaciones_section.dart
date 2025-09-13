import 'package:flutter/material.dart';
import 'configuracion_card.dart';
import 'configuracion_controls.dart';

class ConfiguracionNotificacionesSection extends StatelessWidget {
  final bool notificacionesStock;
  final bool notificacionesVentas;
  final int stockMinimo;
  final Function(bool) onNotificacionesStockChanged;
  final Function(bool) onNotificacionesVentasChanged;
  final Function(int) onStockMinimoChanged;

  const ConfiguracionNotificacionesSection({
    super.key,
    required this.notificacionesStock,
    required this.notificacionesVentas,
    required this.stockMinimo,
    required this.onNotificacionesStockChanged,
    required this.onNotificacionesVentasChanged,
    required this.onStockMinimoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ConfiguracionCard(
      title: 'Notificaciones',
      icon: Icons.notifications,
      children: [
        ConfiguracionControls.buildSwitchConfig(
          context,
          'Notificaciones de Stock Bajo',
          notificacionesStock,
          onNotificacionesStockChanged,
          'Recibe alertas cuando el stock esté por debajo del mínimo',
        ),
        const SizedBox(height: 16),
        ConfiguracionControls.buildNumberConfig(
          context,
          'Nivel Mínimo de Stock',
          stockMinimo,
          onStockMinimoChanged,
          'Cantidad mínima de productos antes de generar alertas',
          1,
          100,
        ),
        const SizedBox(height: 16),
        ConfiguracionControls.buildSwitchConfig(
          context,
          'Notificaciones de Ventas',
          notificacionesVentas,
          onNotificacionesVentasChanged,
          'Recibe notificaciones sobre ventas importantes',
        ),
      ],
    );
  }
}
