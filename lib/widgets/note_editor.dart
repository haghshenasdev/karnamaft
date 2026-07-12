import 'package:flutter/material.dart';

class NoteEditor extends StatefulWidget {
  final TextEditingController controller;

  final bool enabled;

  final EdgeInsets padding;

  const NoteEditor({
    super.key,
    required this.controller,
    required this.enabled,
    this.padding = const EdgeInsets.fromLTRB(
      28,
      24,
      28,
      24,
    ),
  });

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant NoteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    //------------------------------------------
    // ورود به حالت تایپ
    //------------------------------------------

    if (widget.enabled && !oldWidget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }

    //------------------------------------------
    // خروج از حالت تایپ
    //------------------------------------------

    if (!widget.enabled && oldWidget.enabled) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: widget.enabled ? 1 : .95,
        child: TextField(
          controller: widget.controller,

          focusNode: _focusNode,

          enabled: widget.enabled,

          autofocus: false,

          expands: true,

          maxLines: null,

          minLines: null,

          keyboardType: TextInputType.multiline,

          textInputAction: TextInputAction.newline,

          textDirection: TextDirection.rtl,

          textAlign: TextAlign.right,

          textAlignVertical: TextAlignVertical.top,

          cursorWidth: 2,

          cursorRadius: const Radius.circular(2),

          style: const TextStyle(
            fontSize: 18,
            height: 1.9,
            color: Colors.black87,
          ),

          decoration: InputDecoration(
            border: InputBorder.none,

            enabledBorder: InputBorder.none,

            focusedBorder: InputBorder.none,

            disabledBorder: InputBorder.none,

            contentPadding: widget.padding,

            hintText: widget.enabled
                ? "شروع به نوشتن کنید..."
                : null,

            hintStyle: const TextStyle(
              color: Colors.grey,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}