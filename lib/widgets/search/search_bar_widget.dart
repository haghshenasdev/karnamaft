import 'package:flutter/material.dart';
import 'package:karnamaft/utils/persian_text.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;

  final VoidCallback? onBack;

  final VoidCallback? onVoice;

  final VoidCallback? onClear;

  final ValueChanged<String>? onChanged;

  final VoidCallback? onTap;

  final String hint;
  final bool? backBtn;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onBack,
    this.onVoice,
    this.onClear,
    this.onChanged,
    this.onTap,
    this.backBtn,
    this.hint = "جستجو...",
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            //-------------------------------------
            // Back
            //-------------------------------------
            if (backBtn == true)
              IconButton(
                onPressed:
                    onBack ??
                    () {
                      Navigator.pop(context);
                    },
                icon: const Icon(Icons.arrow_back),
              ),
            const SizedBox(width: 4),

            //-------------------------------------
            // TextField
            //-------------------------------------
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                onChanged: (value) {
                  final normalized = PersianText.normalize(value);

                  if (normalized != value && !value.endsWith(' ')) {
                    controller.value = TextEditingValue(
                      text: normalized,
                      selection: TextSelection.collapsed(
                        offset: normalized.length,
                      ),
                    );
                  }

                  onChanged?.call(normalized);
                },
                onTap: onTap,
                decoration: InputDecoration(
                  hintText: hint,

                  border: InputBorder.none,

                  isDense: true,

                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            //-------------------------------------
            // Clear
            //-------------------------------------
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, __) {
                if (value.text.isEmpty) {
                  return const SizedBox();
                }

                return IconButton(
                  tooltip: "پاک کردن",

                  onPressed: () {
                    controller.clear();

                    if (onClear != null) {
                      onClear!();
                    }
                  },

                  icon: const Icon(Icons.close),
                );
              },
            ),

            //-------------------------------------
            // Voice
            //-------------------------------------
            IconButton(
              tooltip: "جستجوی صوتی",
              onPressed: onVoice,
              icon: const Icon(Icons.keyboard_voice_outlined),
            ),

            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
