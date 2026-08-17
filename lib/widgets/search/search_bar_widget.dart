import 'package:flutter/material.dart';
import 'package:karnamaft/utils/persian_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
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

class _SearchBarWidgetState extends State<SearchBarWidget>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();

  bool _speechEnabled = false;
  bool _isListening = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.8,
      upperBound: 1.15,
    );

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      if (!mounted) return;

      setState(() {
        _speechEnabled = available;
      });
    } catch (e) {
      debugPrint('Speech initialize error: $e');
    }
  }

  void _onSpeechStatus(String status) {
    debugPrint('Speech status: $status');

    if (!mounted) return;

    if (status == 'listening') {
      setState(() {
        _isListening = true;
      });

      _pulseController.repeat(reverse: true);
    }

    if (status == 'done' || status == 'notListening') {
      setState(() {
        _isListening = false;
      });

      _pulseController.stop();
      _pulseController.value = 1;
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    debugPrint('Speech error: ${error.errorMsg}');

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });

    _pulseController.stop();
    _pulseController.value = 1;
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      await _initSpeech();
    }

    if (!_speechEnabled) {
      debugPrint('Speech recognition is not available');
      return;
    }

    // اگر متن قبلی وجود دارد، می‌توانی این قسمت را حذف کنی
    // تا متن جدید به متن قبلی اضافه شود.
    widget.controller.clear();

    if (!mounted) return;

    setState(() {
      _isListening = true;
    });

    _pulseController.repeat(reverse: true);

    await _speech.listen(
      localeId: 'fa_IR',
      partialResults: true,
      listenMode: ListenMode.search,
      onResult: _onSpeechResult,
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });

    _pulseController.stop();
    _pulseController.value = 1;
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;

    final text = PersianText.normalize(result.recognizedWords);

    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    // همان رفتار تایپ معمولی
    widget.onChanged?.call(text);
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseController.dispose();

    super.dispose();
  }

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
            AnimatedBuilder(
              animation: _pulseController,

              builder: (context, child) {
                return Transform.scale(
                  scale: _isListening ? _pulseController.value : 1.0,

                  child: IconButton(
                    tooltip: _isListening
                        ? "در حال گوش دادن..."
                        : "جستجوی صوتی",

                    onPressed: _speechEnabled ? _toggleVoice : null,

                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : null,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
