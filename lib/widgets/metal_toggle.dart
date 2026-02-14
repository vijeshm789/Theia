import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

class MetalToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const MetalToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTab(AppConstants.gold, AppTheme.primaryGold),
          _buildTab(AppConstants.silver, AppTheme.secondarySilver),
        ],
      ),
    );
  }

  Widget _buildTab(String metal, Color accentColor) {
    final isSelected = selected == metal;
    return GestureDetector(
      onTap: () => onChanged(metal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: accentColor.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Text(
          metal,
          style: TextStyle(
            color: isSelected ? accentColor : AppTheme.textMuted,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class TimeRangeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const TimeRangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: AppConstants.chartTimeFilters.map((filter) {
        final isSelected = selected == filter;
        return GestureDetector(
          onTap: () => onChanged(filter),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryGold.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(
                      color: AppTheme.primaryGold.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Text(
              filter,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryGold : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PredictionWindowSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const PredictionWindowSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: AppConstants.predictionWindows.map((window) {
        final isSelected = selected == window;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(window),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGold.withOpacity(0.15)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(
                        color: AppTheme.primaryGold.withOpacity(0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Text(
                window,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryGold : AppTheme.textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
