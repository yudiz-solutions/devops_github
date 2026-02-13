import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';

// ─── Text Input ─────────────────────────────────────────────────────
class StyledInput extends StatelessWidget {
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final bool enabled;
  final Widget? suffix;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;

  const StyledInput({
    super.key, this.placeholder, this.onChanged, this.obscureText = false,
    this.enabled = true, this.suffix, this.controller, this.focusNode, this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, focusNode: focusNode, obscureText: obscureText,
      enabled: enabled, onChanged: onChanged, onSubmitted: onSubmitted,
      style: GoogleFonts.jetBrainsMono(fontSize: 13, color: AppColors.textPrimary),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: GoogleFonts.jetBrainsMono(fontSize: 13, color: AppColors.textMuted.withOpacity(0.6)),
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.inputBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.inputBorder.withOpacity(0.4))),
        suffixIcon: suffix,
      ),
    );
  }
}

// ─── Dropdown ───────────────────────────────────────────────────────
class StyledDropdown extends StatelessWidget {
  final String value;
  final List<Map<String, String>> items;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const StyledDropdown({super.key, required this.value, required this.items, required this.onChanged, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1E2A42),
          style: GoogleFonts.jetBrainsMono(fontSize: 13, color: AppColors.textPrimary),
          isExpanded: true,
          icon: const Icon(Icons.unfold_more_rounded, color: AppColors.textMuted, size: 18),
          items: items.map((i) => DropdownMenuItem(value: i['value'], child: Text(i['label']!))).toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

// ─── Button ─────────────────────────────────────────────────────────
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool danger;
  final IconData? icon;
  final bool compact;

  const PrimaryButton({
    super.key, required this.label, this.onPressed, this.loading = false,
    this.danger = false, this.icon, this.compact = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final baseColor = widget.danger ? AppColors.danger : AppColors.primary;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        child: ElevatedButton(
          onPressed: enabled ? widget.onPressed : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? 16 : 24, vertical: widget.compact ? 8 : 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: _hovered && enabled ? baseColor.withOpacity(0.85) : baseColor,
            disabledBackgroundColor: baseColor.withOpacity(0.35),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.loading)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withOpacity(0.8))),
                ),
              if (widget.icon != null && !widget.loading)
                Padding(padding: const EdgeInsets.only(right: 8), child: Icon(widget.icon, size: 16, color: Colors.white)),
              Text(widget.label, style: TextStyle(fontSize: widget.compact ? 12 : 13, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Card ───────────────────────────────────────────────────────────
class StyledCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const StyledCard({super.key, required this.child, this.backgroundColor, this.borderColor, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.only(bottom: 20),
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.card,
        border: Border.all(color: borderColor ?? AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

// ─── Label ──────────────────────────────────────────────────────────
class FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const FieldLabel(this.text, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(text.toUpperCase(),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          if (required)
            const Text(' *', style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── ComboBox (editable + dropdown) ─────────────────────────────────
class ComboBox extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> options;
  final String? placeholder;
  final bool enabled;

  const ComboBox({super.key, required this.value, required this.onChanged, required this.options, this.placeholder, this.enabled = true});

  @override
  State<ComboBox> createState() => _ComboBoxState();
}

class _ComboBoxState extends State<ComboBox> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _link = LayerLink();
  OverlayEntry? _overlay;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.value;
    _focus.addListener(() {
      if (_focus.hasFocus) { _show(); } else { Future.delayed(const Duration(milliseconds: 200), _hide); }
    });
  }

  @override
  void didUpdateWidget(covariant ComboBox old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  List<String> get _filtered {
    final q = _controller.text.toLowerCase();
    return widget.options.where((o) => o.toLowerCase().contains(q)).toList();
  }

  void _show() {
    _hide();
    if (_filtered.isEmpty) return;
    _overlay = OverlayEntry(builder: (_) => Positioned(
      width: 300,
      child: CompositedTransformFollower(
        link: _link, offset: const Offset(0, 50), showWhenUnlinked: false,
        child: Material(
          color: const Color(0xFF1E2A42),
          borderRadius: BorderRadius.circular(8),
          elevation: 12,
          shadowColor: Colors.black54,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView(padding: EdgeInsets.zero, shrinkWrap: true, children: _filtered.map((o) => InkWell(
              onTap: () { widget.onChanged(o); _controller.text = o; _hide(); _focus.unfocus(); },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.5)))),
                child: Text(o, style: GoogleFonts.jetBrainsMono(fontSize: 13, color: AppColors.textSecondary)),
              ),
            )).toList()),
          ),
        ),
      ),
    ));
    Overlay.of(context).insert(_overlay!);
  }

  void _hide() { _overlay?.remove(); _overlay = null; }

  @override
  void dispose() { _hide(); _controller.dispose(); _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: StyledInput(
        controller: _controller, focusNode: _focus, placeholder: widget.placeholder, enabled: widget.enabled,
        onChanged: (v) { widget.onChanged(v); _hide(); _show(); },
      ),
    );
  }
}

// ─── Page Header ────────────────────────────────────────────────────
class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const PageHeader({super.key, required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5)),
          ])),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Badge ──────────────────────────────────────────────────────────
class PlatformBadge extends StatelessWidget {
  final bool isMac;
  const PlatformBadge({super.key, required this.isMac});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isMac ? AppColors.accent.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isMac ? AppColors.accent.withOpacity(0.3) : AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.language, size: 13, color: AppColors.primaryLight),
        const SizedBox(width: 6),
        Text('HTTP · API',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryLight)),
      ]),
    );
  }
}
