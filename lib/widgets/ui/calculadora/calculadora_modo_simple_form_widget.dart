import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../screens/calcularprecios_screen/models/calculadora_config.dart';
import '../../../services/ui/calculadora/modo_simple_service.dart';
import '../../../services/ui/calculadora/calculadora_validation_service.dart';

/// Widget para el formulario del modo simple
class CalculadoraModoSimpleFormWidget extends StatefulWidget {
  final CalculadoraConfig config;
  final Function(ResultadoModoSimple) onResultado;

  const CalculadoraModoSimpleFormWidget({
    Key? key,
    required this.config,
    required this.onResultado,
  }) : super(key: key);

  @override
  State<CalculadoraModoSimpleFormWidget> createState() => _CalculadoraModoSimpleFormWidgetState();
}

class _CalculadoraModoSimpleFormWidgetState extends State<CalculadoraModoSimpleFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _tallaController = TextEditingController();
  final _stockController = TextEditingController();
  final _precioController = TextEditingController();
  final _descripcionController = TextEditingController();

  final ModoSimpleService _modoSimpleService = ModoSimpleService();
  final CalculadoraValidationService _validationService = CalculadoraValidationService();

  bool _isLoading = false;
  ValidacionResultado? _validacionResultado;

  @override
  void initState() {
    super.initState();
    _categoriaController.text = 'General';
    _tallaController.text = 'Única';
    _stockController.text = '1';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _categoriaController.dispose();
    _tallaController.dispose();
    _stockController.dispose();
    _precioController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del formulario
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.speed,
                  color: AppTheme.successColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modo Simple',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Guarda productos rápidamente con precio básico',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Campos del formulario
          _buildCampoNombre(),
          const SizedBox(height: 16),
          
          _buildCampoCategoria(),
          const SizedBox(height: 16),
          
          _buildCampoTalla(),
          const SizedBox(height: 16),
          
          _buildCampoStock(),
          const SizedBox(height: 16),
          
          _buildCampoPrecio(),
          const SizedBox(height: 16),
          
          _buildCampoDescripcion(),
          const SizedBox(height: 20),
          
          // Validaciones
          if (_validacionResultado != null) ...[
            _buildValidaciones(),
            const SizedBox(height: 20),
          ],
          
          // Botones
          _buildBotones(),
          
          const SizedBox(height: 16),
          
          // Información adicional
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.infoColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.infoColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'El producto se guardará con el precio especificado y estará disponible para ventas inmediatas.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.infoColor.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoNombre() {
    return TextFormField(
      controller: _nombreController,
      decoration: InputDecoration(
        labelText: 'Nombre del Producto *',
        hintText: 'Ej: Camiseta de algodón',
        prefixIcon: const Icon(Icons.inventory_2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El nombre es requerido';
        }
        if (value.trim().length < 2) {
          return 'El nombre debe tener al menos 2 caracteres';
        }
        return null;
      },
      onChanged: (_) => _validarEnTiempoReal(),
    );
  }

  Widget _buildCampoCategoria() {
    return DropdownButtonFormField<String>(
      value: _categoriaController.text,
      decoration: InputDecoration(
        labelText: 'Categoría *',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
      ),
      items: _getCategorias().map((categoria) {
        return DropdownMenuItem(
          value: categoria,
          child: Text(categoria),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _categoriaController.text = value ?? 'General';
        });
        _validarEnTiempoReal();
      },
    );
  }

  Widget _buildCampoTalla() {
    return TextFormField(
      controller: _tallaController,
      decoration: InputDecoration(
        labelText: 'Talla (Opcional)',
        hintText: 'Ej: M, L, XL o Única',
        prefixIcon: const Icon(Icons.straighten),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
      ),
      onChanged: (_) => _validarEnTiempoReal(),
    );
  }

  Widget _buildCampoStock() {
    return TextFormField(
      controller: _stockController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Stock Inicial *',
        hintText: 'Ej: 10',
        prefixIcon: const Icon(Icons.inventory),
        suffixText: 'unidades',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El stock es requerido';
        }
        final stock = int.tryParse(value);
        if (stock == null || stock < 0) {
          return 'El stock debe ser un número mayor o igual a 0';
        }
        if (stock > 10000) {
          return 'El stock no puede exceder 10,000 unidades';
        }
        return null;
      },
      onChanged: (_) => _validarEnTiempoReal(),
    );
  }

  Widget _buildCampoPrecio() {
    return TextFormField(
      controller: _precioController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Precio Actual *',
        hintText: 'Ej: 25.50',
        prefixIcon: const Icon(Icons.attach_money),
        suffixText: 'ARS',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El precio es requerido';
        }
        final precio = double.tryParse(value);
        if (precio == null || precio <= 0) {
          return 'El precio debe ser mayor a 0';
        }
        if (precio > 100000) {
          return 'El precio no puede exceder \$100,000';
        }
        return null;
      },
      onChanged: (_) => _validarEnTiempoReal(),
    );
  }

  Widget _buildCampoDescripcion() {
    return TextFormField(
      controller: _descripcionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Descripción (Opcional)',
        hintText: 'Describe las características del producto...',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
      ),
      onChanged: (_) => _validarEnTiempoReal(),
    );
  }

  Widget _buildValidaciones() {
    if (_validacionResultado == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _validacionResultado!.esValido 
            ? AppTheme.successColor.withOpacity(0.1)
            : AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _validacionResultado!.esValido 
              ? AppTheme.successColor.withOpacity(0.3)
              : AppTheme.errorColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _validacionResultado!.esValido ? Icons.check_circle : Icons.error,
                color: _validacionResultado!.esValido ? AppTheme.successColor : AppTheme.errorColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _validacionResultado!.esValido ? 'Datos válidos' : 'Revisar datos',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _validacionResultado!.esValido ? AppTheme.successColor : AppTheme.errorColor,
                ),
              ),
            ],
          ),
          
          if (_validacionResultado!.errores.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._validacionResultado!.errores.values.map((error) => Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 4),
              child: Text(
                '• $error',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.errorColor,
                ),
              ),
            )),
          ],
          
          if (_validacionResultado!.advertencias.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._validacionResultado!.advertencias.values.map((advertencia) => Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 4),
              child: Text(
                '⚠ $advertencia',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.warningColor,
                ),
              ),
            )),
          ],
          
          if (_validacionResultado!.sugerencias.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._validacionResultado!.sugerencias.map((sugerencia) => Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 4),
              child: Text(
                '💡 $sugerencia',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.infoColor,
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildBotones() {
    return Column(
      children: [
        // Botón principal de guardar
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _guardarProducto,
            icon: _isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save, size: 20),
            label: Text(
              _isLoading ? 'Guardando...' : 'Guardar Producto',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Botón secundario de sugerencias
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _obtenerSugerencias,
            icon: const Icon(Icons.lightbulb_outline, size: 18),
            label: const Text(
              'Ver Sugerencias de Precio',
              style: TextStyle(fontSize: 14),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.infoColor,
              side: BorderSide(color: AppTheme.infoColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<String> _getCategorias() {
    return [
      'General',
      'Camiseta',
      'Pantalón',
      'Vestido',
      'Chaqueta',
      'Zapatos',
      'Accesorios',
      'Ropa Interior',
      'Deportiva',
    ];
  }

  void _validarEnTiempoReal() {
    if (_nombreController.text.isNotEmpty && _precioController.text.isNotEmpty) {
      final precio = double.tryParse(_precioController.text);
      if (precio != null) {
        setState(() {
          _validacionResultado = _validationService.validarModoSimple(
            nombre: _nombreController.text,
            categoria: _categoriaController.text,
            talla: _tallaController.text.isEmpty ? null : _tallaController.text,
            stock: int.tryParse(_stockController.text) ?? 1,
            precioActual: precio,
            descripcion: _descripcionController.text.isEmpty ? null : _descripcionController.text,
          );
        });
      }
    }
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final precio = double.parse(_precioController.text);
      final stock = int.parse(_stockController.text);
      
      final resultado = await _modoSimpleService.guardarProductoSimple(
        nombre: _nombreController.text,
        categoria: _categoriaController.text,
        talla: _tallaController.text.isEmpty ? null : _tallaController.text,
        stock: stock,
        precioActual: precio,
        descripcion: _descripcionController.text.isEmpty ? null : _descripcionController.text,
        config: widget.config,
      );

      widget.onResultado(resultado);

      if (resultado.exito) {
        _limpiarFormulario();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.mensaje ?? 'Producto guardado exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.mensaje ?? 'Error guardando producto'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _obtenerSugerencias() async {
    if (_categoriaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoría para obtener sugerencias'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sugerencias = await _modoSimpleService.obtenerSugerenciasPrecio(
        categoria: _categoriaController.text,
        config: widget.config,
      );

      _mostrarDialogoSugerencias(sugerencias);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error obteniendo sugerencias: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mostrarDialogoSugerencias(Map<String, dynamic> sugerencias) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sugerencias de Precio'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sugerencias['estadisticas'] != null) ...[
                Text(
                  'Estadísticas de la categoría:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ..._buildEstadisticas(sugerencias['estadisticas']),
                const SizedBox(height: 16),
              ],
              
              if (sugerencias['sugerencias'] != null) ...[
                Text(
                  'Recomendaciones:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...(sugerencias['sugerencias'] as List<String>).map((sugerencia) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $sugerencia'),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEstadisticas(Map<String, dynamic> estadisticas) {
    return [
      Text('Productos similares: ${estadisticas['cantidad']}'),
      Text('Precio promedio: \$${estadisticas['precioPromedio']?.toStringAsFixed(2) ?? 'N/A'}'),
      Text('Precio mínimo: \$${estadisticas['precioMinimo']?.toStringAsFixed(2) ?? 'N/A'}'),
      Text('Precio máximo: \$${estadisticas['precioMaximo']?.toStringAsFixed(2) ?? 'N/A'}'),
    ];
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _categoriaController.text = 'General';
    _tallaController.text = 'Única';
    _stockController.text = '1';
    _precioController.clear();
    _descripcionController.clear();
    setState(() {
      _validacionResultado = null;
    });
  }
}
