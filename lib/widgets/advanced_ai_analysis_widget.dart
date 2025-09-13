import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/ai/advanced_ai_analysis_service.dart';

class AdvancedAIAnalysisWidget extends StatefulWidget {
  const AdvancedAIAnalysisWidget({super.key});

  @override
  State<AdvancedAIAnalysisWidget> createState() => _AdvancedAIAnalysisWidgetState();
}

class _AdvancedAIAnalysisWidgetState extends State<AdvancedAIAnalysisWidget> {
  final AdvancedAIAnalysisService _analysisService = AdvancedAIAnalysisService();
  bool _isLoading = false;
  
  SeasonalAnalysis? _seasonalTrends;
  ProfitabilityAnalysis? _profitability;
  PurchasePatternAnalysis? _patterns;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _analysisService.analyzeSeasonalTrends(),
        _analysisService.analyzeProductProfitability(),
        _analysisService.detectPurchasePatterns(),
      ]);
      
      if (mounted) {
        setState(() {
          _seasonalTrends = results[0] as SeasonalAnalysis?;
          _profitability = results[1] as ProfitabilityAnalysis?;
          _patterns = results[2] as PurchasePatternAnalysis?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60, // Altura aumentada para mejor visualización
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: _isLoading
          ? const Center(
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1),
              ),
            )
          : _buildSimpleContent(),
    );
  }

  Widget _buildSimpleContent() {
    return Row(
      children: [
        Icon(
          FontAwesomeIcons.brain,
          color: Colors.blue,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'IA: ${_getBestInsight()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getBestInsight() {
    if (_seasonalTrends != null) {
      return 'Mejor día: ${_seasonalTrends!.bestDay}';
    } else if (_profitability != null && _profitability!.topProducts.isNotEmpty) {
      return 'Top: ${_profitability!.topProducts.first.producto.nombre}';
    } else if (_patterns != null) {
      final bestCategory = _patterns!.categoryPatterns.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      return 'Top: ${bestCategory.key}';
    }
    return 'Cargando...';
  }
}