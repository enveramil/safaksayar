import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tanıtım, rol seçimi ve kurulum sihirbazının ortak görsel dili.
/// PRO ekranlarıyla aynı koyu zemin ve altın vurguyu kullanır.
class SetupColors {
  SetupColors._();

  static const Color background = Color(0xFF0C0D11);
  static const Color surface = Color(0xFF14161E);
  static const Color surfaceRaised = Color(0xFF1B1E28);
  static const Color border = Color(0xFF262A37);
  static const Color gold = Color(0xFFFBBF24);
  static const Color goldDeep = Color(0xFFF59E0B);
  static const Color goldLight = Color(0xFFFDE68A);
  static const Color onGold = Color(0xFF1F1600);
  static const Color green = Color(0xFF10B981);
  static const Color greenLight = Color(0xFF34D399);
  static const Color error = Color(0xFFF87171);
  static const Color textMuted = Color(0xFFB0B5C6);
  static const Color textFaint = Color(0xFF7D8295);
}

const SystemUiOverlayStyle setupOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: SetupColors.background,
  systemNavigationBarIconBrightness: Brightness.light,
);

/// [AnimatedSwitcher] içeriğini ortalamak yerine üstten hizalar.
Widget setupTopLayoutBuilder(Widget? currentChild, List<Widget> previousChildren) {
  return Stack(
    fit: StackFit.expand,
    alignment: Alignment.topCenter,
    children: [...previousChildren, if (currentChild != null) currentChild],
  );
}

/// Türkçe karakterleri sadeleştirerek arama için küçük harfe çevirir.
String normalizeForSearch(String text) {
  const Map<String, String> replacements = {
    'İ': 'i',
    'I': 'i',
    'ı': 'i',
    'Ş': 's',
    'ş': 's',
    'Ğ': 'g',
    'ğ': 'g',
    'Ü': 'u',
    'ü': 'u',
    'Ö': 'o',
    'ö': 'o',
    'Ç': 'c',
    'ç': 'c',
  };
  return text.split('').map((c) => replacements[c] ?? c.toLowerCase()).join();
}

/// Üstten yayılan vurgu ışıklı ekran zemini.
class SetupBackground extends StatelessWidget {
  final Color accent;
  final Widget child;

  const SetupBackground({
    super.key,
    this.accent = SetupColors.goldDeep,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -1.05),
                radius: 1.1,
                colors: [
                  accent.withValues(alpha: 0.18),
                  SetupColors.background.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Akışın ana eylem butonu.
class SetupPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SetupPrimaryButton({
    super.key,
    required this.label,
    this.icon = Icons.arrow_forward_rounded,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: onPressed == null ? 0.45 : 1,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [SetupColors.goldLight, SetupColors.gold, SetupColors.goldDeep],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: SetupColors.goldDeep.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    onPressed!();
                  }
                : null,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: SetupColors.onGold,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SetupColors.onGold,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: 6),
                          Icon(icon, color: SetupColors.onGold, size: 19),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Üst köşelerdeki yuvarlak geri butonu.
class SetupBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SetupBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Geri',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: SetupColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: SetupColors.border),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

/// Ekran başlığı ve açıklaması.
class SetupHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const SetupHeading({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            height: 1.15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          subtitle,
          style: const TextStyle(
            color: SetupColors.textMuted,
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Alan başlığı.
class SetupFieldLabel extends StatelessWidget {
  final String text;

  const SetupFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          color: SetupColors.textMuted,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Alanın altında gösterilen doğrulama mesajı.
class SetupFieldError extends StatelessWidget {
  final String? message;

  const SetupFieldError(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.topLeft,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(left: 2, top: 6),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: SetupColors.error, size: 14),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      message!,
                      style: const TextStyle(
                        color: SetupColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Akış içi hata kutusu.
class SetupErrorBanner extends StatelessWidget {
  final String message;

  const SetupErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SetupColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SetupColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: SetupColors.error, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration setupFieldDecoration({bool isActive = false, bool hasError = false}) {
  return BoxDecoration(
    color: SetupColors.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: hasError
          ? SetupColors.error
          : (isActive ? SetupColors.gold : SetupColors.border),
      width: hasError || isActive ? 1.5 : 1,
    ),
  );
}

/// Odaklandığında altın çerçeve alan metin girişi.
class SetupTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? errorText;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const SetupTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.errorText,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.words,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<SetupTextField> createState() => _SetupTextFieldState();
}

class _SetupTextFieldState extends State<SetupTextField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SetupFieldLabel(widget.label),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: setupFieldDecoration(
            isActive: _focusNode.hasFocus,
            hasError: widget.errorText != null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            cursorColor: SetupColors.gold,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                color: SetupColors.textFaint,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                widget.icon,
                size: 20,
                color: _focusNode.hasFocus ? SetupColors.gold : SetupColors.textFaint,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        SetupFieldError(widget.errorText),
      ],
    );
  }
}

/// Alttan açılan seçim listesini tetikleyen alan.
class SetupSelectField extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final IconData icon;
  final String? errorText;
  final VoidCallback onTap;

  const SetupSelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.icon,
    required this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SetupFieldLabel(label),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: setupFieldDecoration(hasError: errorText != null),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: hasValue ? SetupColors.gold : SetupColors.textFaint,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasValue ? Colors.white : SetupColors.textFaint,
                      fontSize: 15.5,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: SetupColors.textFaint,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        SetupFieldError(errorText),
      ],
    );
  }
}

/// Az seçenekli alanlar için dokunmatik seçim hapı.
class SetupChoiceChip extends StatelessWidget {
  final String label;
  final String? caption;
  final bool isSelected;
  final VoidCallback onTap;

  const SetupChoiceChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? SetupColors.gold.withValues(alpha: 0.14)
                : SetupColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? SetupColors.gold : SetupColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: isSelected ? SetupColors.goldLight : Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    caption!,
                    maxLines: 1,
                    style: TextStyle(
                      color: isSelected ? SetupColors.gold : SetupColors.textFaint,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Seçenekleri eşit genişlikte satırlara dizer.
class SetupChoiceGrid extends StatelessWidget {
  final int columns;
  final List<Widget> children;

  const SetupChoiceGrid({
    super.key,
    required this.columns,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [];
    for (int start = 0; start < children.length; start += columns) {
      final List<Widget> cells = [];
      for (int i = 0; i < columns; i++) {
        if (i > 0) cells.add(const SizedBox(width: 8));
        final int index = start + i;
        cells.add(
          Expanded(
            child: index < children.length ? children[index] : const SizedBox.shrink(),
          ),
        );
      }
      if (start > 0) rows.add(const SizedBox(height: 8));
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells),
      ));
    }
    return Column(children: rows);
  }
}

/// Aranabilir seçim listesini alttan açar; seçilen değeri döndürür.
Future<String?> showSetupOptionSheet({
  required BuildContext context,
  required String title,
  required List<String> items,
  String? selectedValue,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SetupOptionSheet(
      title: title,
      items: items,
      selectedValue: selectedValue,
    ),
  );
}

class _SetupOptionSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? selectedValue;

  const _SetupOptionSheet({
    required this.title,
    required this.items,
    this.selectedValue,
  });

  @override
  State<_SetupOptionSheet> createState() => _SetupOptionSheetState();
}

class _SetupOptionSheetState extends State<_SetupOptionSheet> {
  static const double _rowHeight = 50;

  late final ScrollController _scrollController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final int selectedIndex = widget.selectedValue == null
        ? -1
        : widget.items.indexOf(widget.selectedValue!);
    _scrollController = ScrollController(
      initialScrollOffset: selectedIndex > 3 ? (selectedIndex - 3) * _rowHeight : 0,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = normalizeForSearch(_query.trim());
    final List<String> visibleItems = query.isEmpty
        ? widget.items
        : widget.items.where((i) => normalizeForSearch(i).contains(query)).toList();
    final MediaQueryData media = MediaQuery.of(context);

    return Container(
      height: media.size.height * 0.78,
      margin: EdgeInsets.only(bottom: media.viewInsets.bottom),
      decoration: const BoxDecoration(
        color: SetupColors.surfaceRaised,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: SetupColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SetupColors.border),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                cursorColor: SetupColors.gold,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Şehir ara',
                  hintStyle: TextStyle(color: SetupColors.textFaint),
                  prefixIcon: Icon(Icons.search_rounded, color: SetupColors.textFaint, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: visibleItems.isEmpty
                ? const Center(
                    child: Text(
                      'Sonuç bulunamadı',
                      style: TextStyle(color: SetupColors.textFaint, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemExtent: _rowHeight,
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(bottom: media.padding.bottom + 8),
                    itemCount: visibleItems.length,
                    itemBuilder: (context, index) {
                      final String item = visibleItems[index];
                      final bool isSelected = item == widget.selectedValue;

                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop(item);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    color: isSelected ? SetupColors.goldLight : Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: SetupColors.gold,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
