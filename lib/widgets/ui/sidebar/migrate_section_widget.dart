import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../services/system/logging_service.dart';
import '../../../services/system/service_manager.dart';
import '../dashboard/modern_card_widget.dart';
import '../auth/user_conversion_modal.dart';

/// Widget que muestra la sección de migración para usuarios anónimos
class MigrateSectionWidget extends StatefulWidget {
  const MigrateSectionWidget({super.key});

  @override
  State<MigrateSectionWidget> createState() => _MigrateSectionWidgetState();
}

class _MigrateSectionWidgetState extends State<MigrateSectionWidget> {
  final ServiceManager _serviceManager = ServiceManager();
  
  bool _isCheckingMigration = false;
  bool _canMigrate = false;
  String? _migrationStatus;

  @override
  void initState() {
    super.initState();
    _checkMigrationStatus();
  }

  Future<void> _checkMigrationStatus() async {
    final authService = _serviceManager.authService;
    final migrationService = _serviceManager.userMigrationService;
    
    if (authService == null || migrationService == null) {
      setState(() {
        _canMigrate = false;
        _migrationStatus = 'Servicios no inicializados';
        _isCheckingMigration = false;
      });
      return;
    }

    if (!authService.isAnonymous) return;

    setState(() {
      _isCheckingMigration = true;
    });

    try {
      LoggingService.info('🔍 Verificando estado de migración...');
      
      final validation = await migrationService.validateConversion();
      
      setState(() {
        _canMigrate = validation.isValid;
        _migrationStatus = validation.warning ?? validation.error;
        _isCheckingMigration = false;
      });
    } catch (e) {
      LoggingService.error('❌ Error verificando migración: $e');
      setState(() {
        _canMigrate = false;
        _migrationStatus = 'Error verificando migración';
        _isCheckingMigration = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = _serviceManager.authService;
    
    // Solo mostrar si el usuario es anónimo
    if (authService == null || !authService.isAnonymous) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ModernCardWidget(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildContent(),
            const SizedBox(height: 12),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF3C096C).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            FontAwesomeIcons.userPlus,
            color: Color(0xFF3C096C),
            size: 14,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crear Cuenta',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3C096C),
                ),
              ),
              Text(
                'Migra tus datos',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        if (_isCheckingMigration)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3C096C)),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isCheckingMigration) {
      return const Text(
        'Verificando datos...',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
        ),
      );
    }

    if (!_canMigrate) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No hay datos para migrar',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          if (_migrationStatus != null) ...[
            const SizedBox(height: 2),
            Text(
              _migrationStatus!,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ],
      );
    }

    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tienes datos guardados localmente',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Crea una cuenta para sincronizar tus datos en la nube',
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (_isCheckingMigration) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canMigrate ? _showConversionModal : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _canMigrate ? const Color(0xFF3C096C) : Colors.grey[300],
          foregroundColor: _canMigrate ? Colors.white : Colors.grey[600],
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FontAwesomeIcons.arrowRight, size: 12),
            const SizedBox(width: 6),
            Text(
              _canMigrate ? 'Crear Cuenta' : 'Sin datos para migrar',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showConversionModal() async {
    try {
      LoggingService.info('🔄 Mostrando modal de conversión...');
      
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const UserConversionModal(),
      );

      if (result == true) {
        // La conversión fue exitosa, actualizar el estado
        setState(() {
          _canMigrate = false;
          _migrationStatus = 'Cuenta creada exitosamente';
        });
        
        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Cuenta creada exitosamente! Tus datos han sido migrados.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      LoggingService.error('❌ Error mostrando modal de conversión: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
