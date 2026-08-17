import 'package:flutter/material.dart';
import 'package:karnamaft/utils/persian_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;

  final VoidCallback? onBack;

  final VoidCallback? onVoice;

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
    this.onVoice,
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
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;

  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();

    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      if (!mounted) return;

      setState(() {
        _speechAvailable = available;
      });
    } catch (e) {
      debugPrint('Speech initialization error: $e');
    }
  }

  void _onSpeechStatus(String status) {
    debugPrint('Speech status: $status');

    if (!mounted) return;

    if (status == 'listening') {
      setState(() {
        _isListening = true;
      });
    }

    if (status == 'done' || status == 'notListening') {
      setState(() {
        _isListening = false;
      });
    }
  }

  void _onSpeechError(dynamic error) {
    debugPrint('Speech error: $error');

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });
  }

  Future<void> _toggleVoice() async {
    // اگر در حال گوش دادن است → توقف
    if (_isListening) {
      await _stopListening();
      return;
    }

    // اگر callback خارجی تعریف شده باشد
    // می‌توانیم آن را هم اجرا کنیم.
    if (widget.onVoice != null) {
      widget.onVoice!();
      return;
    }

    await _startListening();
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      await _initializeSpeech();
    }

    if (!_speechAvailable) {
      debugPrint('Speech recognition is not available');
      return;
    }

    if (!mounted) return;

    setState(() {
      _isListening = true;
    });

    await _speech.listen(
      localeId: 'fa_IR',
      partialResults: true,
      listenMode: stt.ListenMode.search,

      onResult: (result) {
        if (!mounted) return;

        final text = PersianText.normalize(result.recognizedWords);

        widget.controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );

        // همان onChanged معمولی TextField
        widget.onChanged?.call(text);
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });
  }

  @override
  void dispose() {
    _speech.stop();
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
            IconButton(
              tooltip: _isListening ? "توقف ضبط" : "جستجوی صوتی",

              onPressed: _toggleVoice,

              icon: Icon(
                _isListening ? Icons.mic : Icons.keyboard_voice_outlined,
              ),
            ),

            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
