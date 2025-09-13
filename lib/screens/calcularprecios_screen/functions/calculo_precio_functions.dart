import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/material_item.dart';

class CalculoPrecioFunctions {
  /// Formatea un precio sin decimales innecesarios
  static String formatearPrecio(double precio) {
    if (precio == precio.roundToDouble()) {
      return precio.round().toString();
    } else {
      return precio.toStringAsFixed(2);
    }
  }

  /// Calcula los costos totales del producto
  static Map<String, double> calcularCostos({
    required List<MaterialItem> materiales,
    required double tiempoConfeccion,
    required double tarifaHora,
    required double costoEquipos,
    required double alquiler,
    required double servicios,
    required double gastosAdmin,
    required double productosEstimados,
  }) {
    // Costos de materiales
    final costoMateriales = materiales.fold<double>(
      0,
      (sum, material) => sum + (material.cantidad * material.precio),
    );

    // Costos de producción
    final costoManoObra = tiempoConfeccion * tarifaHora;

    // Costos fijos
    final costoFijoPorProducto = (alquiler + servicios + gastosAdmin) / productosEstimados;

    final costoTotal = costoMateriales + costoManoObra + costoEquipos + costoFijoPorProducto;

    return {
      'materiales': costoMateriales,
      'manoObra': costoManoObra,
      'equipos': costoEquipos,
      'costosFijos': costoFijoPorProducto,
      'costoTotal': costoTotal,
    };
  }

  /// Calcula el precio final con margen e IVA
  static Map<String, double> calcularPrecioFinal({
    required double costoTotal,
    required double margenGanancia,
    required double iva,
  }) {
    final precioSinIva = costoTotal * (1 + margenGanancia / 100);
    final precioConIva = precioSinIva * (1 + iva / 100);
    final ganancia = precioSinIva - costoTotal;
    final porcentajeGanancia = costoTotal > 0 ? (ganancia / costoTotal) * 100 : margenGanancia;

    return {
      'precioSinIva': precioSinIva,
      'precioConIva': precioConIva,
      'ganancia': ganancia,
      'porcentajeGanancia': porcentajeGanancia,
    };
  }

  /// Obtiene la información del paso actual
  static Map<String, dynamic> getStepInfo(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return {
          'title': 'Información del Producto',
          'description': 'Completa los datos básicos de tu producto. Esta información te ayudará a organizar mejor tu inventario y calcular costos precisos.',
          'icon': FontAwesomeIcons.circleInfo,
        };
      case 1:
        return {
          'title': 'Costos de Materiales',
          'description': 'Agrega todos los materiales necesarios para confeccionar tu producto. Incluye tela, hilos, botones, cierres, etiquetas y cualquier otro insumo.',
          'icon': FontAwesomeIcons.boxesStacked,
        };
      case 2:
        return {
          'title': 'Costos de Producción',
          'description': 'Calcula el costo de mano de obra y equipos necesarios para confeccionar tu producto. Considera el tiempo de trabajo y la depreciación de máquinas.',
          'icon': FontAwesomeIcons.hammer,
        };
      case 3:
        return {
          'title': 'Costos Fijos',
          'description': 'Incluye los gastos mensuales de tu negocio que se distribuyen entre todos los productos. Alquiler, servicios, gastos administrativos y otros costos operativos.',
          'icon': FontAwesomeIcons.house,
        };
      case 4:
        return {
          'title': 'Resultado Final',
          'description': 'Revisa el desglose completo de costos y el precio de venta sugerido. Analiza la rentabilidad y ajusta el margen de ganancia según tus objetivos de negocio.',
          'icon': FontAwesomeIcons.chartLine,
        };
      default:
        return {
          'title': 'Calculadora de Costos Completa',
          'description': 'Calcula el precio de venta de tus productos',
          'icon': Icons.calculate,
        };
    }
  }

  /// Valida los datos del producto
  static String? validarProducto({
    required String nombre,
    required String categoria,
    required String talla,
    required Map<String, double> costos,
  }) {
    if (nombre.trim().isEmpty) {
      return 'Por favor ingresa el nombre del producto';
    }

    if (categoria.isEmpty) {
      return 'Por favor selecciona una categoría';
    }

    if (talla.isEmpty) {
      return 'Por favor selecciona una talla';
    }

    if (costos['costoTotal']! <= 0) {
      return 'El costo total debe ser mayor a 0';
    }

    return null;
  }

  /// Obtiene las categorías disponibles
  static List<String> getCategorias() {
    return [
      'Bodies',
      'Conjuntos',
      'Vestidos',
      'Pijamas',
      'Gorros',
      'Accesorios',
    ];
  }

  /// Obtiene las tallas disponibles
  static List<String> getTallas() {
    return [
      '0-3 meses',
      '3-6 meses',
      '6-12 meses',
      '12-18 meses',
      '18-24 meses',
    ];
  }

  /// Limpia los controladores para un nuevo cálculo
  static void limpiarControladores({
    required TextEditingController nombreController,
    required TextEditingController descripcionController,
    required TextEditingController stockController,
    required TextEditingController tiempoConfeccionController,
    required TextEditingController tarifaHoraController,
    required TextEditingController costoEquiposController,
    required TextEditingController alquilerMensualController,
    required TextEditingController serviciosController,
    required TextEditingController gastosAdminController,
    required TextEditingController productosEstimadosController,
    required TextEditingController margenGananciaController,
    required TextEditingController ivaController,
    required List<MaterialItem> materiales,
  }) {
    nombreController.clear();
    descripcionController.clear();
    stockController.text = '1';
    materiales.clear();
    materiales.add(MaterialItem(nombre: 'Tela principal', cantidad: 1, precio: 0));
    tiempoConfeccionController.clear();
    tarifaHoraController.text = '15.0';
    costoEquiposController.text = '0';
    alquilerMensualController.clear();
    serviciosController.clear();
    gastosAdminController.clear();
    productosEstimadosController.text = '50';
    margenGananciaController.text = '50';
    ivaController.text = '21';
  }
}
