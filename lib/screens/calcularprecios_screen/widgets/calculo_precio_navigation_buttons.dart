import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../widgets/animated_widgets.dart';

class CalculoPrecioNavigationButtons extends StatelessWidget {
  final int currentIndex;
  final TabController tabController;

  const CalculoPrecioNavigationButtons({
    super.key,
    required this.currentIndex,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (currentIndex > 0)
          AnimatedButton(
            text: 'Anterior',
            type: ButtonType.secondary,
            onPressed: () => tabController.animateTo(tabController.index - 1),
            icon: FontAwesomeIcons.arrowLeft,
            delay: const Duration(milliseconds: 100),
          ),
        const Spacer(),
        if (currentIndex < 4)
          AnimatedButton(
            text: 'Siguiente',
            type: ButtonType.primary,
            onPressed: () => tabController.animateTo(tabController.index + 1),
            icon: FontAwesomeIcons.arrowRight,
            delay: const Duration(milliseconds: 200),
          ),
      ],
    );
  }
}
