import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';

class CalculoPrecioTabBar extends StatelessWidget {
  final TabController tabController;

  const CalculoPrecioTabBar({
    super.key,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: TabBar(
        controller: tabController,
        indicatorColor: AppTheme.primaryColor,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(
            icon: FaIcon(FontAwesomeIcons.circleInfo, size: 20),
            text: 'Producto',
          ),
          Tab(
            icon: FaIcon(FontAwesomeIcons.boxesStacked, size: 20),
            text: 'Materiales',
          ),
          Tab(
            icon: FaIcon(FontAwesomeIcons.hammer, size: 20),
            text: 'Producción',
          ),
          Tab(
            icon: FaIcon(FontAwesomeIcons.house, size: 20),
            text: 'Costos Fijos',
          ),
          Tab(
            icon: FaIcon(FontAwesomeIcons.chartLine, size: 20),
            text: 'Resultado',
          ),
        ],
      ),
    );
  }
}
