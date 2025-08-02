import 'package:flutter/material.dart';

class CompositionPanel extends StatefulWidget {
  final String submission;
  final Map<String, dynamic> submissionContent;

  const CompositionPanel({
    super.key,
    required this.submission,
    required this.submissionContent,
  });

  @override
  State<CompositionPanel> createState() => _CompositionPanelState();
}

class _CompositionPanelState extends State<CompositionPanel> {
  List<Map<String, dynamic>> get _breakdown {
    try {
      final breakdown = widget.submissionContent['compositionBreakdown'];
      if (breakdown is List) {
        return breakdown.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  String _getText(String key, [String fallback = '']) =>
      widget.submissionContent[key]?.toString() ?? fallback;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
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
              child: const Row(
                children: [
                  Icon(Icons.analytics, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Writing Composition Breakdown',
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
                child: widget.submission.isEmpty
                    ? const Center(
                        child: Text(
                          'Composition analysis will appear here once a submission is selected.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryCard(),
                            const SizedBox(height: 16),
                            ..._buildBreakdownItems(),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2d5a2d).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report:',
            style: TextStyle(
              color: Color(0xFF2d5a2d),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Writing Composition Breakdown:',
            style: TextStyle(
              color: Color(0xFF2d5a2d),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
              'Student written:', _getText('Student written', 'N/A')),
          _buildMetricRow('AI generated:', _getText('AI generated', 'N/A')),
          const SizedBox(height: 16),
          const Text(
            'AI Use Assessment:',
            style: TextStyle(
              color: Color(0xFF2d5a2d),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getText('AI Use Assessment', 'No assessment available'),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBreakdownItems() {
    return _breakdown.map((item) {
      final type = item['type']?.toString() ?? '';
      final (borderColor, bgColor) = _getColorsForType(type);

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: borderColor,
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['section']?.toString() ?? 'Unknown section',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item['confidence']?.toString() ?? 'N/A',
                    style: TextStyle(
                      fontSize: 12,
                      color: borderColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item['details']?.toString() ?? 'No details available',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${item['wordCount']?.toString() ?? '0'} words',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  (Color, Color) _getColorsForType(String type) {
    switch (type) {
      case 'human-written':
        return (
          const Color(0xFF28a745),
          const Color(0xFF28a745).withOpacity(0.1)
        );
      case 'ai-assisted':
        return (
          const Color(0xFFffc107),
          const Color(0xFFffc107).withOpacity(0.1)
        );
      default:
        return (
          const Color(0xFFdc3545),
          const Color(0xFFdc3545).withOpacity(0.1)
        );
    }
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d5a2d),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
