import 'package:flutter/material.dart';
import 'package:stockcito/config/app_theme.dart';
import 'package:stockcito/models/search_result.dart';

/// Widget para mostrar resultados de búsqueda agrupados por tipo
class SearchResultsWidget extends StatelessWidget {
  final List<SearchResult> results;
  final Function(SearchResult)? onResultSelected;
  final int maxResultsPerType;

  const SearchResultsWidget({
    super.key,
    required this.results,
    this.onResultSelected,
    this.maxResultsPerType = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    // Agrupar resultados por tipo
    final Map<String, List<SearchResult>> groupedResults = {};
    for (final result in results) {
      groupedResults.putIfAbsent(result.type, () => []).add(result);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header con contador de resultados
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${results.length} resultado${results.length != 1 ? 's' : ''} encontrado${results.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Resultados agrupados
        ...groupedResults.entries.map((entry) {
          final type = entry.key;
          final typeResults = entry.value.take(maxResultsPerType).toList();
          
          return _buildResultGroup(context, type, typeResults);
        }).toList(),

        // Ver más si hay muchos resultados
        if (results.length > maxResultsPerType * groupedResults.length)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Text(
              'Ver más resultados...',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultGroup(BuildContext context, String type, List<SearchResult> typeResults) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header del tipo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _getTypeColor(type).withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.borderColor.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getTypeIcon(type),
                size: 14,
                color: _getTypeColor(type),
              ),
              const SizedBox(width: 8),
              Text(
                _getTypeLabel(type),
                style: TextStyle(
                  fontSize: 12,
                  color: _getTypeColor(type),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${typeResults.length}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Resultados del tipo
        ...typeResults.map((result) => _buildResultItem(context, result)).toList(),
      ],
    );
  }

  Widget _buildResultItem(BuildContext context, SearchResult result) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onResultSelected?.call(result),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppTheme.borderColor.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Icono del tipo
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getTypeColor(result.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getTypeColor(result.type).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getTypeIcon(result.type),
                  size: 16,
                  color: _getTypeColor(result.type),
                ),
              ),
              const SizedBox(width: 12),

              // Contenido del resultado
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      result.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Subtítulo
                    Text(
                      result.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Campos coincidentes
                    if (result.matchedFields.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: result.matchedFields.take(3).map((field) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTypeColor(result.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getFieldLabel(field),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getTypeColor(result.type),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Indicador de relevancia
              if (result.relevanceScore > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(result.relevanceScore * 10).round()}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'producto':
        return AppTheme.primaryColor;
      case 'venta':
        return AppTheme.successColor;
      case 'cliente':
        return AppTheme.infoColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'producto':
        return Icons.inventory_2_outlined;
      case 'venta':
        return Icons.shopping_cart_outlined;
      case 'cliente':
        return Icons.person_outline;
      default:
        return Icons.search;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'producto':
        return 'Productos';
      case 'venta':
        return 'Ventas';
      case 'cliente':
        return 'Clientes';
      default:
        return 'Otros';
    }
  }

  String _getFieldLabel(String field) {
    switch (field) {
      case 'nombre':
        return 'Nombre';
      case 'categoria':
        return 'Categoría';
      case 'talla':
        return 'Talla';
      case 'cliente':
        return 'Cliente';
      case 'estado':
        return 'Estado';
      case 'metodoPago':
        return 'Pago';
      case 'telefono':
        return 'Teléfono';
      case 'email':
        return 'Email';
      default:
        return field;
    }
  }
}
