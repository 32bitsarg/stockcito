import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'modern_card_widget.dart';
import '../../../services/ml/personalization_service.dart';
import '../../../services/ml/feedback_service.dart';
import '../../../services/datos/datos.dart';
import '../../../services/system/logging_service.dart';
import '../ml/ml_educational_message_widget.dart';
import '../../../services/ml/ml_data_validation_service.dart';

/// Widget para recomendaciones de IA con predicciones reales y feedback
class MLRecommendationsWidget extends StatefulWidget {
  const MLRecommendationsWidget({Key? key}) : super(key: key);

  @override
  State<MLRecommendationsWidget> createState() => _MLRecommendationsWidgetState();
}

class _MLRecommendationsWidgetState extends State<MLRecommendationsWidget> {
  final PersonalizationService _personalizationService = PersonalizationService();
  final FeedbackService _feedbackService = FeedbackService();
  final DatosService _datosService = DatosService();
  final MLDataValidationService _validationService = MLDataValidationService();

  List<MLRecommendation> _recommendations = [];
  bool _isLoading = true;
  String _error = '';
  MLInsights? _insights;
  
  // Estado para tracking de feedback
  Map<String, bool> _feedbackGiven = {}; // ID -> ya dio feedback
  bool _hasPendingUndo = false;
  Duration? _remainingUndoTime;
  
  // Estado para mensajes educativos
  bool _showEducationalMessage = false;
  MLValidationErrorType? _validationErrorType;
  int? _requiredData;
  int? _currentData;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // Obtener datos
      final productos = await _datosService.getAllProductos();
      final ventas = await _datosService.getAllVentas();
      final clientes = await _datosService.getAllClientes();

      // Validar datos antes de generar recomendaciones
      final demandValidation = _validationService.validateDemandTrainingData(ventas, productos);
      final priceValidation = _validationService.validatePriceTrainingData(ventas, productos);
      final customerValidation = _validationService.validateCustomerSegmentationData(ventas, clientes);

      // Determinar si mostrar mensaje educativo
      bool showEducationalMessage = false;
      MLValidationErrorType? errorType;
      int? requiredData;
      int? currentData;

      if (!demandValidation.isValid) {
        showEducationalMessage = true;
        errorType = demandValidation.errorType;
        requiredData = demandValidation.requiredData;
        currentData = demandValidation.currentData;
      } else if (!priceValidation.isValid) {
        showEducationalMessage = true;
        errorType = priceValidation.errorType;
        requiredData = priceValidation.requiredData;
        currentData = priceValidation.currentData;
      } else if (!customerValidation.isValid) {
        showEducationalMessage = true;
        errorType = customerValidation.errorType;
        requiredData = customerValidation.requiredData;
        currentData = customerValidation.currentData;
      }

      // Generar recomendaciones personalizadas
      final recommendations = await _personalizationService.generatePersonalizedRecommendations(
        productos: productos,
        ventas: ventas,
        clientes: clientes,
      );

      // Cargar estado de feedback para cada recomendación
      final feedbackState = <String, bool>{};
      for (final recommendation in recommendations) {
        final hasGivenFeedback = await _feedbackService.hasUserGivenFeedback(recommendation);
        feedbackState[recommendation.id] = hasGivenFeedback;
      }

      // Verificar si hay feedback pendiente de deshacer
      final hasPendingUndo = await _feedbackService.hasPendingUndo();
      final remainingUndoTime = await _feedbackService.getRemainingUndoTime();

      // Generar insights
      final insights = await _personalizationService.generatePersonalizedInsights(
        productos: productos,
        ventas: ventas,
        clientes: clientes,
      );

      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _feedbackGiven = feedbackState;
          _hasPendingUndo = hasPendingUndo;
          _remainingUndoTime = remainingUndoTime;
          _insights = insights;
          _showEducationalMessage = showEducationalMessage;
          _validationErrorType = errorType;
          _requiredData = requiredData;
          _currentData = currentData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error cargando recomendaciones: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título y botón de refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recomendaciones IA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              Row(
                children: [
                  // Botón de refresh
                  GestureDetector(
                    onTap: _loadRecommendations,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.arrowsRotate,
                        size: 12,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Icono de IA
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF88).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.robot,
                      size: 12,
                      color: Color(0xFF00FF88),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Contenido principal
          if (_isLoading)
            _buildLoadingState()
          else if (_error.isNotEmpty)
            _buildErrorState()
          else if (_recommendations.isEmpty)
            _buildEmptyState()
          else
            _buildRecommendationsList(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        children: [
          CircularProgressIndicator(
            color: Color(0xFF00FF88),
            strokeWidth: 2,
          ),
          SizedBox(height: 8),
          Text(
            'Generando recomendaciones...',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            FontAwesomeIcons.triangleExclamation,
            color: Color(0xFFEF4444),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6B7280).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          Icon(
            FontAwesomeIcons.lightbulb,
            color: Color(0xFF6B7280),
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            'No hay recomendaciones disponibles',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Agrega más datos para obtener recomendaciones personalizadas',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList() {
    return Column(
      children: [
        // Mostrar mensaje educativo si es necesario
        if (_showEducationalMessage)
          MLEducationalMessageWidget(
            errorType: _validationErrorType,
            requiredData: _requiredData,
            currentData: _currentData,
            onActionPressed: () {
              // Aquí podrías navegar a la pantalla de agregar datos
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navega a Inventario, Ventas o Clientes para agregar datos'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        
        // Mostrar insights si están disponibles
        if (_insights != null && _insights!.insights.isNotEmpty)
          _buildInsightsSection(),
        
        const SizedBox(height: 16),
        
        // Lista de recomendaciones
        ..._recommendations.take(5).map((recommendation) => 
          _buildRecommendationItem(recommendation)
        ).toList(),
        
        // Botón de deshacer si hay feedback pendiente
        if (_hasPendingUndo) _buildUndoButton(),
      ],
    );
  }

  Widget _buildInsightsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                FontAwesomeIcons.chartLine,
                color: Color(0xFF3B82F6),
                size: 14,
              ),
              const SizedBox(width: 6),
              const Text(
                'Insights',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _insights!.insights.first,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF2D2D2D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(MLRecommendation recommendation) {
    // Determinar colores basados en el tipo y prioridad
    Color iconColor;
    Color statusColor;
    Color statusBgColor;
    IconData icon;
    String status;

    switch (recommendation.type) {
      case RecommendationType.demand:
        iconColor = const Color(0xFFF59E0B);
        icon = FontAwesomeIcons.boxesStacked;
        break;
      case RecommendationType.pricing:
        iconColor = const Color(0xFF10B981);
        icon = FontAwesomeIcons.dollarSign;
        break;
      case RecommendationType.customer:
        iconColor = const Color(0xFF3B82F6);
        icon = FontAwesomeIcons.users;
        break;
    }

    // Determinar estado basado en prioridad y confianza
    if (recommendation.priority > 80 && recommendation.confidence > 0.8) {
      status = 'Urgente';
      statusColor = const Color(0xFFEF4444);
      statusBgColor = const Color(0xFFEF4444).withOpacity(0.1);
    } else if (recommendation.priority > 60 && recommendation.confidence > 0.6) {
      status = 'Importante';
      statusColor = const Color(0xFF10B981);
      statusBgColor = const Color(0xFF10B981).withOpacity(0.1);
    } else {
      status = 'Nueva';
      statusColor = const Color(0xFFF59E0B);
      statusBgColor = const Color(0xFFF59E0B).withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Icono de la recomendación
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Contenido de la recomendación
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                Text(
                  recommendation.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Barra de confianza
                Row(
                  children: [
                    const Text(
                      'Confianza: ',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: recommendation.confidence,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          recommendation.confidence > 0.7 
                              ? const Color(0xFF10B981)
                              : recommendation.confidence > 0.5
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(recommendation.confidence * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Estado y botones de acción
          Column(
            children: [
              // Estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Botones de feedback
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón de like
                  _buildFeedbackButton(
                    recommendation: recommendation,
                    isPositive: true,
                    isEnabled: !(_feedbackGiven[recommendation.id] ?? false),
                  ),
                  const SizedBox(width: 4),
                  // Botón de dislike
                  _buildFeedbackButton(
                    recommendation: recommendation,
                    isPositive: false,
                    isEnabled: !(_feedbackGiven[recommendation.id] ?? false),
                  ),
                  // Indicador de estado si ya dio feedback
                  if (_feedbackGiven[recommendation.id] ?? false) ...[
                    const SizedBox(width: 8),
                    _buildFeedbackStatusIndicator(),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _recordFeedback(MLRecommendation recommendation, bool isPositive) async {
    try {
      // Usar el nuevo sistema de feedback único
      final success = await _feedbackService.recordUniqueFeedback(
        recommendation: recommendation,
        isPositive: isPositive,
      );

      if (success && mounted) {
        // Actualizar estado local
        setState(() {
          _feedbackGiven[recommendation.id] = true;
          _hasPendingUndo = true;
          _remainingUndoTime = const Duration(seconds: 30);
        });

        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPositive 
                  ? 'Gracias por tu feedback positivo' 
                  : 'Gracias por tu feedback. Mejoraremos las recomendaciones.',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: isPositive 
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B),
          ),
        );

        // Iniciar timer para actualizar tiempo restante
        _startUndoTimer();
      } else if (!success) {
        // Mostrar mensaje si ya dio feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya evaluaste esta recomendación'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF6B7280),
          ),
        );
      }
    } catch (e) {
      LoggingService.error('Error registrando feedback: $e');
    }
  }

  /// Inicia el timer para actualizar el tiempo restante de deshacer
  void _startUndoTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _hasPendingUndo) {
        _feedbackService.getRemainingUndoTime().then((remainingTime) {
          if (mounted) {
            setState(() {
              _remainingUndoTime = remainingTime;
              _hasPendingUndo = remainingTime != null;
            });
            
            if (_hasPendingUndo) {
              _startUndoTimer(); // Continuar el timer
            }
          }
        });
      }
    });
  }

  /// Construye un botón de feedback (like/dislike) con estado visual sutil
  Widget _buildFeedbackButton({
    required MLRecommendation recommendation,
    required bool isPositive,
    required bool isEnabled,
  }) {
    final color = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final icon = isPositive ? FontAwesomeIcons.thumbsUp : FontAwesomeIcons.thumbsDown;
    
    return GestureDetector(
      onTap: isEnabled ? () => _recordFeedback(recommendation, isPositive) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isEnabled 
              ? color.withOpacity(0.1) 
              : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
          border: isEnabled 
              ? null 
              : Border.all(color: color.withOpacity(0.2), width: 0.5),
        ),
        child: Icon(
          icon,
          size: 10,
          color: isEnabled 
              ? color 
              : color.withOpacity(0.4),
        ),
      ),
    );
  }

  /// Construye un indicador sutil de que ya se dio feedback
  Widget _buildFeedbackStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF6B7280).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FontAwesomeIcons.check,
            size: 8,
            color: const Color(0xFF6B7280).withOpacity(0.7),
          ),
          const SizedBox(width: 2),
          Text(
            'Evaluado',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el botón de deshacer si hay feedback pendiente
  Widget _buildUndoButton() {
    if (!_hasPendingUndo || _remainingUndoTime == null) {
      return const SizedBox.shrink();
    }

    final secondsLeft = _remainingUndoTime!.inSeconds;
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: _undoLastFeedback,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                FontAwesomeIcons.undo,
                size: 8,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 4),
              Text(
                'Deshacer (${secondsLeft}s)',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Deshace el último feedback dado
  Future<void> _undoLastFeedback() async {
    try {
      final success = await _feedbackService.undoLastFeedback();
      if (success && mounted) {
        // Recargar recomendaciones para actualizar estado
        await _loadRecommendations();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback deshecho correctamente'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      LoggingService.error('Error deshaciendo feedback: $e');
    }
  }
}
