import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../widgets/windows_button.dart';

class ReportesHeader extends StatelessWidget {
  final VoidCallback onExportarPDF;
  final VoidCallback onExportarCSV;
  final VoidCallback onExportarJSON;

  const ReportesHeader({
    super.key,
    required this.onExportarPDF,
    required this.onExportarCSV,
    required this.onExportarJSON,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Reportes y Análisis',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Análisis detallado de tu inventario y rendimiento',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Botones de exportación
          Row(
            children: [
              WindowsButton(
                text: 'CSV',
                type: ButtonType.secondary,
                onPressed: onExportarCSV,
                icon: Icons.table_chart,
              ),
              const SizedBox(width: 8),
              WindowsButton(
                text: 'JSON',
                type: ButtonType.secondary,
                onPressed: onExportarJSON,
                icon: Icons.code,
              ),
              const SizedBox(width: 8),
              WindowsButton(
                text: 'PDF',
                type: ButtonType.primary,
                onPressed: onExportarPDF,
                icon: Icons.picture_as_pdf,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
