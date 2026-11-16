import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_colors_extra.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';

/// Page-level building blocks shared by every owner page, so titles,
/// search bars, filter chips, menu lists, switches and steppers look the
/// same everywhere. Use these instead of drawing new variants per page.

/// Big page title with an optional badge on the right of the title and a
/// grey subtitle line ("Staff · 14 Members", "Settings").
class PageTitle extends StatelessWidget {
  const PageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.trailing,
  });

  final String title;
  final String? subtitle;

  /// Shown right after the title (e.g. a count pill).
  final Widget? badge;

  /// Pushed to the far right of the title row.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            if (badge != null) ...[SizedBox(width: 10.w), badge!],
            if (trailing != null) ...[
              SizedBox(width: 8.w),
              const Spacer(),
              trailing!,
            ],
          ],
        ),
        if (subtitle != null) ...[
          SizedBox(height: 4.h),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 12.5.sp,
              color: AppColors.textDark.withValues(alpha: 0.75),
            ),
          ),
        ],
      ],
    );
  }
}

/// White search field with a filter (tune) button on the right.
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.hint,
    required this.onChanged,
    this.onFilterTap,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      padding: EdgeInsets.only(left: 14.w, right: 8.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.small,
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 22.sp, color: AppColors.grey),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textDark),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.greyLight,
                ),
              ),
            ),
          ),
          if (onFilterTap != null)
            GestureDetector(
              onTap: onFilterTap,
              child: Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: AppColorsExtra.panelGrey,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.tune, size: 18.sp, color: AppColors.grey),
              ),
            ),
        ],
      ),
    );
  }
}

/// One chip of a [FilterChipBar].
class FilterOption {
  const FilterOption(this.label, {this.count});

  final String label;
  final int? count;
}

/// Horizontal row of filter chips. The selected chip is filled primary
/// blue; others are white with a border.
class FilterChipBar extends StatelessWidget {
  const FilterChipBar({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<FilterOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final o = options[i];
          final active = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.primaryBlue : AppColors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: active ? AppColors.primaryBlue : AppColors.border,
                ),
              ),
              child: Text(
                o.count == null ? o.label : '${o.label} (${o.count})',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.white : AppColors.textDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Section heading above a group of cards ("Business", "People").
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 10.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Light-blue rounded square holding an icon (menu rows, card headers).
class IconBox extends StatelessWidget {
  const IconBox(
    this.icon, {
    super.key,
    this.size = 42,
    this.bg = AppColors.lightBlue,
    this.fg = AppColors.deepBlue,
  });

  final IconData icon;
  final double size;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular((size * 0.3).r),
      ),
      child: Icon(icon, size: (size * 0.5).sp, color: fg),
    );
  }
}

/// One row of a [MenuGroup]: icon box, title (+ optional badge), subtitle,
/// optional trailing widget, chevron.
class MenuTile {
  const MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badge,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  /// Small pill next to the title.
  final Widget? badge;

  /// Widget before the chevron (e.g. a "3 pending" pill).
  final Widget? trailing;
}

/// White card holding several [MenuTile] rows separated by dividers.
class MenuGroup extends StatelessWidget {
  const MenuGroup({super.key, required this.tiles});

  final List<MenuTile> tiles;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 14.w,
                endIndent: 14.w,
                color: AppColorsExtra.panelBorder,
              ),
            _row(tiles[i], i == 0, i == tiles.length - 1),
          ],
        ],
      ),
    );
  }

  Widget _row(MenuTile t, bool first, bool last) {
    return InkWell(
      onTap: t.onTap,
      borderRadius: BorderRadius.vertical(
        top: first ? Radius.circular(20.r) : Radius.zero,
        bottom: last ? Radius.circular(20.r) : Radius.zero,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        child: Row(
          children: [
            IconBox(t.icon),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        t.title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (t.badge != null) t.badge!,
                    ],
                  ),
                  if (t.subtitle != null) ...[
                    SizedBox(height: 3.h),
                    Text(
                      t.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.3,
                        color: AppColors.textDark.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (t.trailing != null) ...[SizedBox(width: 8.w), t.trailing!],
            SizedBox(width: 4.w),
            Icon(Icons.chevron_right, size: 22.sp, color: AppColors.greyLight),
          ],
        ),
      ),
    );
  }
}

/// Blue / grey toggle used on every owner page.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      thumbColor: WidgetStateProperty.all(AppColors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryBlue
            : const Color(0xFFCBD5E1),
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}

/// Title + helper text on the left, [AppSwitch] on the right.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 2.h),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.3,
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: 10.w),
        AppSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}

/// − value + stepper with quick preset chips underneath.
class ValueStepper extends StatelessWidget {
  const ValueStepper({
    super.key,
    required this.current,
    required this.value,
    required this.unit,
    required this.onMinus,
    required this.onPlus,
    this.presets = const [],
    this.presetLabel,
    this.onPreset,
  });

  /// Current numeric value; highlights the matching preset.
  final num current;

  /// Formatted value ("$150.00", "10%").
  final String value;

  /// Small caption after the value ("CAD", "LIMIT").
  final String unit;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  /// Preset values; the one equal to the current value is highlighted.
  final List<num> presets;
  final String Function(num)? presetLabel;
  final void Function(num)? onPreset;

  @override
  Widget build(BuildContext context) {
    Widget roundButton(IconData icon, VoidCallback onTap) => Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColorsExtra.panelBorder),
          ),
          child: Icon(icon, size: 20.sp, color: AppColors.deepBlue),
        ),
      ),
    );

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: AppColorsExtra.panelGrey,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColorsExtra.panelBorder),
          ),
          child: Row(
            children: [
              roundButton(Icons.remove, onMinus),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepBlue,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              roundButton(Icons.add, onPlus),
            ],
          ),
        ),
        if (presets.isNotEmpty) ...[
          SizedBox(height: 10.h),
          Row(
            children: [
              for (var i = 0; i < presets.length; i++) ...[
                if (i > 0) SizedBox(width: 8.w),
                Expanded(child: _preset(presets[i])),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _preset(num p) {
    final label = presetLabel?.call(p) ?? '$p';
    final selected = p == current;
    return GestureDetector(
      onTap: () => onPreset?.call(p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.deepBlue : AppColorsExtra.panelGrey,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: selected ? AppColors.deepBlue : AppColorsExtra.panelBorder,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.white : AppColors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Blue info banner with a round icon ("Changes apply instantly...").
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.child, this.icon = Icons.bolt});

  final Widget child;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColorsExtra.infoBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsExtra.infoBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18.sp, color: AppColors.primaryBlue),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.4,
                color: AppColors.textDark,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Amber warning note ("Includes sensitive financial data...").
class WarningNote extends StatelessWidget {
  const WarningNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsExtra.warningSoft,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColorsExtra.warningBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.gpp_maybe_outlined,
            size: 17.sp,
            color: AppColorsExtra.amber,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.sp,
                height: 1.35,
                color: AppColorsExtra.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable card row with an icon box, title, subtitle and radio dot
/// (Export datasets). Selected = primary border + light blue fill.
class SelectCard extends StatelessWidget {
  const SelectCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: selected ? AppColorsExtra.infoBg : AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.border,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            IconBox(
              icon,
              size: 38,
              bg: selected ? AppColors.primaryBlue : AppColorsExtra.panelGrey,
              fg: selected ? AppColors.white : AppColors.textDark,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? AppColors.primaryBlue
                          : AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textDark.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

/// Small pill that opens a menu of options ("All Users ▾", "Date: Today ▾").
class MenuPill<T> extends StatelessWidget {
  const MenuPill({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
    this.selected,
    this.icon,
  });

  final String label;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onSelected;
  final T? selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      itemBuilder: (_) => [
        for (final it in items)
          PopupMenuItem<T>(
            value: it,
            child: Text(
              itemLabel(it),
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: it == selected ? FontWeight.w800 : FontWeight.w600,
                color: it == selected
                    ? AppColors.primaryBlue
                    : AppColors.textDark,
              ),
            ),
          ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: AppColorsExtra.panelGrey,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColorsExtra.panelBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15.sp, color: AppColors.deepBlue),
              SizedBox(width: 5.w),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 18.sp, color: AppColors.textDark),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet confirmation used everywhere instead of a Material dialog.
/// Returns true when the owner confirms.
Future<bool> showConfirmSheet({
  required String title,
  required String message,
  required String confirmLabel,
  IconData icon = Icons.help_outline,
  bool danger = false,
}) async {
  final color = danger ? AppColors.danger : AppColors.primaryBlue;
  final result = await Get.bottomSheet<bool>(
    SheetFrame(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: Material(
              color: color,
              borderRadius: BorderRadius.circular(16.r),
              child: InkWell(
                onTap: () => Get.back(result: true),
                borderRadius: BorderRadius.circular(16.r),
                child: SizedBox(
                  height: 52.h,
                  child: Center(
                    child: Text(
                      confirmLabel,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: SoftButton(
              label: 'Cancel',
              height: 50,
              radius: 16,
              fontSize: 14.5,
              onTap: () => Get.back(result: false),
            ),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              color: danger ? AppColors.dangerBg : AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22.sp, color: color),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    height: 1.4,
                    color: AppColors.textDark.withValues(alpha: 0.75),
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ],
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
  );
  return result ?? false;
}
