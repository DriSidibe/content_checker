import 'package:flutter/material.dart';
import 'package:content_checker/widgets/nav_section.dart';
import 'package:content_checker/utils/global_variables.dart';

class NavigationPanel extends StatefulWidget {
  final Function(String, String, String) onSelectionChanged;

  const NavigationPanel({super.key, required this.onSelectionChanged});

  @override
  State<NavigationPanel> createState() => _NavigationPanelState();
}

class _NavigationPanelState extends State<NavigationPanel> {
  String selectedCourse = '';
  String selectedAssignment = '';
  String selectedSubmission = '';
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: Colors.white.withOpacity(0.9),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search courses, assignments...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.black.withOpacity(0.2),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  NavSection(
                    title: '📚 Courses',
                    items: globalDatas.keys
                        .where((course) =>
                            course.toLowerCase().contains(searchQuery))
                        .toList(),
                    onItemSelected: (item) {
                      setState(() {
                        selectedCourse = item;
                        selectedAssignment = '';
                        selectedSubmission = '';
                      });
                      widget.onSelectionChanged(selectedCourse,
                          selectedAssignment, selectedSubmission);
                    },
                  ),
                  NavSection(
                    title: '📝 Assignments',
                    items: selectedCourse.isNotEmpty
                        ? (globalDatas[selectedCourse] as Map<String, dynamic>?)
                                ?.keys
                                .where((assignment) => assignment
                                    .toLowerCase()
                                    .contains(searchQuery))
                                .toList() ??
                            []
                        : ['Select a course first'],
                    disabled: selectedCourse.isEmpty,
                    onItemSelected: (item) {
                      if (selectedCourse.isNotEmpty) {
                        setState(() {
                          selectedAssignment = item;
                          selectedSubmission = '';
                        });
                        widget.onSelectionChanged(selectedCourse,
                            selectedAssignment, selectedSubmission);
                      }
                    },
                  ),
                  NavSection(
                    title: '📄 Submissions',
                    items: selectedAssignment.isNotEmpty
                        ? (globalDatas[selectedCourse]
                                    as Map<String, dynamic>)[selectedAssignment]
                                ?.keys
                                .where((submission) => submission
                                    .toString()
                                    .toLowerCase()
                                    .contains(searchQuery))
                                .cast<String>()
                                .toList() ??
                            <String>[]
                        : ['Select an assignment first'],
                    disabled: selectedAssignment.isEmpty,
                    onItemSelected: (item) {
                      if (selectedAssignment.isNotEmpty) {
                        setState(() {
                          selectedSubmission = item;
                        });
                        widget.onSelectionChanged(selectedCourse,
                            selectedAssignment, selectedSubmission);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
