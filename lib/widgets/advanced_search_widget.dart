import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_theme.dart';

class AdvancedSearchWidget extends StatefulWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final Function(Map<String, dynamic>) onFiltersChanged;
  final List<String> categories;
  final List<String> sizes;
  final bool showStockFilter;
  final bool showPriceFilter;

  const AdvancedSearchWidget({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFiltersChanged,
    this.categories = const [],
    this.sizes = const [],
    this.showStockFilter = true,
    this.showPriceFilter = true,
  });

  @override
  State<AdvancedSearchWidget> createState() => _AdvancedSearchWidgetState();
}

class _AdvancedSearchWidgetState extends State<AdvancedSearchWidget> {
  bool _showFilters = false;
  String _selectedCategory = 'Todas';
  String _selectedSize = 'Todas';
  bool _showOnlyLowStock = false;
  double _minPrice = 0;
  double _maxPrice = 1000;
  bool _priceRangeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de búsqueda principal
        Container(
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
          child: TextField(
            controller: widget.searchController,
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              prefixIcon: const FaIcon(
                FontAwesomeIcons.magnifyingGlass,
                color: AppTheme.primaryColor,
                size: 18,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.searchController.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        widget.searchController.clear();
                        widget.onSearchChanged('');
                      },
                      icon: const FaIcon(
                        FontAwesomeIcons.xmark,
                        color: AppTheme.textSecondary,
                        size: 16,
                      ),
                    ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                    icon: FaIcon(
                      _showFilters ? FontAwesomeIcons.filter : FontAwesomeIcons.filter,
                      color: _showFilters ? AppTheme.primaryColor : AppTheme.textSecondary,
                      size: 18,
                    ),
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),

        // Panel de filtros desplegable
        if (_showFilters) ...[
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header de filtros
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.filter,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Filtros Avanzados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text(
                          'Limpiar',
                          style: TextStyle(color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Filtros en grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.5,
                    children: [
                      // Filtro por categoría
                      if (widget.categories.isNotEmpty)
                        _buildFilterCard(
                          'Categoría',
                          FontAwesomeIcons.tag,
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              items: ['Todas', ...widget.categories].map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value ?? 'Todas';
                                });
                                _applyFilters();
                              },
                            ),
                          ),
                        ),

                      // Filtro por talla
                      if (widget.sizes.isNotEmpty)
                        _buildFilterCard(
                          'Talla',
                          FontAwesomeIcons.ruler,
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSize,
                              isExpanded: true,
                              items: ['Todas', ...widget.sizes].map((size) {
                                return DropdownMenuItem<String>(
                                  value: size,
                                  child: Text(size),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSize = value ?? 'Todas';
                                });
                                _applyFilters();
                              },
                            ),
                          ),
                        ),

                      // Filtro de stock bajo
                      if (widget.showStockFilter)
                        _buildFilterCard(
                          'Stock Bajo',
                          FontAwesomeIcons.triangleExclamation,
                          Switch(
                            value: _showOnlyLowStock,
                            onChanged: (value) {
                              setState(() {
                                _showOnlyLowStock = value;
                              });
                              _applyFilters();
                            },
                            activeColor: AppTheme.warningColor,
                          ),
                        ),

                      // Filtro de rango de precios
                      if (widget.showPriceFilter)
                        _buildFilterCard(
                          'Rango de Precios',
                          FontAwesomeIcons.dollarSign,
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Mín',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        _minPrice = double.tryParse(value) ?? 0;
                                        _applyFilters();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(' - '),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Máx',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        _maxPrice = double.tryParse(value) ?? 1000;
                                        _applyFilters();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _applyFilters,
                          icon: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 16),
                          label: const Text('Aplicar Filtros'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clearFilters,
                          icon: const FaIcon(FontAwesomeIcons.trashCan, size: 16),
                          label: const Text('Limpiar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: const BorderSide(color: AppTheme.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterCard(String title, IconData icon, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                icon,
                size: 14,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }

  void _applyFilters() {
    final filters = {
      'category': _selectedCategory,
      'size': _selectedSize,
      'showOnlyLowStock': _showOnlyLowStock,
      'minPrice': _minPrice,
      'maxPrice': _maxPrice,
      'priceRangeEnabled': _priceRangeEnabled,
    };
    widget.onFiltersChanged(filters);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'Todas';
      _selectedSize = 'Todas';
      _showOnlyLowStock = false;
      _minPrice = 0;
      _maxPrice = 1000;
      _priceRangeEnabled = false;
    });
    _applyFilters();
  }
}
