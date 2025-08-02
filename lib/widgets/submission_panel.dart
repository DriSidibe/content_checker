// lib/widgets/submission_panel.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class HighlightedText extends StatelessWidget {
  final String text;

  const HighlightedText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: RichText(
        text: _buildTextSpans(text),
      ),
    );
  }

  TextSpan _buildTextSpans(String text) {
    final List<TextSpan> spans = [];
    final RegExp exp = RegExp(r'@\{([^}]*)\}');
    final matches = exp.allMatches(text);
    int currentIndex = 0;

    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(
            backgroundColor: Color(0xFFFFEB3B),
          ),
        ),
      );

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex),
        ),
      );
    }

    return TextSpan(
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black,
        height: 1.6,
      ),
      children: spans,
    );
  }
}

class SubmissionPanel extends StatelessWidget {
  final String submission;
  final Map<String, dynamic> submissionContent;

  const SubmissionPanel({
    super.key,
    required this.submission,
    required this.submissionContent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2d5a2d), Color(0xFF3d6a3d)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Student Submission',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: submission.isEmpty
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Select a submission to view content',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Use the navigation panel to select a course, assignment, and submission to begin the comparison analysis.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (submissionContent['content']?["title"] !=
                                  null)
                                Text(
                                  submissionContent['content']!["title"],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              HighlightedText(
                                text: submissionContent['content']?["body"],
                              ),
                            ],
                          ),
                        )),
            ),
          ],
        ),
      ),
    );
  }
}
