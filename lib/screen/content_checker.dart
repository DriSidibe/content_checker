import 'package:flutter/material.dart';
import 'package:content_checker/widgets/header.dart';
import 'package:content_checker/widgets/navigation_panel.dart';
import 'package:content_checker/widgets/submission_panel.dart';
import 'package:content_checker/widgets/composition_panel.dart';
import 'package:content_checker/widgets/logs_panel.dart';
import 'package:content_checker/utils/global_variables.dart';
import 'package:content_checker/services/api_service.dart';
import 'package:content_checker/screen/login.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import your login screen

class ContentCheckerScreen extends StatefulWidget {
  const ContentCheckerScreen({super.key});

  @override
  State<ContentCheckerScreen> createState() => _ContentCheckerScreenState();
}

class _ContentCheckerScreenState extends State<ContentCheckerScreen> {
  String selectedCourse = '';
  String selectedAssignment = '';
  String selectedSubmission = '';
  String navigator = '';
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (globalDatas.isEmpty) {
      await _fetchData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = await ApiService.getAllData();

      setState(() {
        globalDatas = data;
        _isLoading = false;
        _isRefreshing = false;

        if (selectedCourse.isNotEmpty &&
            !globalDatas.containsKey(selectedCourse)) {
          selectedCourse = '';
          selectedAssignment = '';
          selectedSubmission = '';
          navigator = '';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = 'Failed to load data: ${e.toString()}';
      });
    }
  }

  void _handleLogout() async {
    // Clear authentication token and user data
    ApiService.logout();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    loggedUser.clear();

    // Navigate back to login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ElegantLoginScreen()),
    );
  }

  void updateSelection(String course, String assignment, String submission) {
    setState(() {
      selectedCourse = course;
      selectedAssignment = assignment;
      selectedSubmission = submission;
      navigator = _buildNavigationPath(course, assignment, submission);
    });
  }

  String _buildNavigationPath(
      String course, String assignment, String submission) {
    if (course.isEmpty) return "";
    if (assignment.isEmpty) return course;
    if (submission.isEmpty) return "$course > $assignment";
    return "$course > $assignment > $submission";
  }

  Map<String, dynamic> getSubmissionContent() {
    try {
      return globalDatas[selectedCourse]?[selectedAssignment]
          ?[selectedSubmission] as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFa8d5a8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              strokeWidth: 4,
            ),
            const SizedBox(height: 20),
            Text(
              _isRefreshing ? 'Refreshing data...' : 'Loading course data...',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFa8d5a8),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 50,
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage ?? 'Failed to load data',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  setState(() => _isRefreshing = true);
                  _fetchData();
                },
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const AppHeader(), // Your existing header
        Positioned(
          right: 20,
          top: 50,
          child: IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ),
      ],
    );
  }

  Widget _buildContentScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFa8d5a8),
      body: Column(
        children: [
          _buildAppHeader(), // Updated header with logout button
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NavigationPanel(
                  onSelectionChanged: updateSelection,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              SubmissionPanel(
                                submission: selectedSubmission,
                                submissionContent: getSubmissionContent(),
                              ),
                              const SizedBox(height: 12),
                              CompositionPanel(
                                submission: selectedSubmission,
                                submissionContent: getSubmissionContent(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: LogsPanel(
                            submission: selectedSubmission,
                            submissionContent: getSubmissionContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingScreen();
    if (_errorMessage != null) return _buildErrorScreen();
    return _buildContentScreen();
  }
}
