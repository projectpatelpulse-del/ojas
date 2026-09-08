import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class ScrollableTermsDialog extends StatefulWidget {
  final String title;
  final String termsContent;
  final Color primaryColor;
  final Function(bool) onAccepted;

  const ScrollableTermsDialog({
    super.key,
    required this.title,
    required this.termsContent,
    required this.onAccepted,
    this.primaryColor = AppColors.primaryPink,
  });

  @override
  State<ScrollableTermsDialog> createState() => _ScrollableTermsDialogState();
}

class _ScrollableTermsDialogState extends State<ScrollableTermsDialog> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (_scrollController.position.maxScrollExtent <= 5) {
          setState(() {
            _hasScrolledToBottom = true;
          });
        }
      }
    });
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 15) {
        if (!_hasScrolledToBottom) {
          setState(() {
            _hasScrolledToBottom = true;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  List<TextSpan> _parseRichText(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(
        r'(<b>.*?</b>|<i>.*?</i>|<strong>.*?</strong>|<em>.*?</em>|<li>.*?</li>)',
        dotAll: true);

    int lastMatchEnd = 0;
    final matches = regExp.allMatches(text);

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      final matchedText = match.group(0)!;
      if (matchedText.startsWith('<b>') || matchedText.startsWith('<strong>')) {
        final innerText = matchedText
            .replaceAll('<b>', '')
            .replaceAll('</b>', '')
            .replaceAll('<strong>', '')
            .replaceAll('</strong>', '');
        spans.add(TextSpan(
          text: innerText,
          style: baseStyle.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ));
      } else if (matchedText.startsWith('<i>') || matchedText.startsWith('<em>')) {
        final innerText = matchedText
            .replaceAll('<i>', '')
            .replaceAll('</i>', '')
            .replaceAll('<em>', '')
            .replaceAll('</em>', '');
        spans.add(TextSpan(
          text: innerText,
          style: baseStyle.copyWith(fontStyle: FontStyle.italic, color: const Color(0xFF334155)),
        ));
      } else if (matchedText.startsWith('<li>')) {
        final innerText = matchedText
            .replaceAll('<li>', '')
            .replaceAll('</li>', '');
        spans.add(TextSpan(
          text: '\n  • $innerText',
          style: baseStyle.copyWith(color: const Color(0xFF334155)),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 24,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 600),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 20,
                )
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Please scroll to the bottom of the terms to accept.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFFF8FAFC),
                ),
                padding: const EdgeInsets.all(20),
                child: Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: RichText(
                        text: TextSpan(
                          children: _parseRichText(
                            widget.termsContent.isNotEmpty
                                ? widget.termsContent
                                : "No Terms & Conditions provided.",
                            GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF334155),
                              height: 1.65,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _hasScrolledToBottom
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.primaryColor.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _agreed,
                            onChanged: (v) {
                              setState(() {
                                _agreed = v ?? false;
                              });
                            },
                            activeColor: widget.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'I have read and agree to the Terms & Conditions.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Scroll down to unlock agreement',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _agreed
                      ? () {
                          widget.onAccepted(true);
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    elevation: _agreed ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Accept & Continue',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
