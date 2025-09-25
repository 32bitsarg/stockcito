import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../widgets/ui/utility/animated_widgets.dart';
import '../services/calculadora_service.dart';
import '../models/calculadora_config.dart';

/// Widget para configurar el modo de la calculadora
class CalculadoraConfigWidget extends StatefulWidget {
  final CalculadoraService calculadoraService;
  final VoidCallback onConfigChanged;

  const CalculadoraConfigWidget({
    super.key,
    required this.calculadoraService,
    required this.onConfigChanged,
  });

  @override
  State<CalculadoraConfigWidget> createState() => _CalculadoraConfigWidgetState();
}

class _CalculadoraConfigWidgetState extends State<CalculadoraConfigWidget> {
  late CalculadoraConfig _config;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _config = widget.calculadoraService.config;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del paso
          _buildStepHeader(),
          const SizedBox(height: 24),
          
          // Configuración del modo
          _buildModeSelection(),
          const SizedBox(height: 24),
          
          // Configuración del tipo de negocio
          _buildBusinessTypeSelection(),
          const SizedBox(height: 24),
          
          
          const Spacer(),
          
          // Botones de navegación
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.gear,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Configuración Inicial',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Configura el modo de cálculo y el tipo de negocio para personalizar la experiencia',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modo de Cálculo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildModeOption(
                title: 'Modo Simple',
                description: 'Solo información básica y precio',
                icon: FontAwesomeIcons.bolt,
                isSelected: !_config.modoAvanzado,
                onTap: () => _updateMode(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModeOption(
                title: 'Modo Avanzado',
                description: 'Cálculo completo de costos',
                icon: FontAwesomeIcons.cogs,
                isSelected: _config.modoAvanzado,
                onTap: () => _updateMode(true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeOption({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedCard(
      delay: const Duration(milliseconds: 100),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? AppTheme.primaryColor
                    : AppTheme.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FaIcon(
                    icon,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected 
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Negocio',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CalculadoraConfig.tiposNegocio.map((tipo) {
            final isSelected = _config.tipoNegocio == tipo['id'];
            return _buildBusinessTypeOption(
              tipo: tipo,
              isSelected: isSelected,
              onTap: () => _updateBusinessType(tipo['id']),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBusinessTypeOption({
    required Map<String, dynamic> tipo,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedCard(
      delay: Duration(milliseconds: 100 + (CalculadoraConfig.tiposNegocio.indexOf(tipo) * 50)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                    ? AppTheme.primaryColor
                    : AppTheme.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tipo['icono'],
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  tipo['nombre'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected 
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }




  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(), // Espacio para alinear a la derecha
        AnimatedButton(
          text: 'Continuar',
          type: ButtonType.primary,
          onPressed: _canContinue() ? _continue : null,
          icon: FontAwesomeIcons.arrowRight,
          delay: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  bool _canContinue() {
    return _config.tipoNegocio.isNotEmpty;
  }

  Future<void> _updateMode(bool modoAvanzado) async {
    setState(() {
      _config = _config.copyWith(modoAvanzado: modoAvanzado);
    });
    await _saveConfig();
  }

  Future<void> _updateBusinessType(String tipoNegocio) async {
    setState(() {
      _config = _config.copyWith(tipoNegocio: tipoNegocio);
    });
    await _saveConfig();
  }


  Future<void> _saveConfig() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.calculadoraService.updateConfig(_config);
      widget.onConfigChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando configuración: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _continue() async {
    if (_canContinue()) {
      await widget.calculadoraService.nextStep();
      widget.onConfigChanged();
    }
  }

}
