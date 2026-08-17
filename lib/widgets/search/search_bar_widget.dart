import 'package:flutter/material.dart';
import 'package:karnamaft/utils/persian_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;

  final VoidCallback? onBack;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  final String hint;
  final bool? backBtn;
  final bool autofocus;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onBack,
    this.onClear,
    this.onChanged,
    this.onTap,
    this.backBtn,
    this.hint = "جستجو...",
    this.autofocus = false,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final SpeechToText _speechToText = SpeechToText();

  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();

    _initSpeech();
  }

  /// فقط یک بار در طول عمر این Widget
  Future<void> _initSpeech() async {
    try {
      final enabled = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');

          if (mounted) {
            setState(() {});
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _speechEnabled = enabled;
      });
    } catch (e) {
      debugPrint('Speech initialize error: $e');
    }
  }

  /// شروع تایپ صوتی
  Future<void> _startListening() async {
    if (!_speechEnabled) {
      debugPrint('Speech recognition is not available');
      return;
    }

    await _speechToText.listen(onResult: _onSpeechResult);

    if (!mounted) return;

    setState(() {});
  }

  /// توقف تایپ صوتی
  Future<void> _stopListening() async {
    await _speechToText.stop();

    if (!mounted) return;

    setState(() {});
  }

  /// نتیجه تشخیص صدا
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;

    final text = PersianText.normalize(result.recognizedWords);

    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    widget.onChanged?.call(text);

    setState(() {});
  }

  /// دکمه میکروفون
  Future<void> _toggleListening() async {
    if (_speechToText.isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  @override
  void dispose() {
    _speechToText.stop();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isListening = _speechToText.isListening;

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
            if (widget.backBtn == true)
              IconButton(
                onPressed:
                    widget.onBack ??
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
                controller: widget.controller,
                autofocus: widget.autofocus,

                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,

                onChanged: (value) {
                  final normalized = PersianText.normalize(value);

                  if (normalized != value && !value.endsWith(' ')) {
                    widget.controller.value = TextEditingValue(
                      text: normalized,
                      selection: TextSelection.collapsed(
                        offset: normalized.length,
                      ),
                    );
                  }

                  widget.onChanged?.call(normalized);
                },

                onTap: widget.onTap,

                decoration: InputDecoration(
                  hintText: widget.hint,
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
              valueListenable: widget.controller,

              builder: (_, value, __) {
                if (value.text.isEmpty) {
                  return const SizedBox();
                }

                return IconButton(
                  tooltip: "پاک کردن",

                  onPressed: () {
                    widget.controller.clear();

                    widget.onClear?.call();
                  },

                  icon: const Icon(Icons.close),
                );
              },
            ),

            //-------------------------------------
            // Voice
            //-------------------------------------
            IconButton(
              tooltip: !_speechEnabled
                  ? "تایپ صوتی در دسترس نیست"
                  : isListening
                  ? "توقف تایپ صوتی"
                  : "تایپ صوتی",

              onPressed: _speechEnabled ? _toggleListening : null,

              icon: Icon(isListening ? Icons.mic : Icons.mic_none),
            ),

            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
