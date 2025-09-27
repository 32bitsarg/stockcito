import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../services/ml/ml_data_validation_service.dart';
import '../../../models/venta.dart';
import '../../../models/producto.dart';

/// Widget para mostrar mensajes educativos cuando no hay datos suficientes para ML
class MLEducationalMessageWidget extends StatelessWidget {
  final MLValidationErrorType? errorType;
  final int? requiredData;
  final int? currentData;
  final VoidCallback? onActionPressed;

  const MLEducationalMessageWidget({
    super.key,
    this.errorType,
    this.requiredData,
    this.currentData,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final message = MLDataValidationService().generateEducationalMessage(
      errorType ?? MLValidationErrorType.insufficientSales,
      requiredData ?? 5,
      currentData ?? 0,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '💡 Mejora tus Recomendaciones',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Mensaje educativo
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Barra de progreso si hay datos parciales
          if (currentData != null && requiredData != null && currentData! > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '$currentData / $requiredData',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (currentData! / requiredData!).clamp(0.0, 1.0),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  minHeight: 6,
                ),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Botón de acción
          if (onActionPressed != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar Datos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget compacto para mostrar estado de datos ML
class MLDataStatusWidget extends StatelessWidget {
  final int ventasCount;
  final int productosCount;
  final int clientesCount;
  final VoidCallback? onRefresh;

  const MLDataStatusWidget({
    super.key,
    required this.ventasCount,
    required this.productosCount,
    required this.clientesCount,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Determinar el estado general
    final demandValidation = MLDataValidationService().validateDemandTrainingData(
      <Venta>[], // Lista vacía para validación
      <Producto>[], // Lista vacía para validación
    );
    
    final hasEnoughData = demandValidation.isValid;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasEnoughData 
            ? AppTheme.successColor.withOpacity(0.1)
            : AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasEnoughData 
              ? AppTheme.successColor.withOpacity(0.3)
              : AppTheme.warningColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasEnoughData ? Icons.check_circle : Icons.info,
            color: hasEnoughData ? AppTheme.successColor : AppTheme.warningColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasEnoughData 
                  ? '✅ Datos suficientes para IA'
                  : '⚠️ Necesitas más datos para IA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasEnoughData ? AppTheme.successColor : AppTheme.warningColor,
              ),
            ),
          ),
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
