import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/venta.dart';
import '../../../widgets/animated_widgets.dart';
import '../functions/ventas_functions.dart';

class VentasListWidget extends StatelessWidget {
  final List<Venta> ventas;
  final Function(Venta) onVerVenta;
  final Function(Venta) onEditarVenta;
  final Function(Venta) onEliminarVenta;

  const VentasListWidget({
    super.key,
    required this.ventas,
    required this.onVerVenta,
    required this.onEditarVenta,
    required this.onEliminarVenta,
  });

  @override
  Widget build(BuildContext context) {
    if (ventas.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ventas (${ventas.length})',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ventas.length,
          itemBuilder: (context, index) {
            final venta = ventas[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildVentaCard(context, venta),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay ventas registradas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Las ventas aparecerán aquí cuando se creen.\n¡Comienza creando tu primera venta!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Usa el botón "Nueva Venta" para comenzar',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentaCard(BuildContext context, Venta venta) {
    return AnimatedCard(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con gradiente
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VentasFunctions.getEstadoColor(venta.estado).withOpacity(0.1),
                    VentasFunctions.getEstadoColor(venta.estado).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: VentasFunctions.getEstadoColor(venta.estado).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      VentasFunctions.getEstadoIcon(venta.estado),
                      color: VentasFunctions.getEstadoColor(venta.estado),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Venta #${venta.id}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cliente: ${venta.cliente}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        VentasFunctions.formatPrecio(venta.total),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: VentasFunctions.getEstadoColor(venta.estado).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          VentasFunctions.getEstadoText(venta.estado),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: VentasFunctions.getEstadoColor(venta.estado),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información adicional
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          context,
                          'Fecha',
                          VentasFunctions.formatFecha(venta.fecha),
                          Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          context,
                          'Método de Pago',
                          VentasFunctions.getMetodoPagoText(venta.metodoPago),
                          Icons.payment,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          context,
                          'Productos',
                          '${venta.items.length}',
                          Icons.shopping_bag,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context,
                          'Ver Detalle',
                          Icons.visibility,
                          AppTheme.primaryColor,
                          () => onVerVenta(venta),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (VentasFunctions.canEditVenta(venta))
                        Expanded(
                          child: _buildActionButton(
                            context,
                            'Editar',
                            Icons.edit,
                            AppTheme.secondaryColor,
                            () => onEditarVenta(venta),
                          ),
                        ),
                      if (VentasFunctions.canEditVenta(venta))
                        const SizedBox(width: 12),
                      if (VentasFunctions.canDeleteVenta(venta))
                        Expanded(
                          child: _buildActionButton(
                            context,
                            'Eliminar',
                            Icons.delete,
                            AppTheme.errorColor,
                            () => onEliminarVenta(venta),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
