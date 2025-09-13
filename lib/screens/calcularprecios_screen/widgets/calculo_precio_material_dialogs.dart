import 'package:flutter/material.dart';
import '../../../widgets/animated_widgets.dart';
import '../models/material_item.dart';

class CalculoPrecioMaterialDialogs {
  /// Diálogo para agregar material
  static void showAgregarMaterialDialog({
    required BuildContext context,
    required TextEditingController nombreController,
    required TextEditingController cantidadController,
    required TextEditingController precioController,
    required Function(MaterialItem) onAgregar,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Material'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Material',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: cantidadController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: precioController,
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          AnimatedButton(
            text: 'Cancelar',
            type: ButtonType.secondary,
            onPressed: () => Navigator.pop(context),
            delay: const Duration(milliseconds: 100),
          ),
          AnimatedButton(
            text: 'Agregar',
            type: ButtonType.primary,
            onPressed: () {
              if (nombreController.text.isNotEmpty) {
                onAgregar(MaterialItem(
                  nombre: nombreController.text,
                  cantidad: double.tryParse(cantidadController.text) ?? 1,
                  precio: double.tryParse(precioController.text) ?? 0,
                ));
                nombreController.clear();
                cantidadController.clear();
                precioController.clear();
                Navigator.pop(context);
              }
            },
            delay: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  /// Diálogo para editar material
  static void showEditarMaterialDialog({
    required BuildContext context,
    required MaterialItem material,
    required TextEditingController nombreController,
    required TextEditingController cantidadController,
    required TextEditingController precioController,
    required Function(MaterialItem) onEditar,
  }) {
    // Llenar los controladores con los valores actuales
    nombreController.text = material.nombre;
    cantidadController.text = material.cantidad.toString();
    precioController.text = material.precio.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Material'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Material',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: cantidadController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: precioController,
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          AnimatedButton(
            text: 'Cancelar',
            type: ButtonType.secondary,
            onPressed: () {
              nombreController.clear();
              cantidadController.clear();
              precioController.clear();
              Navigator.pop(context);
            },
            delay: const Duration(milliseconds: 100),
          ),
          AnimatedButton(
            text: 'Guardar',
            type: ButtonType.primary,
            onPressed: () {
              if (nombreController.text.isNotEmpty) {
                onEditar(MaterialItem(
                  nombre: nombreController.text,
                  cantidad: double.tryParse(cantidadController.text) ?? 1,
                  precio: double.tryParse(precioController.text) ?? 0,
                ));
                nombreController.clear();
                cantidadController.clear();
                precioController.clear();
                Navigator.pop(context);
              }
            },
            delay: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
