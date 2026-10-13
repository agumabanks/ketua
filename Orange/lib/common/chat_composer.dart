import 'package:ketua_ui/utils/font_res.dart';
import 'package:flutter/material.dart';
import 'package:ketua_ui/utils/color_res.dart';

/// Compact composer that keeps the text area usable on narrow phones.
class ChatComposer extends StatelessWidget {
  const ChatComposer(
      {super.key,
      required this.controller,
      required this.enabled,
      required this.busy,
      required this.onAttach,
      required this.onSend});
  final TextEditingController controller;
  final bool enabled, busy;
  final VoidCallback onAttach, onSend;

  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _circle(Icons.add_rounded, 'Attachments',
                enabled && !busy ? onAttach : null),
            const SizedBox(width: 8),
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFF24242C),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: .10))),
                    child: TextField(
                        controller: controller,
                        enabled: enabled,
                        maxLength: 5000,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(
                            fontFamily: FontRes.medium,
                            fontSize: 16,
                            height: 1.35,
                            color: Colors.white),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                            hintText: 'Message',
                            counterText: '',
                            hintStyle: TextStyle(color: Color(0xFFA8A8B3)),
                            isDense: true,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none)))),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, value, __) {
                  final canSend =
                      enabled && !busy && value.text.trim().isNotEmpty;
                  return SizedBox(
                      width: 48,
                      height: 48,
                      child: Material(
                          color: canSend
                              ? ColorRes.ketuaAccent
                              : const Color(0xFF24242C),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: IconButton(
                              tooltip: 'Send message',
                              color: Colors.white,
                              disabledColor: const Color(0xFF747480),
                              onPressed: canSend ? onSend : null,
                              icon: busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.arrow_upward_rounded,
                                      size: 25))));
                })
          ])));

  Widget _circle(IconData icon, String label, VoidCallback? action) => SizedBox(
      width: 48,
      height: 48,
      child: Material(
          color: const Color(0xFF24242C),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
              tooltip: label,
              color: Colors.white,
              onPressed: action,
              icon: Icon(icon, size: 27))));
}
