import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../widgets/animated_widgets.dart';
import '../models/material_item.dart';
import '../functions/calculo_precio_functions.dart';
import 'calculo_precio_navigation_buttons.dart';

class CalculoPrecioMaterialesTab extends StatelessWidget {
  final List<MaterialItem> materiales;
  final Function() onAgregarMaterial;
  final Function(int) onEditarMaterial;
  final Function(int) onEliminarMaterial;
  final TabController tabController;

  const CalculoPrecioMaterialesTab({
    super.key,
    required this.materiales,
    required this.onAgregarMaterial,
    required this.onEditarMaterial,
    required this.onEliminarMaterial,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedButton(
                text: 'Agregar Material',
                type: ButtonType.primary,
                onPressed: onAgregarMaterial,
                icon: FontAwesomeIcons.plus,
                delay: const Duration(milliseconds: 100),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: materiales.isEmpty
                ? const Center(
                    child: Text(
                      'No hay materiales agregados',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: materiales.length,
                    itemBuilder: (context, index) {
                      final material = materiales[index];
                      return AnimatedCard(
                        delay: Duration(milliseconds: 100 * (index + 1)),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    FontAwesomeIcons.boxesStacked,
                                    color: AppTheme.primaryColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        material.nombre,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            'Cantidad: ${material.cantidad}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            'Precio: \$${CalculoPrecioFunctions.formatearPrecio(material.precio)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${CalculoPrecioFunctions.formatearPrecio(material.cantidad * material.precio)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.successColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: IconButton(
                                            onPressed: () => onEditarMaterial(index),
                                            icon: const FaIcon(FontAwesomeIcons.penToSquare, color: AppTheme.primaryColor, size: 18),
                                            tooltip: 'Editar material',
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: AppTheme.errorColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: IconButton(
                                            onPressed: () => onEliminarMaterial(index),
                                            icon: const FaIcon(FontAwesomeIcons.trash, color: AppTheme.errorColor, size: 18),
                                            tooltip: 'Eliminar material',
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          CalculoPrecioNavigationButtons(
            currentIndex: 1,
            tabController: tabController,
          ),
        ],
      ),
    );
  }
}
