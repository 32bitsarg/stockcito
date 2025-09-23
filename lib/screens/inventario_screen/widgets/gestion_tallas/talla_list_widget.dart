import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../config/app_theme.dart';
import '../../../../models/talla.dart';

class TallaListWidget extends StatelessWidget {
  final List<Talla> tallas;
  final Function(Talla) onEditar;
  final Function(Talla) onEliminar;

  const TallaListWidget({
    super.key,
    required this.tallas,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    if (tallas.isEmpty) {
      return _buildEmptyState(context);
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tallas Disponibles (${tallas.length})',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: tallas.length,
              itemBuilder: (context, index) {
                final talla = tallas[index];
                return _buildTallaCard(context, talla, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              FontAwesomeIcons.ruler,
              size: 48,
              color: AppTheme.primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay tallas disponibles',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera talla para comenzar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTallaCard(BuildContext context, Talla talla, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            FontAwesomeIcons.ruler,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              talla.nombre,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (talla.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Por defecto',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: talla.descripcion != null && talla.descripcion!.isNotEmpty
            ? Text(
                talla.descripcion!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!talla.isDefault) ...[
              IconButton(
                onPressed: () => onEditar(talla),
                icon: const Icon(
                  FontAwesomeIcons.pen,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
                tooltip: 'Editar talla',
              ),
              IconButton(
                onPressed: () => onEliminar(talla),
                icon: const Icon(
                  FontAwesomeIcons.trash,
                  color: AppTheme.errorColor,
                  size: 16,
                ),
                tooltip: 'Eliminar talla',
              ),
            ] else ...[
              IconButton(
                onPressed: null,
                icon: Icon(
                  FontAwesomeIcons.lock,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                  size: 16,
                ),
                tooltip: 'Talla por defecto - No editable',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
