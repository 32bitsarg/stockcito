import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/ui/calculadora/calculadora_state_service.dart';
import '../../../services/ui/calculadora/calculadora_logic_service.dart';
import '../../../services/ui/calculadora/calculadora_navigation_service.dart';

/// Widget que contiene el contenido principal de la pantalla de calculadora
class CalculadoraContentWidget extends StatelessWidget {
  const CalculadoraContentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculadoraStateService>(
      builder: (context, stateService, child) {
        final logicService = Provider.of<CalculadoraLogicService>(context, listen: false);
        final navigationService = Provider.of<CalculadoraNavigationService>(context, listen: false);
        
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // Contenido principal con stepper
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Stepper vertical simplificado
                    _buildStepper(context, stateService, logicService),
                    
                    // Contenido del paso actual
                    Expanded(
                      child: _buildCurrentStepContent(context, stateService, logicService, navigationService),
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

  Widget _buildCurrentStepContent(
    BuildContext context,
    CalculadoraStateService stateService,
    CalculadoraLogicService logicService,
    CalculadoraNavigationService navigationService,
  ) {
    switch (stateService.currentStep) {
      case 0:
        return _buildConfigStep(context, stateService, logicService);
      case 1:
        return _buildProductoStep(context, stateService, logicService);
      case 2:
        return _buildCostosDirectosStep(context, stateService, logicService, navigationService);
      case 3:
        return _buildCostosIndirectosStep(context, stateService, logicService, navigationService);
      case 4:
        return _buildResultadoStep(context, stateService, logicService);
      default:
        return _buildConfigStep(context, stateService, logicService);
    }
  }

  Widget _buildConfigStep(
    BuildContext context,
    CalculadoraStateService stateService,
    CalculadoraLogicService logicService,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuración',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          _buildConfigContent(context, stateService, logicService),
          const SizedBox(height: 24),
          _buildStepNavigation(context, stateService, logicService),
        ],
      ),
    );
  }

  Widget _buildProductoStep(
    BuildContext context,
    CalculadoraStateService stateService,
    CalculadoraLogicService logicService,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Producto',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          _buildProductoContent(context, stateService, logicService),
          const SizedBox(height: 24),
          _buildStepNavigation(context, stateService, logicService),
        ],
      ),
    );
  }

  Widget _buildCostosDirectosStep(
    BuildContext context,
    CalculadoraStateService stateService,
    CalculadoraLogicService logicService,
    CalculadoraNavigationService navigationService,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Costos Directos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          _buildCostosDirectosContent(context, stateService, logicService, navigationService),
          const SizedBox(height: 24),
          _buildStepNavigation(context, stateService, logicService),
        ],
      ),
    );
  }

  Widget _buildCostosIndirectosStep(
    BuildContext context,
    CalculadoraStateService stateService,
    CalculadoraLogicService logicService,
    CalculadoraNavigationService navigationService,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Costos Indirectos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          _buildCostosIndirectosContent(context, stateService, logicService, navigationService),
          const SizedBox(height: 24),
          _buildStepNavigation(context, stateService, logicService),
        ],
      ),
    );
  }

  Widget _buildResultadoStep(
    BuildContext context,
    CalculadoraStateService stateService,
    CalculadoraLogicService logicService,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resultado',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          _buildResultadoContent(context, stateService, logicService),
          const SizedBox(height: 24),
          _buildStepNavigation(context, stateService, logicService),
        ],
      ),
    );
  }

  Widget _buildStepNavigation(
    BuildContext context,
    CalculadoraStateService stateService,
    CalculadoraLogicService logicService,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Botón anterior
        if (stateService.canGoPrevious())
          ElevatedButton.icon(
            onPressed: () => logicService.previousStep(),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Anterior'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B7280),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        else
          const SizedBox.shrink(),
        
        // Botón siguiente
        if (stateService.canGoNext())
          ElevatedButton.icon(
            onPressed: () => logicService.nextStep(),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Siguiente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildConfigContent(
    BuildContext context,
    CalculadoraStateService stateService,
    CalculadoraLogicService logicService,
  ) {
    return Column(
      children: [
        // Selector de modo
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Modo de Calculadora',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'El modo simple ofrece cálculos básicos, mientras que el modo avanzado incluye análisis detallados y opciones adicionales.',
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Modo Simple'),
                        subtitle: const Text('Cálculo básico de precios'),
                        value: false,
                        groupValue: stateService.config.modoAvanzado,
                        onChanged: (value) {
                          if (value != null) {
                            final newConfig = stateService.config.copyWith(modoAvanzado: value);
                            logicService.saveConfiguracion(newConfig);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Modo Avanzado'),
                        subtitle: const Text('Análisis detallado y opciones avanzadas'),
                        value: true,
                        groupValue: stateService.config.modoAvanzado,
                        onChanged: (value) {
                          if (value != null) {
                            final newConfig = stateService.config.copyWith(modoAvanzado: value);
                            logicService.saveConfiguracion(newConfig);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Información sobre configuración de precios
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configuración de Precios',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'El margen de ganancia y el IVA se configuran desde la pantalla de Configuración. Los valores actuales son: Margen ${stateService.config.margenGananciaDefault.toStringAsFixed(1)}% e IVA ${stateService.config.ivaDefault.toStringAsFixed(1)}%.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductoContent(
    BuildContext context,
    CalculadoraStateService stateService,
    CalculadoraLogicService logicService,
  ) {
    return FutureBuilder<List<String>>(
      future: logicService.getCategorias(),
      builder: (context, categoriasSnapshot) {
        return FutureBuilder<List<String>>(
          future: logicService.getTallas(),
          builder: (context, tallasSnapshot) {
            final categorias = categoriasSnapshot.data ?? [];
            final tallas = tallasSnapshot.data ?? [];
            
            return Column(
              children: [
                // Nombre del producto
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Producto',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: Camiseta básica algodón',
                  ),
                  onChanged: (value) {
                    // Actualizar nombre del producto
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Categoría y Talla
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          border: OutlineInputBorder(),
                          hintText: 'Selecciona una categoría',
                        ),
                        items: categorias.map((categoria) => 
                          DropdownMenuItem(
                            value: categoria,
                            child: Text(categoria),
                          ),
                        ).toList(),
                        onChanged: (value) {
                          // Actualizar categoría
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Talla',
                          border: OutlineInputBorder(),
                          hintText: 'Selecciona una talla',
                        ),
                        items: tallas.map((talla) => 
                          DropdownMenuItem(
                            value: talla,
                            child: Text(talla),
                          ),
                        ).toList(),
                        onChanged: (value) {
                          // Actualizar talla
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Información sobre categorías y tallas
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Las categorías y tallas incluyen las opciones por defecto y las que has creado en el inventario.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCostosDirectosContent(
    BuildContext context,
    CalculadoraStateService stateService,
    CalculadoraLogicService logicService,
    CalculadoraNavigationService navigationService,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Costos Directos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await navigationService.showCostoDirectoDialog(context);
                if (result != null) {
                  // Agregar costo directo
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (stateService.costosDirectos.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'No hay costos directos agregados',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          )
        else
          ...stateService.costosDirectos.asMap().entries.map((entry) => 
            ListTile(
              title: Text((entry.value as dynamic).nombre ?? 'Costo'),
              subtitle: Text('\$${((entry.value as dynamic).costo ?? 0.0).toStringAsFixed(2)}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => logicService.removeCostoDirecto(entry.key),
              ),
            ),
          ).toList(),
      ],
    );
  }

  Widget _buildCostosIndirectosContent(
    BuildContext context,
    CalculadoraStateService stateService,
    CalculadoraLogicService logicService,
    CalculadoraNavigationService navigationService,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Costos Indirectos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await navigationService.showCostoIndirectoDialog(context);
                if (result != null) {
                  // Agregar costo indirecto
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (stateService.costosIndirectos.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'No hay costos indirectos agregados',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          )
        else
          ...stateService.costosIndirectos.asMap().entries.map((entry) => 
            ListTile(
              title: Text((entry.value as dynamic).nombre ?? 'Costo'),
              subtitle: Text('\$${((entry.value as dynamic).costo ?? 0.0).toStringAsFixed(2)}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => logicService.removeCostoIndirecto(entry.key),
              ),
            ),
          ).toList(),
      ],
    );
  }

  Widget _buildResultadoContent(
    BuildContext context,
    CalculadoraStateService stateService,
    CalculadoraLogicService logicService,
  ) {
    final resultado = logicService.calculateFinalPrice();
    
    return Column(
      children: [
        const Text(
          'Resultado del Cálculo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Costo Total:'),
                  Text('\$${resultado['costoTotal']?.toStringAsFixed(2) ?? '0.00'}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Precio de Venta:'),
                  Text('\$${resultado['precioVenta']?.toStringAsFixed(2) ?? '0.00'}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Precio con IVA:'),
                  Text(
                    '\$${resultado['precioConIVA']?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepper(
    BuildContext context,
    CalculadoraStateService stateService,
    CalculadoraLogicService logicService,
  ) {
    final steps = [
      {'title': 'Configuración', 'icon': Icons.settings, 'description': 'Configurar parámetros'},
      {'title': 'Producto', 'icon': Icons.inventory_2, 'description': 'Definir producto'},
      {'title': 'Costos Directos', 'icon': Icons.monetization_on, 'description': 'Materiales y mano de obra'},
      {'title': 'Costos Indirectos', 'icon': Icons.business, 'description': 'Gastos generales'},
      {'title': 'Resultado', 'icon': Icons.calculate, 'description': 'Ver precio final'},
    ];

    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Proceso de Cálculo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isActive = stateService.currentStep == index;
            final isCompleted = stateService.currentStep > index;
            
            return GestureDetector(
              onTap: () => logicService.goToStep(index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF3B82F6) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive 
                            ? Colors.white 
                            : isCompleted 
                                ? const Color(0xFF10B981) 
                                : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : step['icon'] as IconData,
                        color: isActive 
                            ? const Color(0xFF3B82F6) 
                            : isCompleted 
                                ? Colors.white 
                                : const Color(0xFF6B7280),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['title'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white : const Color(0xFF2D2D2D),
                            ),
                          ),
                          Text(
                            step['description'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isActive ? Colors.white70 : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
