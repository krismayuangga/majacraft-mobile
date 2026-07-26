import 'package:flutter/material.dart';

/// Simple markdown editor with toolbar for bold and list formatting
class SimpleMarkdownEditor extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final int maxLines;
  final bool required;

  const SimpleMarkdownEditor({
    Key? key,
    required this.controller,
    this.label,
    this.hint,
    this.maxLines = 6,
    this.required = false,
  }) : super(key: key);

  @override
  State<SimpleMarkdownEditor> createState() => _SimpleMarkdownEditorState();
}

class _SimpleMarkdownEditorState extends State<SimpleMarkdownEditor> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _applyBold() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid) {
      // No selection, insert template
      final newText =
          text.substring(0, selection.baseOffset) +
          '**text bold**' +
          text.substring(selection.baseOffset);
      widget.controller.text = newText;
      widget.controller.selection = TextSelection(
        baseOffset: selection.baseOffset + 2,
        extentOffset: selection.baseOffset + 11,
      );
    } else {
      // Wrap selected text
      final selectedText = text.substring(selection.start, selection.end);
      final newText =
          text.substring(0, selection.start) +
          '**$selectedText**' +
          text.substring(selection.end);
      widget.controller.text = newText;
      widget.controller.selection = TextSelection.collapsed(
        offset: selection.end + 4,
      );
    }
    _focusNode.requestFocus();
  }

  void _applyList() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid) {
      // Add list item at cursor
      final cursorPos = selection.baseOffset;

      // Find start of current line
      int lineStart = text.lastIndexOf('\n', cursorPos - 1) + 1;

      // Insert "- " at start of line if not already there
      final lineText = text.substring(
        lineStart,
        text.indexOf('\n', cursorPos) == -1
            ? text.length
            : text.indexOf('\n', cursorPos),
      );

      if (!lineText.trimLeft().startsWith('-')) {
        final newText =
            text.substring(0, lineStart) + '- ' + text.substring(lineStart);
        widget.controller.text = newText;
        widget.controller.selection = TextSelection.collapsed(
          offset: cursorPos + 2,
        );
      }
    } else {
      // Apply list to each line in selection
      final lines = text.substring(selection.start, selection.end).split('\n');
      final formattedLines = lines
          .map((line) {
            if (line.trimLeft().isEmpty) return line;
            if (line.trimLeft().startsWith('-')) return line;
            return '- $line';
          })
          .join('\n');

      final newText =
          text.substring(0, selection.start) +
          formattedLines +
          text.substring(selection.end);
      widget.controller.text = newText;
      widget.controller.selection = TextSelection.collapsed(
        offset: selection.start + formattedLines.length,
      );
    }
    _focusNode.requestFocus();
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Panduan Format'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '**Text Bold**',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Hasil: Text Bold',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Divider(height: 24),
            Text('- Item 1\n- Item 2\n- Item 3'),
            SizedBox(height: 4),
            Text('Hasil: List dengan bullet'),
            Divider(height: 24),
            Text(
              'Tip: Pilih teks lalu klik tombol toolbar untuk format otomatis',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label != null)
          Row(
            children: [
              Text(
                widget.label!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1A14),
                ),
              ),
              if (widget.required)
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
            ],
          ),
        if (widget.label != null) const SizedBox(height: 8),

        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.format_bold, size: 20),
                onPressed: _applyBold,
                tooltip: 'Bold (** **)',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                color: const Color(0xFFB45309),
              ),
              IconButton(
                icon: const Icon(Icons.format_list_bulleted, size: 20),
                onPressed: _applyList,
                tooltip: 'List (- )',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                color: const Color(0xFFB45309),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.help_outline, size: 18),
                onPressed: _showHelp,
                tooltip: 'Panduan',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),

        // Text Field
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              borderSide: BorderSide(color: Color(0xFFB45309), width: 2),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              borderSide: BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: widget.maxLines,
          validator: widget.required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '${widget.label ?? "Field"} wajib diisi';
                  }
                  return null;
                }
              : null,
        ),

        // Helper text
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 12),
          child: Text(
            'Gunakan **bold** untuk teks tebal, - untuk list',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}
